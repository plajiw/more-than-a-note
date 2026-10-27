#pragma once

#include "page_history.h"
#include "text_card_model.h"

#include <QElapsedTimer>
#include <QHash>
#include <QObject>
#include <QVariantList>

#include <memory>
#include <vector>

class NotebookStore;

// E4 editor slice: independently identified text cards and mouse ink.
// PageSession owns the authoritative content. Every completed command is
// persisted, in one transaction, before success is reported to QML. Text,
// formatting, geometry and ink share one history per page; recently visited
// pages keep theirs.
class PageEditorAdapter final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool demoEnabled READ demoEnabled NOTIFY stateChanged)
    Q_PROPERTY(QString pageId READ pageId NOTIFY stateChanged)
    Q_PROPERTY(QVariantList textCards READ textCards NOTIFY stateChanged)
    Q_PROPERTY(QObject* textCardModel READ textCardModel CONSTANT)
    Q_PROPERTY(QString undoLabel READ undoLabel NOTIFY stateChanged)
    Q_PROPERTY(QString redoLabel READ redoLabel NOTIFY stateChanged)
    Q_PROPERTY(QVariantList inkStrokes READ inkStrokes NOTIFY stateChanged)
    Q_PROPERTY(int inkCount READ inkCount NOTIFY stateChanged)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY stateChanged)
    Q_PROPERTY(bool canRedo READ canRedo NOTIFY stateChanged)
    Q_PROPERTY(QString error READ error NOTIFY stateChanged)
    Q_PROPERTY(bool infiniteCanvas READ infiniteCanvas NOTIFY stateChanged)

public:
    explicit PageEditorAdapter(NotebookStore* store, QObject* parent = nullptr);

    bool demoEnabled() const noexcept { return enabled_ && session_ != nullptr; }
    Q_INVOKABLE void setEnabled(bool enabled);
    QString pageId() const { return pageId_; }
    QVariantList textCards() const { return textCards_; }
    QObject* textCardModel() { return &textCardModel_; }
    QString undoLabel() const;
    QString redoLabel() const;
    QVariantList inkStrokes() const { return inkStrokes_; }
    int inkCount() const noexcept { return inkCount_; }
    bool canUndo() const noexcept { return session_ && session_->undo_depth() > 0; }
    bool canRedo() const noexcept { return session_ && session_->redo_depth() > 0; }
    QString error() const { return error_; }
    bool infiniteCanvas() const noexcept { return infiniteCanvas_; }
    Q_INVOKABLE bool setInfiniteCanvas(bool infinite);

    Q_INVOKABLE QString createTextAt(double xPt, double yPt);
    Q_INVOKABLE bool saveText(const QString& id, const QString& text);
    Q_INVOKABLE bool loadRichText(const QString& id, QObject* quickDocument);
    // Selections are opaque strings restored by undo/redo ("caret:a:b").
    Q_INVOKABLE bool saveRichText(const QString& id, QObject* quickDocument,
                                  const QString& selectionBefore = {},
                                  const QString& selectionAfter = {},
                                  const QString& kind = QStringLiteral("typing"));
    Q_INVOKABLE bool saveRichTextDocuments(const QVariantList& entries);
    Q_INVOKABLE QVariantMap richFormatAt(QObject* quickDocument, int position) const;
    Q_INVOKABLE bool applyRichBlockFormat(QObject* quickDocument, int start, int end,
                                          const QString& kind, const QString& value = {});
    // `coalesce` folds repeated nudges of the same card within a second into
    // one history entry; pointer gestures are always their own entry.
    Q_INVOKABLE bool moveText(const QString& id, double xPt, double yPt, bool coalesce = false);
    Q_INVOKABLE bool resizeText(const QString& id, double widthPt, bool coalesce = false);
    Q_INVOKABLE QString duplicateText(const QString& id);
    Q_INVOKABLE bool deleteText(const QString& id);
    Q_INVOKABLE bool discardEmptyText(const QString& id);
    Q_INVOKABLE bool addInk(const QVariantList& points);
    Q_INVOKABLE bool undo();
    Q_INVOKABLE bool redo();

signals:
    void stateChanged();
    void pageLoaded();
    // Asks editors to commit pending input now (before undo, redo, navigation).
    void flushRequested();
    // After undo/redo: the object to select ("" if it no longer exists) and
    // the selection stored with the entry.
    void historyApplied(const QString& objectId, const QString& selection, bool undone);

private:
    NotebookStore* store_;
    bool enabled_ = false;
    QString pageId_;
    QVariantList textCards_;
    QVariantList inkStrokes_;
    int inkCount_ = 0;
    QString error_;
    bool infiniteCanvas_ = false;
    std::unique_ptr<mtn::model::PageSession> session_;
    struct CachedSession {
        QString pageId;
        std::unique_ptr<mtn::model::PageSession> session;
    };
    std::vector<CachedSession> recentSessions_;
    TextCardModel textCardModel_;
    QHash<QString, int> revisions_;
    QString mergeKey_;
    QElapsedTimer mergeClock_;

    void syncSelection();
    void rebuildVisual();
    void setError(const QString& message);
    void dropSessionAfterFailure(const QString& message);
    bool commit(mtn::model::PageCommand command, const QString& mergeKey = {});
    bool persist(const mtn::model::PageCommand& command);
    bool applyHistory(bool undo);
};
