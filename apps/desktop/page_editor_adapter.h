#pragma once

#include "page_history.h"

#include <QObject>
#include <QVariantList>

#include <memory>
#include <vector>

class NotebookStore;

// E4 vertical slice: two fixed text slots and mouse ink on the selected page.
// PageSession owns the authoritative content. Every completed command is
// persisted before success is reported to QML.
class PageEditorAdapter final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool demoEnabled READ demoEnabled NOTIFY stateChanged)
    Q_PROPERTY(QString pageId READ pageId NOTIFY stateChanged)
    Q_PROPERTY(QString text1 READ text1 NOTIFY stateChanged)
    Q_PROPERTY(QString text2 READ text2 NOTIFY stateChanged)
    Q_PROPERTY(QVariantList inkStrokes READ inkStrokes NOTIFY stateChanged)
    Q_PROPERTY(int inkCount READ inkCount NOTIFY stateChanged)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY stateChanged)
    Q_PROPERTY(bool canRedo READ canRedo NOTIFY stateChanged)
    Q_PROPERTY(QString error READ error NOTIFY stateChanged)

public:
    explicit PageEditorAdapter(NotebookStore* store, QObject* parent = nullptr);

    bool demoEnabled() const noexcept { return enabled_ && session_ != nullptr; }
    Q_INVOKABLE void setEnabled(bool enabled);
    QString pageId() const { return pageId_; }
    QString text1() const { return text_[0]; }
    QString text2() const { return text_[1]; }
    QVariantList inkStrokes() const { return inkStrokes_; }
    int inkCount() const noexcept { return inkCount_; }
    bool canUndo() const noexcept { return session_ && session_->undo_depth() > 0; }
    bool canRedo() const noexcept { return session_ && session_->redo_depth() > 0; }
    QString error() const { return error_; }

    Q_INVOKABLE bool saveText(int slot, const QString& text);
    Q_INVOKABLE bool addInk(const QVariantList& points);
    Q_INVOKABLE bool undo();
    Q_INVOKABLE bool redo();

signals:
    void stateChanged();
    void pageLoaded();

private:
    NotebookStore* store_;
    bool enabled_ = false;
    QString pageId_;
    QString text_[2];
    QVariantList inkStrokes_;
    int inkCount_ = 0;
    QString error_;
    std::unique_ptr<mtn::model::PageSession> session_;
    std::vector<std::string> undoIds_;
    std::vector<std::string> redoIds_;

    void syncSelection();
    void rebuildVisual();
    void setError(const QString& message);
    bool commit(mtn::model::PageCommand command, const std::string& objectId);
    bool persist(const std::string& objectId);
};
