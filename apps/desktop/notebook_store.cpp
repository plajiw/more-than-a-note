#include "notebook_store.h"
#include "notebook_schema.h"

#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QSqlError>
#include <QSqlQuery>
#include <QRegularExpression>
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

// Title, section and page counts for the Library. "modified" is the latest
// file activity (database or its WAL), which includes navigation, not only edits.
QVariantMap NotebookStore::describeNotebook(const QString& id, QSqlDatabase& db) const {
    QSqlQuery query(db);
    if (!query.exec("SELECT title, (SELECT COUNT(*) FROM sections), (SELECT COUNT(*) FROM pages) FROM notebook LIMIT 1") ||
        !query.next()) return {};
    QDateTime modified = QFileInfo(databasePath(id)).lastModified();
    const QFileInfo wal(databasePath(id) + "-wal");
    if (wal.exists() && wal.lastModified() > modified) modified = wal.lastModified();
    return {{"id", id}, {"title", query.value(0).toString()}, {"sections", query.value(1).toInt()},
            {"pages", query.value(2).toInt()}, {"modified", modified}};
}

// Updates one cached entry from an open database, without rereading the others.
void NotebookStore::refreshNotebook(const QString& id, QSqlDatabase& db) {
    if (!notebooksLoaded_) return;
    const QVariantMap item = describeNotebook(id, db);
    for (QVariant& entry : notebooks_)
        if (entry.toMap().value("id").toString() == id) { entry = item; break; }
    emit notebooksChanged();
}

