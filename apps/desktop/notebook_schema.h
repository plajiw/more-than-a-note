#pragma once

#include <QSqlDatabase>

// Reading an older notebook never migrates it. The repository migrates only
// before its first content write.
enum class NotebookSchemaStatus {
    LegacyV1, ReadyV2, MigratedV2, ReadyV3, MigratedV3,
    ReadyV4, MigratedV4, FutureVersion,
    UnsupportedVersion, InvalidSchema, SqlError
};

NotebookSchemaStatus inspectNotebookSchema(QSqlDatabase& db);
NotebookSchemaStatus migrateNotebookSchema(QSqlDatabase& db);
NotebookSchemaStatus migrateNotebookSchemaV3(QSqlDatabase& db);
NotebookSchemaStatus migrateNotebookSchemaV4(QSqlDatabase& db);
