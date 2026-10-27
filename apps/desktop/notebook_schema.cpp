#include "notebook_schema.h"

#include <QSqlQuery>

namespace {
bool hasColumns(QSqlDatabase& db, const char* queryText) {
    QSqlQuery query(db);
    return query.exec(QString::fromLatin1(queryText));
}

bool validV1(QSqlDatabase& db) {
    return hasColumns(db, "SELECT id, title, last_section, last_page FROM notebook LIMIT 0") &&
           hasColumns(db, "SELECT id, title, color, position FROM sections LIMIT 0") &&
           hasColumns(db, "SELECT id, section_id, title, position FROM pages LIMIT 0");
}

bool validV2(QSqlDatabase& db) {
    return validV1(db) &&
           hasColumns(db, "SELECT page_id, canvas_kind, width_pt, height_pt, paper_kind FROM page_settings LIMIT 0") &&
           hasColumns(db, "SELECT id, page_id, kind, z_order, reading_order, tx, ty, rotation, scale_x, scale_y, locked, accessible_description, payload_version, payload FROM page_objects LIMIT 0") &&
           hasColumns(db, "SELECT id, sha256, kind, mime, byte_size, width_px, height_px, source_name FROM assets LIMIT 0");
}

bool validV3(QSqlDatabase& db) {
    return validV2(db) &&
           hasColumns(db, "SELECT text_width_pt, text_max_width_pt, text_fixed_width FROM page_objects LIMIT 0");
}

bool run(QSqlDatabase& db, const char* sql) {
    QSqlQuery query(db);
    return query.exec(QString::fromLatin1(sql));
}
} // namespace

NotebookSchemaStatus inspectNotebookSchema(QSqlDatabase& db) {
    if (!db.isOpen()) return NotebookSchemaStatus::SqlError;
    QSqlQuery query(db);
    if (!query.exec("PRAGMA user_version") || !query.next())
        return NotebookSchemaStatus::SqlError;
    const auto version = query.value(0).toInt();
    if (version > 4) return NotebookSchemaStatus::FutureVersion;
    if (version < 1) return NotebookSchemaStatus::UnsupportedVersion;
    if (version == 1) return validV1(db) ? NotebookSchemaStatus::LegacyV1 :
                                          NotebookSchemaStatus::InvalidSchema;
    if (version == 2)
        return validV2(db) ? NotebookSchemaStatus::ReadyV2 : NotebookSchemaStatus::InvalidSchema;
    if (version == 3)
        return validV3(db) ? NotebookSchemaStatus::ReadyV3 : NotebookSchemaStatus::InvalidSchema;
    return validV3(db) ? NotebookSchemaStatus::ReadyV4 : NotebookSchemaStatus::InvalidSchema;
}

NotebookSchemaStatus migrateNotebookSchema(QSqlDatabase& db) {
    const auto existing = inspectNotebookSchema(db);
    if (existing != NotebookSchemaStatus::LegacyV1) return existing;
    if (!db.transaction()) return NotebookSchemaStatus::SqlError;
    const bool created =
        run(db, "CREATE TABLE page_settings ("
                "page_id TEXT PRIMARY KEY REFERENCES pages(id) ON DELETE CASCADE, "
                "canvas_kind INTEGER NOT NULL DEFAULT 0 CHECK(canvas_kind IN (0, 1)), "
                "width_pt REAL NOT NULL DEFAULT 595.2755905512 CHECK(width_pt > 0), "
                "height_pt REAL NOT NULL DEFAULT 841.8897637795 CHECK(height_pt > 0), "
                "paper_kind INTEGER NOT NULL DEFAULT 0 CHECK(paper_kind BETWEEN 0 AND 4))") &&
        run(db, "INSERT INTO page_settings(page_id) SELECT id FROM pages") &&
        run(db, "CREATE TRIGGER page_settings_after_page_insert "
                "AFTER INSERT ON pages BEGIN "
                "INSERT INTO page_settings(page_id) VALUES (NEW.id); END") &&
        run(db, "CREATE TABLE page_objects ("
                "id TEXT PRIMARY KEY, page_id TEXT NOT NULL REFERENCES pages(id) ON DELETE CASCADE, "
                "kind TEXT NOT NULL CHECK(kind IN ('text', 'ink')), "
                "z_order INTEGER NOT NULL, reading_order INTEGER NOT NULL, "
                "tx REAL NOT NULL, ty REAL NOT NULL, rotation REAL NOT NULL DEFAULT 0, "
                "scale_x REAL NOT NULL DEFAULT 1, scale_y REAL NOT NULL DEFAULT 1, "
                "locked INTEGER NOT NULL DEFAULT 0 CHECK(locked IN (0, 1)), "
                "accessible_description TEXT NOT NULL DEFAULT '', "
                "payload_version INTEGER NOT NULL DEFAULT 1 CHECK(payload_version = 1), "
                "payload BLOB NOT NULL)") &&
        run(db, "CREATE INDEX page_objects_order ON page_objects(page_id, z_order, id)") &&
        run(db, "CREATE TABLE assets ("
                "id TEXT PRIMARY KEY, sha256 TEXT NOT NULL, kind INTEGER NOT NULL, "
                "mime TEXT NOT NULL, byte_size INTEGER NOT NULL CHECK(byte_size > 0), "
                "width_px INTEGER NOT NULL CHECK(width_px > 0), "
                "height_px INTEGER NOT NULL CHECK(height_px > 0), "
                "source_name TEXT NOT NULL)") &&
        run(db, "PRAGMA user_version = 2");
    if (!created || !db.commit()) {
        db.rollback();
        return NotebookSchemaStatus::SqlError;
    }
    return NotebookSchemaStatus::MigratedV2;
}