// Reading every notebook opens each database, so it happens once; later
// changes update single entries.
QVariantList NotebookStore::notebooks() const {
    if (notebooksLoaded_) return notebooks_;
    notebooks_.clear();
    const auto folders = QDir(root_).entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    for (const QString& id : folders) {
        if (!validNotebookId(id) || !QFileInfo::exists(databasePath(id))) continue;
        const QVariantMap item = withDatabase<QVariantMap>(databasePath(id), {}, [&](QSqlDatabase& db) {
            return describeNotebook(id, db);
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
        QSqlDatabase db = QSqlDatabase::database(connection, false);
        QSqlQuery query(db);
        const auto schema = inspectNotebookSchema(db);
        if ((schema == NotebookSchemaStatus::LegacyV1 || schema == NotebookSchemaStatus::ReadyV2 ||
             schema == NotebookSchemaStatus::ReadyV3 || schema == NotebookSchemaStatus::ReadyV4) &&
            query.exec("SELECT title, last_section, last_page FROM notebook LIMIT 1") && query.next())
            data = {{"title", query.value(0)}, {"section", query.value(1)}, {"page", query.value(2)}};
    }
    if (data.isEmpty()) {
        if (!connection.isEmpty()) closeDatabase(connection);
        setError("Caderno inválido ou incompatível.");
        return false;
    }

    emit aboutToChangeSelection();
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
    emit aboutToChangeSelection();
    if (!notebookId_.isEmpty()) {
        QSqlDatabase db = activeDatabase();
        refreshNotebook(notebookId_, db);
    }
    closeConnection();
    notebookId_.clear(); notebookName_.clear(); sectionId_.clear(); pageId_.clear(); pageTitle_.clear();
    sections_.clear(); pages_.clear();
    setError({});
    emit notebookChanged();
    emit sectionsChanged();
    emit pagesChanged();
    emit selectionChanged();
}

bool NotebookStore::renameNotebook(const QString& id, const QString& name) {
    const QString title = name.trimmed();
    if (title.isEmpty()) { setError("Informe um nome para o caderno."); return false; }
    if (!validNotebookId(id) || !QFileInfo::exists(databasePath(id))) { setError("Caderno não encontrado."); return false; }
    const auto rename = [&](QSqlDatabase& db) {
        QSqlQuery query(db);
        query.prepare("UPDATE notebook SET title = ?");
        query.addBindValue(title);
        if (!query.exec()) return false;
        refreshNotebook(id, db);
        return true;
    };
    bool saved = false;
    if (id == notebookId_) {
        QSqlDatabase db = activeDatabase();
        saved = rename(db);
    } else {
        saved = withDatabase<bool>(databasePath(id), false, rename);
    }
    if (!saved) { setError("Não foi possível renomear o caderno."); return false; }
    if (id == notebookId_) { notebookName_ = title; emit notebookChanged(); }
    setError({});
    return true;
}

bool NotebookStore::deleteNotebook(const QString& id) {
    if (!validNotebookId(id) || !QFileInfo::exists(databasePath(id))) { setError("Caderno não encontrado."); return false; }
    if (id == notebookId_) closeNotebook();
    const QString trash = QFileInfo(root_).absolutePath() + "/trash";
    const QString target = trash + "/" + id + "-" + QDateTime::currentDateTimeUtc().toString("yyyyMMddHHmmss");
    if (!QDir().mkpath(trash) || !QDir().rename(root_ + "/" + id, target)) {
        setError("Não foi possível mover o caderno para a lixeira.");
        return false;
    }
    for (int i = 0; i < notebooks_.size(); ++i)
        if (notebooks_[i].toMap().value("id").toString() == id) { notebooks_.removeAt(i); break; }
    setError({});
    emit notebooksChanged();
    return true;
}

bool NotebookStore::addSection(const QString& title) {
    if (notebookId_.isEmpty() || title.trimmed().isEmpty()) return false;
    const QString id = newId();
    QSqlQuery query(activeDatabase());
    query.prepare("INSERT INTO sections (id, title, color, position) VALUES (?, ?, ?, (SELECT COALESCE(MAX(position), -1) + 1 FROM sections))");
    query.addBindValue(id); query.addBindValue(title.trimmed()); query.addBindValue("#C58E61");
    if (!query.exec()) { setError("Não foi possível salvar a seção."); return false; }
    loadSections();
    emit sectionsChanged();
    return selectSection(id);
}

bool NotebookStore::renameSection(const QString& id, const QString& title) {
    if (!containsId(sections_, id) || title.trimmed().isEmpty()) return false;
    QSqlQuery query(activeDatabase());
    query.prepare("UPDATE sections SET title = ? WHERE id = ?");
    query.addBindValue(title.trimmed()); query.addBindValue(id);
    if (!query.exec()) { setError("Não foi possível renomear a seção."); return false; }
    loadSections();
    emit sectionsChanged();
    return true;
}

bool NotebookStore::setSectionColor(const QString& id, const QString& color) {
    if (!containsId(sections_, id) || !QRegularExpression("^#[0-9A-Fa-f]{6}$").match(color).hasMatch()) return false;
    QSqlQuery query(activeDatabase());
    query.prepare("UPDATE sections SET color = ? WHERE id = ?");
    query.addBindValue(color.toUpper()); query.addBindValue(id);
    if (!query.exec()) { setError("Não foi possível alterar a cor da seção."); return false; }
    loadSections();
    emit sectionsChanged();
    return true;
}

bool NotebookStore::deleteSection(const QString& id) {
    if (!containsId(sections_, id)) return false;
    const bool wasActive = sectionId_ == id;
    int oldIndex = 0;
    for (; oldIndex < sections_.size(); ++oldIndex)
        if (sections_[oldIndex].toMap().value("id").toString() == id) break;
    auto db = activeDatabase();
    if (!db.transaction()) { setError("Não foi possível excluir a seção."); return false; }
    QSqlQuery query(db);
    query.prepare("DELETE FROM pages WHERE section_id = ?");
    query.addBindValue(id);
    if (!query.exec()) { db.rollback(); setError("Não foi possível excluir a seção."); return false; }
    query.prepare("DELETE FROM sections WHERE id = ?");
    query.addBindValue(id);
    if (!query.exec() || !db.commit()) { db.rollback(); setError("Não foi possível excluir a seção."); return false; }
    loadSections();
    emit sectionsChanged();
    if (wasActive) {
        if (sections_.isEmpty()) {
            sectionId_.clear(); pageId_.clear(); pageTitle_.clear(); pages_.clear();
        } else {
            applySection(sections_[qMin(oldIndex, sections_.size() - 1)].toMap().value("id").toString());
        }
        rememberSelection();
        emit pagesChanged();
        emit selectionChanged();
    }
    return true;
}

bool NotebookStore::selectSection(const QString& id) {
    if (!containsId(sections_, id)) return false;
    emit aboutToChangeSelection();
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
    query.prepare("INSERT INTO pages (id, section_id, title, position) VALUES (?, ?, ?, (SELECT COALESCE(MAX(position), -1) + 1 FROM pages WHERE section_id = ?))");
    query.addBindValue(id); query.addBindValue(sectionId_); query.addBindValue(title.trimmed()); query.addBindValue(sectionId_);
    if (!query.exec()) { setError("Não foi possível salvar a página."); return false; }
    loadPages();
    emit pagesChanged();
    return selectPage(id);
}

bool NotebookStore::renamePage(const QString& id, const QString& title) {
    if (!containsId(pages_, id) || title.trimmed().isEmpty()) return false;
    QSqlQuery query(activeDatabase());
    query.prepare("UPDATE pages SET title = ? WHERE id = ?");
    query.addBindValue(title.trimmed()); query.addBindValue(id);
    if (!query.exec()) { setError("Não foi possível renomear a página."); return false; }
    loadPages();
    if (pageId_ == id) pageTitle_ = title.trimmed();
    emit pagesChanged();
    if (pageId_ == id) emit selectionChanged();
    return true;
}

bool NotebookStore::deletePage(const QString& id) {
    if (!containsId(pages_, id)) return false;
    const bool wasActive = pageId_ == id;
    int oldIndex = 0;
    for (; oldIndex < pages_.size(); ++oldIndex)
        if (pages_[oldIndex].toMap().value("id").toString() == id) break;
    QSqlQuery query(activeDatabase());
    query.prepare("DELETE FROM pages WHERE id = ?");
    query.addBindValue(id);
    if (!query.exec()) { setError("Não foi possível excluir a página."); return false; }
    loadPages();
    emit pagesChanged();
    if (wasActive) {
        pageId_.clear(); pageTitle_.clear();
        if (!pages_.isEmpty()) applyPage(pages_[qMin(oldIndex, pages_.size() - 1)].toMap().value("id").toString());
        rememberSelection();
        emit selectionChanged();
    }
    return true;
}

bool NotebookStore::selectPage(const QString& id) {
    if (containsId(pages_, id) && id != pageId_) emit aboutToChangeSelection();
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
