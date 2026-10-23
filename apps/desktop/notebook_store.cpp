#include "notebook_store.h"

#include <QDir>
#include <QFileInfo>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QUuid>
#include <QVariantMap>

namespace {
QString newId() { return QUuid::createUuid().toString(QUuid::WithoutBraces); }

// Opens a SQLite connection under a unique name. The caller owns it and must
// release it with closeDatabase once no QSqlDatabase copy is alive.
QString openDatabase(const QString& path) {
    const QString connection = newId();
    bool opened = false;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", connection);
        db.setDatabaseName(path);
        if (db.open()) {
            QSqlQuery(db).exec("PRAGMA foreign_keys = ON");
            opened = true;
        }
    }
    if (!opened) {
        QSqlDatabase::removeDatabase(connection);
        return {};
    }
    return connection;
}

void closeDatabase(const QString& connection) {
    QSqlDatabase::database(connection, false).close();
    QSqlDatabase::removeDatabase(connection);
}

template <typename T, typename F>
T withDatabase(const QString& path, T fallback, F action) {
    const QString connection = openDatabase(path);
    if (connection.isEmpty()) return fallback;
    T result = fallback;
    {
        QSqlDatabase db = QSqlDatabase::database(connection, false);
        result = action(db);
    }
    closeDatabase(connection);
    return result;
}

bool containsId(const QVariantList& list, const QString& id) {
    for (const QVariant& item : list)
        if (item.toMap().value("id").toString() == id) return true;
    return false;
}
}

NotebookStore::NotebookStore(QObject* parent) : QObject(parent) {
    root_ = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/notebooks";
    if (!QDir().mkpath(root_)) setError("Não foi possível criar a pasta de cadernos.");
}

NotebookStore::~NotebookStore() { closeConnection(); }

QString NotebookStore::databasePath(const QString& id) const {
    return root_ + "/" + id + "/notebook.sqlite";
}

bool NotebookStore::validNotebookId(const QString& id) const {
    const QUuid uuid = QUuid::fromString(id);
    return !uuid.isNull() && uuid.toString(QUuid::WithoutBraces) == id;
}

QSqlDatabase NotebookStore::activeDatabase() const {
    return QSqlDatabase::database(connection_, false);
}

void NotebookStore::closeConnection() {
    if (connection_.isEmpty()) return;
    closeDatabase(connection_);
    connection_.clear();
}

void NotebookStore::setError(const QString& message) {
    if (error_ == message) return;
    error_ = message;
    emit errorChanged();
}

// Reading every notebook's title opens each database, so it happens once and
// again only after a notebook is created.
QVariantList NotebookStore::notebooks() const {
    if (notebooksLoaded_) return notebooks_;
    notebooks_.clear();
    const auto folders = QDir(root_).entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    for (const QString& id : folders) {
        if (!validNotebookId(id) || !QFileInfo::exists(databasePath(id))) continue;
        const QVariantMap item = withDatabase<QVariantMap>(databasePath(id), {}, [&](QSqlDatabase& db) {
            QSqlQuery query(db);
            if (!query.exec("SELECT title FROM notebook LIMIT 1") || !query.next()) return QVariantMap{};
            return QVariantMap{{"id", id}, {"title", query.value(0).toString()}};
        });
        if (!item.isEmpty()) notebooks_.append(item);
    }
    notebooksLoaded_ = true;
    return notebooks_;
}

void NotebookStore::loadSections() {
    sections_.clear();
    QSqlQuery query(activeDatabase());
    if (!query.exec("SELECT id, title, color FROM sections ORDER BY position, id")) return;
    while (query.next())
        sections_.append(QVariantMap{{"id", query.value(0)}, {"title", query.value(1)}, {"color", query.value(2)}});
}

void NotebookStore::loadPages() {
    pages_.clear();
    if (sectionId_.isEmpty()) return;
    QSqlQuery query(activeDatabase());
    query.prepare("SELECT id, title FROM pages WHERE section_id = ? ORDER BY position, id");
    query.addBindValue(sectionId_);
    if (!query.exec()) return;
    while (query.next()) pages_.append(QVariantMap{{"id", query.value(0)}, {"title", query.value(1)}});
}

// Changes the in-memory selection only; callers decide whether to persist it
// and which signals to emit.
void NotebookStore::applySection(const QString& id) {
    sectionId_ = id;
    pageId_.clear();
    pageTitle_.clear();
    loadPages();
    if (!pages_.isEmpty()) applyPage(pages_.first().toMap().value("id").toString());
}

bool NotebookStore::applyPage(const QString& id) {
    for (const QVariant& item : pages_) {
        const auto page = item.toMap();
        if (page.value("id").toString() == id) {
            pageId_ = id;
            pageTitle_ = page.value("title").toString();
            return true;
        }
    }
    return false;
}

