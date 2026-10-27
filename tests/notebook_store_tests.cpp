#include "notebook_store.h"
#include "notebook_schema.h"

#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QStandardPaths>

#include <iostream>

#define CHECK(condition) do { if (!(condition)) { \
    std::cerr << "Check failed: " #condition " at line " << __LINE__ << '\n'; \
    return 1; \
} } while (false)

static QByteArray fileHash(const QString& path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return {};
    return QCryptographicHash::hash(file.readAll(), QCryptographicHash::Sha256);
}

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
        CHECK(store.renameSection(sectionId, "Processors"));
        CHECK(store.sections().first().toMap().value("title").toString() == "Processors");
        CHECK(store.setSectionColor(sectionId, "#6A91B8"));
        CHECK(store.sections().first().toMap().value("color").toString() == "#6A91B8");
        CHECK(store.renamePage(pageId, "Pipeline revised"));
        CHECK(store.activePageTitle() == "Pipeline revised");
        store.closeNotebook();
    }
    {
        NotebookStore reopened;
        CHECK(reopened.notebooks().size() >= 1);
        CHECK(reopened.openNotebook(notebookId));
        CHECK(reopened.activeNotebookName() == "Architecture");
        CHECK(reopened.activeSectionId() == sectionId);
        CHECK(reopened.activePageId() == pageId);
        CHECK(reopened.activePageTitle() == "Pipeline revised");
        CHECK(reopened.createNotebook("Second notebook"));
        CHECK(reopened.sections().isEmpty());
        CHECK(reopened.pages().isEmpty());
        CHECK(reopened.openNotebook(notebookId));
        CHECK(reopened.activePageId() == pageId);
    }
    {
        // The Library lists counts and activity; rename and trash update one entry.
        NotebookStore store;
        QVariantMap entry;
        for (const QVariant& item : store.notebooks())
            if (item.toMap().value("id").toString() == notebookId) entry = item.toMap();
        CHECK(entry.value("sections").toInt() == 1);
        CHECK(entry.value("pages").toInt() == 1);
        CHECK(entry.value("modified").toDateTime().isValid());
        CHECK(store.renameNotebook(notebookId, "Architecture notes"));
        CHECK(!store.renameNotebook(notebookId, "  "));
        CHECK(store.renameNotebook(notebookId, "Architecture"));
        CHECK(store.createNotebook("Disposable"));
        const QString disposable = store.activeNotebookId();
        CHECK(store.addSection("Temp"));
        store.closeNotebook();
        for (const QVariant& item : store.notebooks())
            if (item.toMap().value("id").toString() == disposable) CHECK(item.toMap().value("sections").toInt() == 1);
        const int before = static_cast<int>(store.notebooks().size());
        CHECK(store.deleteNotebook(disposable));
        CHECK(store.notebooks().size() == before - 1);
        const QString trash = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/trash";
        CHECK(!QDir(trash).entryList({disposable + "-*"}, QDir::Dirs).isEmpty());
        CHECK(!store.deleteNotebook(disposable));
    }
    const QString dbPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
        + "/notebooks/" + notebookId + "/notebook.sqlite";
    {
        // Opening a notebook only reads it.
        const QByteArray before = fileHash(dbPath);
        NotebookStore store;
        CHECK(store.openNotebook(notebookId));
        store.closeNotebook();
        CHECK(fileHash(dbPath) == before);

        // Lists come from memory: one open notifies each list once.
        int sectionsSignals = 0;
        int pagesSignals = 0;
        QObject::connect(&store, &NotebookStore::sectionsChanged, [&] { ++sectionsSignals; });
        QObject::connect(&store, &NotebookStore::pagesChanged, [&] { ++pagesSignals; });
        CHECK(store.openNotebook(notebookId));
        CHECK(sectionsSignals == 1);
        CHECK(pagesSignals == 1);

        // The cached notebook list is refreshed after a creation.
        const auto count = store.notebooks().size();
        CHECK(store.createNotebook("Third notebook"));
        CHECK(store.notebooks().size() == count + 1);
    }
    {
        NotebookStore store;
        CHECK(store.openNotebook(notebookId));
        CHECK(store.addPage("Temporary"));
        const QString temporaryPage = store.activePageId();
        CHECK(store.deletePage(temporaryPage));
        CHECK(store.activePageId() == pageId);
        CHECK(store.pages().size() == 1);
        CHECK(store.addSection("Temporary section"));
        const QString temporarySection = store.activeSectionId();
        CHECK(store.addPage("Child page"));
        CHECK(store.deleteSection(temporarySection));
        CHECK(store.activeSectionId() == sectionId);
        CHECK(store.activePageId() == pageId);
        CHECK(store.sections().size() == 1);
        CHECK(store.addSection("After deletion"));
        CHECK(store.sections().size() == 2);
    }
    {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "future-schema-test");
        db.setDatabaseName(dbPath);
        CHECK(db.open());
        CHECK(migrateNotebookSchema(db) == NotebookSchemaStatus::MigratedV2);
        db.close();
    }
    QSqlDatabase::removeDatabase("future-schema-test");
    {
        NotebookStore upgraded;
        CHECK(upgraded.openNotebook(notebookId));
        CHECK(upgraded.activeNotebookId() == notebookId);
        CHECK(upgraded.addPage("Page after migration"));
    }
    {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "future-schema-test");
        db.setDatabaseName(dbPath);
        CHECK(db.open());
        QSqlQuery query(db);
        CHECK(query.exec("PRAGMA user_version = 5"));
        db.close();
    }
    QSqlDatabase::removeDatabase("future-schema-test");
    NotebookStore incompatible;
    CHECK(!incompatible.openNotebook(notebookId));
    CHECK(incompatible.error().contains("incompatível"));
}
