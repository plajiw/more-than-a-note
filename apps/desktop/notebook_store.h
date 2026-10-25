#pragma once

#include <QObject>
#include <QSqlDatabase>
#include <QVariantList>

// Lists are cached in memory and reloaded only when they change, so QML
// bindings never touch the disk. The active notebook keeps one SQLite
// connection open until it is closed.
class NotebookStore final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList notebooks READ notebooks NOTIFY notebooksChanged)
    Q_PROPERTY(QVariantList sections READ sections NOTIFY sectionsChanged)
    Q_PROPERTY(QVariantList pages READ pages NOTIFY pagesChanged)
    Q_PROPERTY(QString activeNotebookId READ activeNotebookId NOTIFY notebookChanged)
    Q_PROPERTY(QString activeNotebookName READ activeNotebookName NOTIFY notebookChanged)
    Q_PROPERTY(QString activeSectionId READ activeSectionId NOTIFY selectionChanged)
    Q_PROPERTY(QString activePageId READ activePageId NOTIFY selectionChanged)
    Q_PROPERTY(QString activePageTitle READ activePageTitle NOTIFY selectionChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    explicit NotebookStore(QObject* parent = nullptr);
    ~NotebookStore() override;

    QVariantList notebooks() const;
    QVariantList sections() const { return sections_; }
    QVariantList pages() const { return pages_; }
    QString activeNotebookId() const { return notebookId_; }
    QString activeNotebookName() const { return notebookName_; }
    QString activeSectionId() const { return sectionId_; }
    QString activePageId() const { return pageId_; }
    QString activePageTitle() const { return pageTitle_; }
    QString error() const { return error_; }

    Q_INVOKABLE bool createNotebook(const QString& name);
    Q_INVOKABLE bool openNotebook(const QString& id);
    Q_INVOKABLE void closeNotebook();
    Q_INVOKABLE bool addSection(const QString& title);
    Q_INVOKABLE bool renameSection(const QString& id, const QString& title);
    Q_INVOKABLE bool setSectionColor(const QString& id, const QString& color);
    Q_INVOKABLE bool deleteSection(const QString& id);
    Q_INVOKABLE bool selectSection(const QString& id);
    Q_INVOKABLE bool addPage(const QString& title);
    Q_INVOKABLE bool renamePage(const QString& id, const QString& title);
    Q_INVOKABLE bool deletePage(const QString& id);
    Q_INVOKABLE bool selectPage(const QString& id);

signals:
    void notebooksChanged();
    void sectionsChanged();
    void pagesChanged();
    void notebookChanged();
    void selectionChanged();
    void errorChanged();

private:
    friend class PageEditorAdapter;
    QString root_;
    QString connection_;
    QString notebookId_;
    QString notebookName_;
    QString sectionId_;
    QString pageId_;
    QString pageTitle_;
    QString error_;
    mutable QVariantList notebooks_;
    mutable bool notebooksLoaded_ = false;
    QVariantList sections_;
    QVariantList pages_;

    QString databasePath(const QString& id) const;
    bool validNotebookId(const QString& id) const;
    QSqlDatabase activeDatabase() const;
    void closeConnection();
    void loadSections();
    void loadPages();
    void applySection(const QString& id);
    bool applyPage(const QString& id);
    void setError(const QString& message);
    void rememberSelection();
};
