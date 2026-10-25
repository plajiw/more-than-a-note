#pragma once

#include <QPointF>
#include <QQuickItem>
#include <QVariantList>
#include <QVector>
#include <QtQml/qqmlregistration.h>

class InkProbeItem : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int strokeCount READ strokeCount NOTIFY strokeCountChanged)
    Q_PROPERTY(int pointCount READ pointCount NOTIFY pointCountChanged)

public:
    explicit InkProbeItem(QQuickItem* parent = nullptr);

    int strokeCount() const noexcept { return static_cast<int>(strokes_.size()); }
    int pointCount() const noexcept { return committedPoints_; }

    Q_INVOKABLE bool beginStroke(qreal x, qreal y);
    Q_INVOKABLE bool appendPoint(qreal x, qreal y);
    Q_INVOKABLE bool endStroke();
    Q_INVOKABLE void cancelStroke();
    Q_INVOKABLE void clear();
    Q_INVOKABLE bool loadStrokes(const QVariantList& strokes);

signals:
    void strokeCountChanged();
    void pointCountChanged();
    void strokeFinished(const QVariantList& points);

protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData*) override;

private:
    static constexpr int maxPoints = 50'000;
    QVector<QVector<QPointF>> strokes_;
    QVector<QPointF> active_;
    int committedPoints_ = 0;
    bool strokesDirty_ = true;
    bool activeDirty_ = true;
};
