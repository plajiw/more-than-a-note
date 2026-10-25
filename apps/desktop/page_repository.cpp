#include "page_repository.h"

#include "content_codec.h"
#include "notebook_schema.h"

#include <QByteArray>
#include <QSqlQuery>

#include <new>
#include <span>
#include <utility>

using namespace mtn::model;

namespace {
constexpr qlonglong maxPageObjects = 100'000;
constexpr qlonglong maxPagePayloadBytes = 256ll * 1024 * 1024;
constexpr qlonglong maxObjectPayloadBytes = 32ll * 1024 * 1024;

PageStorageStatus schemaStatus(QSqlDatabase& db, bool forWrite) {
    const auto schema = inspectNotebookSchema(db);
    if (schema == NotebookSchemaStatus::ReadyV2) return PageStorageStatus::Ok;
    if (schema == NotebookSchemaStatus::LegacyV1) {
        if (!forWrite) return PageStorageStatus::LegacyEmpty;
        return migrateNotebookSchema(db) == NotebookSchemaStatus::MigratedV2
                   ? PageStorageStatus::Ok : PageStorageStatus::SqlError;
    }
    if (schema == NotebookSchemaStatus::FutureVersion ||
        schema == NotebookSchemaStatus::UnsupportedVersion)
        return PageStorageStatus::UnsupportedContent;
    return schema == NotebookSchemaStatus::SqlError ? PageStorageStatus::SqlError
                                                   : PageStorageStatus::InvalidSchema;
}

bool pageExists(QSqlDatabase& db, const QString& pageId) {
    QSqlQuery query(db);
    query.prepare("SELECT 1 FROM pages WHERE id = ?");
    query.addBindValue(pageId);
    return query.exec() && query.next();
}

PageStorageStatus codecStatus(CodecStatus status) {
    switch (status) {
    case CodecStatus::Ok: return PageStorageStatus::Ok;
    case CodecStatus::UnsupportedVersion: return PageStorageStatus::UnsupportedContent;
    case CodecStatus::LimitExceeded: return PageStorageStatus::TooLarge;
    case CodecStatus::OutOfMemory: return PageStorageStatus::OutOfMemory;
    default: return PageStorageStatus::InvalidContent;
    }
}

std::span<const std::uint8_t> byteSpan(const QByteArray& blob) {
    return {reinterpret_cast<const std::uint8_t*>(blob.constData()),
            static_cast<std::size_t>(blob.size())};
}
} // namespace

PageLoadResult loadPageContent(QSqlDatabase& db, const QString& pageId) {
    PageLoadResult result;
    result.page.page_id = pageId.toUtf8().toStdString();
    if (!valid_uuid(result.page.page_id)) {
        result.status = PageStorageStatus::InvalidContent;
        return result;
    }
    result.status = schemaStatus(db, false);
    if (result.status != PageStorageStatus::Ok && result.status != PageStorageStatus::LegacyEmpty)
        return result;
    if (!pageExists(db, pageId)) {
        result.status = PageStorageStatus::MissingPage;
        return result;
    }
    if (result.status == PageStorageStatus::LegacyEmpty) return result;

    try {
        QSqlQuery bounds(db);
        bounds.prepare("SELECT COUNT(*), COALESCE(SUM(LENGTH(payload)), 0), "
                       "COALESCE(MAX(LENGTH(payload)), 0) FROM page_objects WHERE page_id = ?");
        bounds.addBindValue(pageId);
        if (!bounds.exec() || !bounds.next()) {
            result.status = PageStorageStatus::SqlError;
            return result;
        }
        if (bounds.value(0).toLongLong() > maxPageObjects ||
            bounds.value(1).toLongLong() > maxPagePayloadBytes ||
            bounds.value(2).toLongLong() > maxObjectPayloadBytes) {
            result.status = PageStorageStatus::TooLarge;
            return result;
        }
        result.page.objects.reserve(static_cast<std::size_t>(bounds.value(0).toLongLong()));
        QSqlQuery query(db);
        query.prepare("SELECT id, kind, z_order, reading_order, tx, ty, rotation, "
                      "scale_x, scale_y, locked, accessible_description, payload_version, payload "
                      "FROM page_objects WHERE page_id = ? ORDER BY z_order, id");
        query.addBindValue(pageId);
        if (!query.exec()) {
            result.status = PageStorageStatus::SqlError;
            return result;
        }
        while (query.next()) {
            PageObject object;
            object.common.id = query.value(0).toString().toUtf8().toStdString();
            object.common.page_id = result.page.page_id;
            object.common.z_order = query.value(2).toLongLong();
            object.common.reading_order = query.value(3).toLongLong();
            object.common.transform.translation = {query.value(4).toDouble(), query.value(5).toDouble()};
            object.common.transform.rotation_degrees = query.value(6).toDouble();
            object.common.transform.scale_x = query.value(7).toDouble();
            object.common.transform.scale_y = query.value(8).toDouble();
            object.common.locked = query.value(9).toBool();
            object.common.accessible_description = query.value(10).toString().toUtf8().toStdString();
            if (query.value(11).toInt() != 1) {
                result.status = PageStorageStatus::UnsupportedContent;
                break;
            }
            const QByteArray blob = query.value(12).toByteArray();
            const QString kind = query.value(1).toString();
            if (kind == "text") {
                auto decoded = decode_text_v1(byteSpan(blob));
                result.status = codecStatus(decoded.status);
                if (result.status != PageStorageStatus::Ok) break;
                TextContainer text;
                text.document = std::move(decoded.value);
                object.payload = std::move(text);
            } else if (kind == "ink") {
                auto decoded = decode_ink_v1(byteSpan(blob));
                result.status = codecStatus(decoded.status);
                if (result.status != PageStorageStatus::Ok) break;
                object.payload = std::move(decoded.value);
            } else {
                result.status = PageStorageStatus::UnsupportedContent;
                break;
            }
            result.page.objects.push_back(std::move(object));
        }
        if (result.status == PageStorageStatus::Ok && !validate_page(result.page).empty())
            result.status = PageStorageStatus::InvalidContent;
    } catch (const std::bad_alloc&) {
        result.status = PageStorageStatus::OutOfMemory;
    }
    if (result.status != PageStorageStatus::Ok) result.page.objects.clear();
    return result;
}

