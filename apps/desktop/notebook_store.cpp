#include "notebook_store.h"

#include <QDir>
#include <QFileInfo>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QUuid>
#include <QVariantMap>

namespace {
template <typename T, typename F>
T withDatabase(const QString& path, T fallback, F action) {
    const QString connection = QUuid::createUuid().toString(QUuid::WithoutBraces);
    T result = fallback;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", connection);
        db.setDatabaseName(path);
        if (db.open()) {
            QSqlQuery foreignKeys(db);
            foreignKeys.exec("PRAGMA foreign_keys = ON");
            result = action(db);
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection);
    return result;
}

QString newId() { return QUuid::createUuid().toString(QUuid::WithoutBraces); }
}

NotebookStore::NotebookStore(QObject* parent) : QObject(parent) {
    root_ = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/notebooks";
    if (!QDir().mkpath(root_)) setError("Não foi possível criar a pasta de cadernos.");
}

QString NotebookStore::databasePath(const QString& id) const {
    return root_ + "/" + id + "/notebook.sqlite";
}

bool NotebookStore::validNotebookId(const QString& id) const {
    const QUuid uuid = QUuid::fromString(id);
    return !uuid.isNull() && uuid.toString(QUuid::WithoutBraces) == id;
}

void NotebookStore::setError(const QString& message) {
    if (error_ == message) return;
    error_ = message;
    emit errorChanged();
}

QVariantList NotebookStore::notebooks() const {
    QVariantList result;
    const auto folders = QDir(root_).entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    for (const QString& id : folders) {
        if (!validNotebookId(id) || !QFileInfo::exists(databasePath(id))) continue;
        const QVariantMap item = withDatabase<QVariantMap>(databasePath(id), {}, [&](QSqlDatabase& db) {
            QSqlQuery query(db);
            if (!query.exec("SELECT title FROM notebook LIMIT 1") || !query.next()) return QVariantMap{};
            QVariantMap value;
            value["id"] = id;
            value["title"] = query.value(0).toString();
            return value;
        });
        if (!item.isEmpty()) result.append(item);
    }
    return result;
}

QVariantList NotebookStore::sections() const {
    if (notebookId_.isEmpty()) return {};
    return withDatabase<QVariantList>(databasePath(notebookId_), {}, [](QSqlDatabase& db) {
        QVariantList rows;
        QSqlQuery query(db);
        if (!query.exec("SELECT id, title, color FROM sections ORDER BY position, id")) return rows;
        while (query.next()) rows.append(QVariantMap{{"id", query.value(0)}, {"title", query.value(1)}, {"color", query.value(2)}});
        return rows;
    });
}

QVariantList NotebookStore::pages() const {
    if (notebookId_.isEmpty() || sectionId_.isEmpty()) return {};
    return withDatabase<QVariantList>(databasePath(notebookId_), {}, [&](QSqlDatabase& db) {
        QVariantList rows;
        QSqlQuery query(db);
        query.prepare("SELECT id, title FROM pages WHERE section_id = ? ORDER BY position, id");
        query.addBindValue(sectionId_);
        if (!query.exec()) return rows;
        while (query.next()) rows.append(QVariantMap{{"id", query.value(0)}, {"title", query.value(1)}});
        return rows;
    });
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
    setError({});
    emit changed();
    return openNotebook(id);
}

