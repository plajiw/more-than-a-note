#pragma once

#include <QSqlDatabase>

// Reading an older notebook never migrates it. The repository migrates only
// before its first content write.
enum class NotebookSchemaStatus {
    LegacyV1, ReadyV2, MigratedV2, ReadyV3, MigratedV3,
    ReadyV4, MigratedV4, ReadyV5, MigratedV5, FutureVersion,
    UnsupportedVersion, InvalidSchema, SqlError
};

NotebookSchemaStatus inspectNotebookSchema(QSqlDatabase& db);
NotebookSchemaStatus migrateNotebookSchema(QSqlDatabase& db);
NotebookSchemaStatus migrateNotebookSchemaV3(QSqlDatabase& db);
NotebookSchemaStatus migrateNotebookSchemaV4(QSqlDatabase& db);
// v5 (C3): text boxes get their own height and may rotate.
NotebookSchemaStatus migrateNotebookSchemaV5(QSqlDatabase& db);
