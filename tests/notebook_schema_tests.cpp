#include "notebook_schema.h"
#include "content_codec.h"

#include <QCoreApplication>
#include <QCryptographicHash>
#include <QFile>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QTemporaryDir>

#include <iostream>

#define CHECK(condition) do { if (!(condition)) { \
    std::cerr << "Check failed: " #condition " at line " << __LINE__ << '\n'; \
    return 1; \
} } while (false)

namespace {
bool loadFixture(QSqlDatabase& db) {
    QFile file(QStringLiteral(MTN_V1_FIXTURE_PATH));
    if (!file.open(QIODevice::ReadOnly)) return false;
    for (const QByteArray& line : file.readAll().split('\n')) {
        const auto sql = line.trimmed();
        if (sql.isEmpty()) continue;
        QSqlQuery query(db);
        if (!query.exec(QString::fromUtf8(sql))) return false;
    }
    return true;
}

QByteArray hashFile(const QString& path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return {};
    return QCryptographicHash::hash(file.readAll(), QCryptographicHash::Sha256);
}
} // namespace

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    QTemporaryDir directory;
    CHECK(directory.isValid());
    const auto path = directory.filePath("notebook.sqlite");
    {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "schema-fixture");
        db.setDatabaseName(path);
        CHECK(db.open());
        CHECK(QSqlQuery(db).exec("PRAGMA foreign_keys = ON"));
        CHECK(loadFixture(db));
        CHECK(inspectNotebookSchema(db) == NotebookSchemaStatus::LegacyV1);
        CHECK(migrateNotebookSchema(db) == NotebookSchemaStatus::MigratedV2);
        CHECK(inspectNotebookSchema(db) == NotebookSchemaStatus::ReadyV2);
        CHECK(migrateNotebookSchema(db) == NotebookSchemaStatus::ReadyV2);
        QSqlQuery query(db);
        CHECK(query.exec("SELECT title, last_section, last_page FROM notebook"));
        CHECK(query.next());
        CHECK(query.value(0).toString() == QString::fromUtf8("Caderno legado — aula"));
        CHECK(query.value(2).toString() == "33333333-3333-4333-8333-333333333333");
        CHECK(query.exec("SELECT title FROM pages"));
        CHECK(query.next() && query.value(0).toString() == "Página preservada");
        CHECK(query.exec("SELECT COUNT(*), MIN(canvas_kind) FROM page_settings"));
        CHECK(query.next() && query.value(0).toInt() == 1 && query.value(1).toInt() == 0);
        CHECK(query.exec("SELECT COUNT(*) FROM page_objects"));
        CHECK(query.next() && query.value(0).toInt() == 0);
        mtn::model::RichTextDocument document;
        mtn::model::RichParagraph paragraph;
        paragraph.runs.push_back({"Texto persistido — שלום", {}});
        document.paragraphs.push_back(std::move(paragraph));
        const auto textBlob = mtn::model::encode_text_v1(document);
        CHECK(textBlob.status == mtn::model::CodecStatus::Ok);
        mtn::model::InkStroke stroke;
        stroke.points.push_back({{3, 4}, 0.8, 0.0, {}, {}});
        const auto inkBlob = mtn::model::encode_ink_v1(stroke);
        CHECK(inkBlob.status == mtn::model::CodecStatus::Ok);
        const auto insertPayload = [&](const QString& id, const QString& kind,
                                       const std::vector<std::uint8_t>& bytes) {
            QSqlQuery write(db);
            write.prepare("INSERT INTO page_objects(id, page_id, kind, z_order, reading_order, "
                          "tx, ty, payload) VALUES (?, ?, ?, 0, 0, 0, 0, ?)");
            write.addBindValue(id);
            write.addBindValue("33333333-3333-4333-8333-333333333333");
            write.addBindValue(kind);
            write.addBindValue(QByteArray(reinterpret_cast<const char*>(bytes.data()),
                                         static_cast<qsizetype>(bytes.size())));
            return write.exec();
        };
        CHECK(insertPayload("55555555-5555-4555-8555-555555555555", "text", textBlob.bytes));
        CHECK(insertPayload("66666666-6666-4666-8666-666666666666", "ink", inkBlob.bytes));
        CHECK(query.exec("SELECT kind, payload FROM page_objects ORDER BY kind DESC"));
        CHECK(query.next() && query.value(0).toString() == "text");
        auto blob = query.value(1).toByteArray();
        const auto loadedText = mtn::model::decode_text_v1(std::span<const std::uint8_t>(
            reinterpret_cast<const std::uint8_t*>(blob.constData()), blob.size()));
        CHECK(loadedText.status == mtn::model::CodecStatus::Ok);
        CHECK(loadedText.value.paragraphs[0].runs[0].utf8 == "Texto persistido — שלום");
        CHECK(query.next() && query.value(0).toString() == "ink");
        blob = query.value(1).toByteArray();
        const auto loadedInk = mtn::model::decode_ink_v1(std::span<const std::uint8_t>(
            reinterpret_cast<const std::uint8_t*>(blob.constData()), blob.size()));
        CHECK(loadedInk.status == mtn::model::CodecStatus::Ok);
        CHECK(loadedInk.value.points[0].pressure == 0.8);
        CHECK(query.exec("INSERT INTO pages VALUES ('44444444-4444-4444-8444-444444444444', "
                         "'22222222-2222-4222-8222-222222222222', 'Nova página', 1)"));
        CHECK(query.exec("SELECT COUNT(*) FROM page_settings"));
        CHECK(query.next() && query.value(0).toInt() == 2);
        CHECK(migrateNotebookSchemaV3(db) == NotebookSchemaStatus::MigratedV3);
        CHECK(inspectNotebookSchema(db) == NotebookSchemaStatus::ReadyV3);
        CHECK(migrateNotebookSchemaV3(db) == NotebookSchemaStatus::ReadyV3);
        CHECK(query.exec("SELECT text_width_pt, text_max_width_pt, text_fixed_width "
                         "FROM page_objects WHERE kind = 'text'"));
        CHECK(query.next() && query.value(0).toDouble() == 240 &&
              query.value(1).toDouble() == 500 && query.value(2).toInt() == 0);
        query.finish();
        CHECK(migrateNotebookSchemaV4(db) == NotebookSchemaStatus::MigratedV4);
        CHECK(inspectNotebookSchema(db) == NotebookSchemaStatus::ReadyV4);
        CHECK(migrateNotebookSchemaV4(db) == NotebookSchemaStatus::ReadyV4);
        CHECK(query.exec("SELECT payload_version FROM page_objects WHERE kind = 'text'"));
        CHECK(query.next() && query.value(0).toInt() == 1);
        CHECK(query.exec("PRAGMA user_version = 5"));
        db.close();
    }
    QSqlDatabase::removeDatabase("schema-fixture");
    const auto futureHash = hashFile(path);
    CHECK(!futureHash.isEmpty());
    {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "future-fixture");
        db.setDatabaseName(path);
        CHECK(db.open());
        CHECK(inspectNotebookSchema(db) == NotebookSchemaStatus::FutureVersion);
        CHECK(migrateNotebookSchema(db) == NotebookSchemaStatus::FutureVersion);
        CHECK(migrateNotebookSchemaV3(db) == NotebookSchemaStatus::FutureVersion);
        CHECK(migrateNotebookSchemaV4(db) == NotebookSchemaStatus::FutureVersion);
        db.close();
    }
    QSqlDatabase::removeDatabase("future-fixture");
    CHECK(hashFile(path) == futureHash);

    const auto badPath = directory.filePath("bad.sqlite");
    {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "bad-fixture");
        db.setDatabaseName(badPath);
        CHECK(db.open());
        CHECK(QSqlQuery(db).exec("PRAGMA user_version = 1"));
        CHECK(inspectNotebookSchema(db) == NotebookSchemaStatus::InvalidSchema);
        CHECK(migrateNotebookSchema(db) == NotebookSchemaStatus::InvalidSchema);
        QSqlQuery query(db);
        CHECK(query.exec("PRAGMA user_version") && query.next() && query.value(0).toInt() == 1);
        db.close();
    }
    QSqlDatabase::removeDatabase("bad-fixture");

    const auto collisionPath = directory.filePath("collision.sqlite");
    {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "collision-fixture");
        db.setDatabaseName(collisionPath);
        CHECK(db.open());
        CHECK(loadFixture(db));
        CHECK(QSqlQuery(db).exec("CREATE TABLE page_settings(dummy TEXT)"));
        CHECK(migrateNotebookSchema(db) == NotebookSchemaStatus::SqlError);
        QSqlQuery query(db);
        CHECK(query.exec("PRAGMA user_version") && query.next() && query.value(0).toInt() == 1);
        CHECK(query.exec("SELECT title FROM pages") && query.next());
        CHECK(query.value(0).toString() == "Página preservada");
        CHECK(!query.exec("SELECT id FROM page_objects"));
        db.close();
    }
    QSqlDatabase::removeDatabase("collision-fixture");
    return 0;
}
