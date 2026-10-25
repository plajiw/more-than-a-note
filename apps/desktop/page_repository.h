#pragma once

#include "page_content.h"

#include <QSqlDatabase>
#include <QString>

enum class PageStorageStatus {
    Ok, LegacyEmpty, MissingPage, InvalidSchema, InvalidContent,
    UnsupportedContent, TooLarge, SqlError, OutOfMemory
};

struct PageLoadResult {
    PageStorageStatus status = PageStorageStatus::SqlError;
    mtn::model::PageContent page;
};

// The repository owns no connection. Callers keep their notebook connection
// open and control when an edit is committed. Each object write is atomic;
// opening a v1 page never migrates it merely to read an empty page.
PageLoadResult loadPageContent(QSqlDatabase& db, const QString& pageId);
PageStorageStatus savePageObject(QSqlDatabase& db, const mtn::model::PageObject& object);
PageStorageStatus deletePageObject(QSqlDatabase& db, const QString& pageId,
                                   const QString& objectId);