bool NotebookStore::openNotebook(const QString& id) {
    if (!validNotebookId(id) || !QFileInfo::exists(databasePath(id))) { setError("Caderno não encontrado."); return false; }
    const QVariantMap data = withDatabase<QVariantMap>(databasePath(id), {}, [](QSqlDatabase& db) {
        QSqlQuery query(db);
        if (!query.exec("PRAGMA user_version") || !query.next() || query.value(0).toInt() != 1)
            return QVariantMap{};
        if (!query.exec("SELECT title, last_section, last_page FROM notebook LIMIT 1") || !query.next()) return QVariantMap{};
        return QVariantMap{{"title", query.value(0)}, {"section", query.value(1)}, {"page", query.value(2)}};
    });
    if (data.isEmpty()) { setError("Caderno inválido ou incompatível."); return false; }
    notebookId_ = id;
    notebookName_ = data.value("title").toString();
    sectionId_.clear(); pageId_.clear(); pageTitle_.clear();
    const auto availableSections = sections();
    QString wantedSection = data.value("section").toString();
    if (wantedSection.isEmpty() && !availableSections.isEmpty()) wantedSection = availableSections.first().toMap().value("id").toString();
    if (!wantedSection.isEmpty() && !selectSection(wantedSection) && !availableSections.isEmpty())
        selectSection(availableSections.first().toMap().value("id").toString());
    const QString wantedPage = data.value("page").toString();
    if (!wantedPage.isEmpty()) selectPage(wantedPage);
    setError({});
    emit changed();
    return true;
}

void NotebookStore::closeNotebook() {
    notebookId_.clear(); notebookName_.clear(); sectionId_.clear(); pageId_.clear(); pageTitle_.clear();
    setError({});
    emit changed();
}

bool NotebookStore::addSection(const QString& title) {
    if (notebookId_.isEmpty() || title.trimmed().isEmpty()) return false;
    const QString id = newId();
    const bool saved = withDatabase<bool>(databasePath(notebookId_), false, [&](QSqlDatabase& db) {
        QSqlQuery query(db);
        query.prepare("INSERT INTO sections (id, title, color, position) VALUES (?, ?, ?, (SELECT COUNT(*) FROM sections))");
        query.addBindValue(id); query.addBindValue(title.trimmed()); query.addBindValue("#C58E61");
        return query.exec();
    });
    if (!saved) { setError("Não foi possível salvar a seção."); return false; }
    return selectSection(id);
}

bool NotebookStore::selectSection(const QString& id) {
    const auto list = sections();
    bool found = false;
    for (const QVariant& item : list) if (item.toMap().value("id") == id) found = true;
    if (!found) return false;
    sectionId_ = id; pageId_.clear(); pageTitle_.clear();
    const auto availablePages = pages();
    if (!availablePages.isEmpty()) {
        pageId_ = availablePages.first().toMap().value("id").toString();
        pageTitle_ = availablePages.first().toMap().value("title").toString();
    }
    rememberSelection();
    emit changed();
    return true;
}

bool NotebookStore::addPage(const QString& title) {
    if (notebookId_.isEmpty() || sectionId_.isEmpty() || title.trimmed().isEmpty()) return false;
    const QString id = newId();
    const bool saved = withDatabase<bool>(databasePath(notebookId_), false, [&](QSqlDatabase& db) {
        QSqlQuery query(db);
        query.prepare("INSERT INTO pages (id, section_id, title, position) VALUES (?, ?, ?, (SELECT COUNT(*) FROM pages WHERE section_id = ?))");
        query.addBindValue(id); query.addBindValue(sectionId_); query.addBindValue(title.trimmed()); query.addBindValue(sectionId_);
        return query.exec();
    });
    if (!saved) { setError("Não foi possível salvar a página."); return false; }
    return selectPage(id);
}

bool NotebookStore::selectPage(const QString& id) {
    for (const QVariant& item : pages()) {
        const auto page = item.toMap();
        if (page.value("id") == id) {
            pageId_ = id;
            pageTitle_ = page.value("title").toString();
            rememberSelection();
            emit changed();
            return true;
        }
    }
    return false;
}

void NotebookStore::rememberSelection() {
    if (notebookId_.isEmpty()) return;
    const bool saved = withDatabase<bool>(databasePath(notebookId_), false, [&](QSqlDatabase& db) {
        QSqlQuery query(db);
        query.prepare("UPDATE notebook SET last_section = ?, last_page = ?");
        query.addBindValue(sectionId_); query.addBindValue(pageId_);
        return query.exec();
    });
    if (!saved) setError("Não foi possível guardar a última página visitada.");
}
