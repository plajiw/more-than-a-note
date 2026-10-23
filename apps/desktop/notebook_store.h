#pragma once

#include <QObject>
#include <QVariantList>

class NotebookStore final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList notebooks READ notebooks NOTIFY changed)
    Q_PROPERTY(QVariantList sections READ sections NOTIFY changed)
    Q_PROPERTY(QVariantList pages READ pages NOTIFY changed)
    Q_PROPERTY(QString activeNotebookId READ activeNotebookId NOTIFY changed)
    Q_PROPERTY(QString activeNotebookName READ activeNotebookName NOTIFY changed)
    Q_PROPERTY(QString activeSectionId READ activeSectionId NOTIFY changed)
    Q_PROPERTY(QString activePageId READ activePageId NOTIFY changed)
    Q_PROPERTY(QString activePageTitle READ activePageTitle NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    explicit NotebookStore(QObject* parent = nullptr);
    QVariantList notebooks() const;
    QVariantList sections() const;
    QVariantList pages() const;
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
    Q_INVOKABLE bool selectSection(const QString& id);
    Q_INVOKABLE bool addPage(const QString& title);
    Q_INVOKABLE bool selectPage(const QString& id);

signals:
    void changed();
    void errorChanged();

private:
    QString root_;
    QString notebookId_;
    QString notebookName_;
    QString sectionId_;
    QString pageId_;
    QString pageTitle_;
    QString error_;

    QString databasePath(const QString& id) const;
    bool validNotebookId(const QString& id) const;
    void setError(const QString& message);
    void rememberSelection();
};