bool NotebookStore::createNotebook(const QString& name) {
    const QString title = name.trimmed();
    if (title.isEmpty()) { setError("Informe um nome para o caderno."); return false; }
    const QString id = newId();
    if (!QDir().mkpath(root_ + "/" + id)) { setError("Não foi possível criar o caderno."); return false; }
    const bool saved = withDatabase<bool>(databasePath(id), false, [&](QSqlDatabase& db) {
        QSqlQuery query(db);
        if (!db.transaction()) return false;
        if (!query.exec("PRAGMA user_version = 1") ||
            !query.exec("CREATE TABLE notebook (id TEXT PRIMARY KEY, title TEXT NOT NULL, last_section TEXT, last_page TEXT)") ||
            !query.exec("CREATE TABLE sections (id TEXT PRIMARY KEY, title TEXT NOT NULL, color TEXT NOT NULL, position INTEGER NOT NULL)") ||
            !query.exec("CREATE TABLE pages (id TEXT PRIMARY KEY, section_id TEXT NOT NULL REFERENCES sections(id), title TEXT NOT NULL, position INTEGER NOT NULL)")) {
            db.rollback(); return false;
        }
        query.prepare("INSERT INTO notebook (id, title) VALUES (?, ?)");
        query.addBindValue(id);
        query.addBindValue(title);
        if (!query.exec()) { db.rollback(); return false; }
        return db.commit();
    });
    if (!saved) { QDir(root_ + "/" + id).removeRecursively(); setError("Não foi possível salvar o caderno."); return false; }
    notebooksLoaded_ = false;
    emit notebooksChanged();
    return openNotebook(id);
}

// Opening only reads: the remembered section/page is restored without writing
// it back.
bool NotebookStore::openNotebook(const QString& id) {
    if (!validNotebookId(id) || !QFileInfo::exists(databasePath(id))) { setError("Caderno não encontrado."); return false; }
    const QString connection = openDatabase(databasePath(id));
    QVariantMap data;
    if (!connection.isEmpty()) {
        QSqlQuery query(QSqlDatabase::database(connection, false));
        if (query.exec("PRAGMA user_version") && query.next() && query.value(0).toInt() == 1 &&
            query.exec("SELECT title, last_section, last_page FROM notebook LIMIT 1") && query.next())
            data = {{"title", query.value(0)}, {"section", query.value(1)}, {"page", query.value(2)}};
    }
    if (data.isEmpty()) {
        if (!connection.isEmpty()) closeDatabase(connection);
        setError("Caderno inválido ou incompatível.");
        return false;
    }

    closeConnection();
    connection_ = connection;
    notebookId_ = id;
    notebookName_ = data.value("title").toString();
    sectionId_.clear(); pageId_.clear(); pageTitle_.clear(); pages_.clear();
    loadSections();
    QString wantedSection = data.value("section").toString();
    if (!containsId(sections_, wantedSection) && !sections_.isEmpty())
        wantedSection = sections_.first().toMap().value("id").toString();
    if (containsId(sections_, wantedSection)) applySection(wantedSection);
    applyPage(data.value("page").toString());

    setError({});
    emit notebookChanged();
    emit sectionsChanged();
    emit pagesChanged();
    emit selectionChanged();
    return true;
}

void NotebookStore::closeNotebook() {
    closeConnection();
    notebookId_.clear(); notebookName_.clear(); sectionId_.clear(); pageId_.clear(); pageTitle_.clear();
    sections_.clear(); pages_.clear();
    setError({});
    emit notebookChanged();
    emit sectionsChanged();
    emit pagesChanged();
    emit selectionChanged();
}

bool NotebookStore::addSection(const QString& title) {
    if (notebookId_.isEmpty() || title.trimmed().isEmpty()) return false;
    const QString id = newId();
    QSqlQuery query(activeDatabase());
    query.prepare("INSERT INTO sections (id, title, color, position) VALUES (?, ?, ?, (SELECT COUNT(*) FROM sections))");
    query.addBindValue(id); query.addBindValue(title.trimmed()); query.addBindValue("#C58E61");
    if (!query.exec()) { setError("Não foi possível salvar a seção."); return false; }
    loadSections();
    emit sectionsChanged();
    return selectSection(id);
}

bool NotebookStore::selectSection(const QString& id) {
    if (!containsId(sections_, id)) return false;
    applySection(id);
    rememberSelection();
    emit pagesChanged();
    emit selectionChanged();
    return true;
}

bool NotebookStore::addPage(const QString& title) {
    if (notebookId_.isEmpty() || sectionId_.isEmpty() || title.trimmed().isEmpty()) return false;
    const QString id = newId();
    QSqlQuery query(activeDatabase());
    query.prepare("INSERT INTO pages (id, section_id, title, position) VALUES (?, ?, ?, (SELECT COUNT(*) FROM pages WHERE section_id = ?))");
    query.addBindValue(id); query.addBindValue(sectionId_); query.addBindValue(title.trimmed()); query.addBindValue(sectionId_);
    if (!query.exec()) { setError("Não foi possível salvar a página."); return false; }
    loadPages();
    emit pagesChanged();
    return selectPage(id);
}

bool NotebookStore::selectPage(const QString& id) {
    if (!applyPage(id)) return false;
    rememberSelection();
    emit selectionChanged();
    return true;
}

void NotebookStore::rememberSelection() {
    if (notebookId_.isEmpty()) return;
    QSqlQuery query(activeDatabase());
    query.prepare("UPDATE notebook SET last_section = ?, last_page = ?");
    query.addBindValue(sectionId_); query.addBindValue(pageId_);
    if (!query.exec()) setError("Não foi possível guardar a última página visitada.");
}
