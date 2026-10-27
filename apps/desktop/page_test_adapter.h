#pragma once

#include "page_history.h"

#include <QObject>
#include <QVariantList>

#include <memory>

class NotebookStore;

// Temporary E3.5 bridge. One selected page owns one in-memory PageSession;
// changing pages or leaving demo mode releases it. No SQLite writes occur.
class PageTestAdapter final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool demoEnabled READ demoEnabled WRITE setDemoEnabled NOTIFY stateChanged)
    Q_PROPERTY(QString pageId READ pageId NOTIFY stateChanged)
    Q_PROPERTY(QVariantList objects READ objects NOTIFY stateChanged)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY stateChanged)
    Q_PROPERTY(bool canRedo READ canRedo NOTIFY stateChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    explicit PageTestAdapter(NotebookStore* store, QObject* parent = nullptr);

    bool demoEnabled() const noexcept { return demoEnabled_; }
    void setDemoEnabled(bool enabled);
    QString pageId() const { return pageId_; }
    QVariantList objects() const { return objects_; }
    bool canUndo() const noexcept { return session_ && session_->undo_depth() != 0; }
    bool canRedo() const noexcept { return session_ && session_->redo_depth() != 0; }
    QString error() const { return error_; }

    Q_INVOKABLE bool createTextAt(double xPt, double yPt, const QString& text);
    Q_INVOKABLE bool moveObject(const QString& id, double xPt, double yPt);
    Q_INVOKABLE bool undo();
    Q_INVOKABLE bool redo();

signals:
    void stateChanged();
    void errorChanged();

private:
    NotebookStore* store_;
    bool demoEnabled_ = false;
    QString pageId_;
    QVariantList objects_;
    QString error_;
    std::unique_ptr<mtn::model::PageSession> session_;

    void syncSelection();
    void refresh();
    void setError(const QString& message);
    bool applied(mtn::model::HistoryResult result);
};
