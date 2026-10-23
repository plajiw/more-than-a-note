#include "notebook_store.h"

#include <QCoreApplication>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QStandardPaths>

#include <iostream>

#define CHECK(condition) do { if (!(condition)) { \
    std::cerr << "Check failed: " #condition " at line " << __LINE__ << '\n'; \
    return 1; \
} } while (false)

int main(int argc, char* argv[]) {
    QCoreApplication app(argc, argv);
    QCoreApplication::setOrganizationName("more-than-a-note-tests");
    QCoreApplication::setApplicationName("notebook-store-test");
    QStandardPaths::setTestModeEnabled(true);

    QString notebookId;
    QString sectionId;
    QString pageId;
    {
        NotebookStore store;
        CHECK(store.createNotebook("Architecture"));
        notebookId = store.activeNotebookId();
        CHECK(store.addSection("Processor"));
        sectionId = store.activeSectionId();
        CHECK(store.addPage("Pipeline"));
        pageId = store.activePageId();
        CHECK(store.sections().size() == 1);
        CHECK(store.pages().size() == 1);
        store.closeNotebook();
    }
    {
        NotebookStore reopened;
        CHECK(reopened.notebooks().size() >= 1);
        CHECK(reopened.openNotebook(notebookId));
        CHECK(reopened.activeNotebookName() == "Architecture");
        CHECK(reopened.activeSectionId() == sectionId);
        CHECK(reopened.activePageId() == pageId);
        CHECK(reopened.activePageTitle() == "Pipeline");
        CHECK(reopened.createNotebook("Second notebook"));
        CHECK(reopened.sections().isEmpty());
        CHECK(reopened.pages().isEmpty());
        CHECK(reopened.openNotebook(notebookId));
        CHECK(reopened.activePageId() == pageId);
    }
    const QString dbPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
        + "/notebooks/" + notebookId + "/notebook.sqlite";
    {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "future-schema-test");
        db.setDatabaseName(dbPath);
        CHECK(db.open());
        QSqlQuery query(db);
        CHECK(query.exec("PRAGMA user_version = 2"));
        db.close();
    }
    QSqlDatabase::removeDatabase("future-schema-test");
    NotebookStore incompatible;
    CHECK(!incompatible.openNotebook(notebookId));
    CHECK(incompatible.error().contains("incompatível"));
}