PageStorageStatus savePageObject(QSqlDatabase& db, const PageObject& object) {
    try {
        if (object.common.group_id ||
            (kind(object) != PageObjectKind::Text && kind(object) != PageObjectKind::Ink))
            return PageStorageStatus::UnsupportedContent;
        PageContent candidate{object.common.page_id, {object}};
        if (!validate_page(candidate).empty()) return PageStorageStatus::InvalidContent;
        EncodedContent encoded;
        QString kindName;
        if (const auto* text = std::get_if<TextContainer>(&object.payload)) {
            // The v2 table stores MTNT but has no columns for container size.
            // Reject non-default geometry until a versioned format stores it.
            if (text->width_pt != 240 || text->max_width_pt != 500 || text->fixed_width)
                return PageStorageStatus::UnsupportedContent;
            encoded = encode_text_v1(text->document);
            kindName = "text";
        } else {
            encoded = encode_ink_v1(std::get<InkStroke>(object.payload));
            kindName = "ink";
        }
        const auto codec = codecStatus(encoded.status);
        if (codec != PageStorageStatus::Ok) return codec;
        if (encoded.bytes.size() > static_cast<std::size_t>(maxObjectPayloadBytes))
            return PageStorageStatus::TooLarge;
        const QString pageId = QString::fromStdString(object.common.page_id);
        if (!pageExists(db, pageId)) return PageStorageStatus::MissingPage;
        const auto schema = schemaStatus(db, true);
        if (schema != PageStorageStatus::Ok) return schema;
        if (!db.transaction()) return PageStorageStatus::SqlError;
        QSqlQuery query(db);
        query.prepare("INSERT INTO page_objects(id, page_id, kind, z_order, reading_order, "
                      "tx, ty, rotation, scale_x, scale_y, locked, accessible_description, "
                      "payload_version, payload) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?) "
                      "ON CONFLICT(id) DO UPDATE SET kind=excluded.kind, "
                      "z_order=excluded.z_order, reading_order=excluded.reading_order, "
                      "tx=excluded.tx, ty=excluded.ty, rotation=excluded.rotation, "
                      "scale_x=excluded.scale_x, scale_y=excluded.scale_y, "
                      "locked=excluded.locked, accessible_description=excluded.accessible_description, "
                      "payload_version=excluded.payload_version, payload=excluded.payload "
                      "WHERE page_objects.page_id=excluded.page_id");
        query.addBindValue(QString::fromStdString(object.common.id));
        query.addBindValue(pageId);
        query.addBindValue(kindName);
        query.addBindValue(static_cast<qlonglong>(object.common.z_order));
        query.addBindValue(static_cast<qlonglong>(object.common.reading_order));
        query.addBindValue(object.common.transform.translation.x);
        query.addBindValue(object.common.transform.translation.y);
        query.addBindValue(object.common.transform.rotation_degrees);
        query.addBindValue(object.common.transform.scale_x);
        query.addBindValue(object.common.transform.scale_y);
        query.addBindValue(object.common.locked);
        query.addBindValue(QString::fromUtf8(object.common.accessible_description));
        query.addBindValue(QByteArray(reinterpret_cast<const char*>(encoded.bytes.data()),
                                      static_cast<qsizetype>(encoded.bytes.size())));
        if (!query.exec() || query.numRowsAffected() != 1 || !db.commit()) {
            db.rollback();
            return PageStorageStatus::SqlError;
        }
        return PageStorageStatus::Ok;
    } catch (const std::bad_alloc&) {
        return PageStorageStatus::OutOfMemory;
    }
}

PageStorageStatus deletePageObject(QSqlDatabase& db, const QString& pageId,
                                   const QString& objectId) {
    if (!valid_uuid(pageId.toUtf8().toStdString()) ||
        !valid_uuid(objectId.toUtf8().toStdString())) return PageStorageStatus::InvalidContent;
    const auto schema = schemaStatus(db, false);
    if (schema != PageStorageStatus::Ok) return schema;
    if (!pageExists(db, pageId)) return PageStorageStatus::MissingPage;
    if (!db.transaction()) return PageStorageStatus::SqlError;
    QSqlQuery query(db);
    query.prepare("DELETE FROM page_objects WHERE page_id = ? AND id = ?");
    query.addBindValue(pageId);
    query.addBindValue(objectId);
    if (!query.exec() || !db.commit()) {
        db.rollback();
        return PageStorageStatus::SqlError;
    }
    return PageStorageStatus::Ok;
}
