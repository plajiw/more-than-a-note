#pragma once

#include <QSqlDatabase>

// E3.4 prepares the schema without migrating on ordinary open. E4 will call
// migrateNotebookSchema before storing page content.
enum class NotebookSchemaStatus {
    LegacyV1, ReadyV2, MigratedV2, FutureVersion,
    UnsupportedVersion, InvalidSchema, SqlError
};

NotebookSchemaStatus inspectNotebookSchema(QSqlDatabase& db);
NotebookSchemaStatus migrateNotebookSchema(QSqlDatabase& db);