NotebookSchemaStatus migrateNotebookSchemaV3(QSqlDatabase& db) {
    auto current = inspectNotebookSchema(db);
    if (current == NotebookSchemaStatus::LegacyV1) {
        current = migrateNotebookSchema(db);
        if (current != NotebookSchemaStatus::MigratedV2) return current;
    }
    if (current == NotebookSchemaStatus::ReadyV3) return current;
    if (current != NotebookSchemaStatus::ReadyV2 &&
        current != NotebookSchemaStatus::MigratedV2) return current;
    if (!db.transaction()) return NotebookSchemaStatus::SqlError;
    const bool changed =
        run(db, "ALTER TABLE page_objects ADD COLUMN text_width_pt REAL NOT NULL DEFAULT 240 CHECK(text_width_pt > 0)") &&
        run(db, "ALTER TABLE page_objects ADD COLUMN text_max_width_pt REAL NOT NULL DEFAULT 500 CHECK(text_max_width_pt > 0)") &&
        run(db, "ALTER TABLE page_objects ADD COLUMN text_fixed_width INTEGER NOT NULL DEFAULT 0 CHECK(text_fixed_width IN (0, 1))") &&
        run(db, "PRAGMA user_version = 3");
    if (!changed || !db.commit()) {
        db.rollback();
        return NotebookSchemaStatus::SqlError;
    }
    return NotebookSchemaStatus::MigratedV3;
}

NotebookSchemaStatus migrateNotebookSchemaV4(QSqlDatabase& db) {
    auto current = inspectNotebookSchema(db);
    if (current == NotebookSchemaStatus::LegacyV1 || current == NotebookSchemaStatus::ReadyV2) {
        current = migrateNotebookSchemaV3(db);
        if (current != NotebookSchemaStatus::MigratedV3) return current;
    }
    if (current == NotebookSchemaStatus::ReadyV4) return current;
    if (current != NotebookSchemaStatus::ReadyV3 &&
        current != NotebookSchemaStatus::MigratedV3) return current;
    if (!db.transaction()) return NotebookSchemaStatus::SqlError;
    const bool changed =
        run(db, "CREATE TABLE page_objects_v4 ("
                "id TEXT PRIMARY KEY, page_id TEXT NOT NULL REFERENCES pages(id) ON DELETE CASCADE, "
                "kind TEXT NOT NULL CHECK(kind IN ('text', 'ink')), "
                "z_order INTEGER NOT NULL, reading_order INTEGER NOT NULL, "
                "tx REAL NOT NULL, ty REAL NOT NULL, rotation REAL NOT NULL DEFAULT 0, "
                "scale_x REAL NOT NULL DEFAULT 1, scale_y REAL NOT NULL DEFAULT 1, "
                "locked INTEGER NOT NULL DEFAULT 0 CHECK(locked IN (0, 1)), "
                "accessible_description TEXT NOT NULL DEFAULT '', "
                "payload_version INTEGER NOT NULL DEFAULT 1 CHECK(payload_version IN (1, 2)), "
                "payload BLOB NOT NULL, "
                "text_width_pt REAL NOT NULL DEFAULT 240 CHECK(text_width_pt > 0), "
                "text_max_width_pt REAL NOT NULL DEFAULT 500 CHECK(text_max_width_pt > 0), "
                "text_fixed_width INTEGER NOT NULL DEFAULT 0 CHECK(text_fixed_width IN (0, 1)))") &&
        run(db, "INSERT INTO page_objects_v4 SELECT id, page_id, kind, z_order, reading_order, "
                "tx, ty, rotation, scale_x, scale_y, locked, accessible_description, "
                "payload_version, payload, text_width_pt, text_max_width_pt, text_fixed_width "
                "FROM page_objects") &&
        run(db, "DROP TABLE page_objects") &&
        run(db, "ALTER TABLE page_objects_v4 RENAME TO page_objects") &&
        run(db, "CREATE INDEX page_objects_order ON page_objects(page_id, z_order, id)") &&
        run(db, "PRAGMA user_version = 4");
    if (!changed || !db.commit()) {
        db.rollback();
        return NotebookSchemaStatus::SqlError;
    }
    return NotebookSchemaStatus::MigratedV4;
}
