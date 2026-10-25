#include "ink_probe_item.h"

#include <QLineF>
#include <QSGFlatColorMaterial>
#include <QSGGeometry>
#include <QSGGeometryNode>

#include <cmath>
#include <utility>

namespace {
constexpr float halfWidth = 1.6f;

class InkNodes final : public QSGNode {
public:
    InkNodes() {
        committed = makeNode();
        active = makeNode();
        appendChildNode(committed);
        appendChildNode(active);
    }

    QSGGeometryNode* committed = nullptr;
    QSGGeometryNode* active = nullptr;

private:
    static QSGGeometryNode* makeNode() {
        auto* node = new QSGGeometryNode;
        auto* geometry = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), 0);
        geometry->setDrawingMode(QSGGeometry::DrawTriangles);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);
        auto* material = new QSGFlatColorMaterial;
        material->setColor(QColor("#9B6336"));
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
        return node;
    }
};

void writeSegment(QSGGeometry::Point2D* vertices, const QPointF& a, const QPointF& b) {
    const float dx = static_cast<float>(b.x() - a.x());
    const float dy = static_cast<float>(b.y() - a.y());
    const float length = std::hypot(dx, dy);
    const float ax = static_cast<float>(a.x());
    const float ay = static_cast<float>(a.y());
    if (length < 0.001f) {
        vertices[0].set(ax - halfWidth, ay - halfWidth);
        vertices[1].set(ax + halfWidth, ay - halfWidth);
        vertices[2].set(ax - halfWidth, ay + halfWidth);
        vertices[3].set(ax - halfWidth, ay + halfWidth);
        vertices[4].set(ax + halfWidth, ay - halfWidth);
        vertices[5].set(ax + halfWidth, ay + halfWidth);
        return;
    }
    const float nx = -dy / length * halfWidth;
    const float ny = dx / length * halfWidth;
    const float bx = static_cast<float>(b.x());
    const float by = static_cast<float>(b.y());
    vertices[0].set(ax + nx, ay + ny);
    vertices[1].set(ax - nx, ay - ny);
    vertices[2].set(bx + nx, by + ny);
    vertices[3].set(bx + nx, by + ny);
    vertices[4].set(ax - nx, ay - ny);
    vertices[5].set(bx - nx, by - ny);
}

void fillGeometry(QSGGeometryNode* node, const QVector<QVector<QPointF>>& strokes) {
    int segments = 0;
    for (const auto& stroke : strokes)
        if (!stroke.isEmpty()) segments += static_cast<int>(stroke.size() == 1 ? 1 : stroke.size() - 1);
    auto* geometry = node->geometry();
    geometry->allocate(segments * 6);
    auto* vertices = geometry->vertexDataAsPoint2D();
    int offset = 0;
    for (const auto& stroke : strokes) {
        if (stroke.size() == 1) {
            writeSegment(vertices + offset, stroke.front(), stroke.front());
            offset += 6;
        } else {
            for (int i = 1; i < stroke.size(); ++i) {
                writeSegment(vertices + offset, stroke[i - 1], stroke[i]);
                offset += 6;
            }
        }
    }
    node->markDirty(QSGNode::DirtyGeometry);
}

void fillGeometry(QSGGeometryNode* node, const QVector<QPointF>& stroke) {
    const int segments = stroke.isEmpty() ? 0 : static_cast<int>(stroke.size() == 1 ? 1 : stroke.size() - 1);
    auto* geometry = node->geometry();
    geometry->allocate(segments * 6);
    auto* vertices = geometry->vertexDataAsPoint2D();
    if (stroke.size() == 1) writeSegment(vertices, stroke.front(), stroke.front());
    else for (int i = 1; i < stroke.size(); ++i)
        writeSegment(vertices + (i - 1) * 6, stroke[i - 1], stroke[i]);
    node->markDirty(QSGNode::DirtyGeometry);
}
} // namespace

InkProbeItem::InkProbeItem(QQuickItem* parent) : QQuickItem(parent) {
    setFlag(ItemHasContents);
}

bool InkProbeItem::beginStroke(qreal x, qreal y) {
    if (!std::isfinite(x) || !std::isfinite(y) || !active_.isEmpty() ||
        committedPoints_ >= maxPoints) return false;
    active_.append({x, y});
    activeDirty_ = true;
    update();
    return true;
}

bool InkProbeItem::appendPoint(qreal x, qreal y) {
    if (!std::isfinite(x) || !std::isfinite(y) || active_.isEmpty() ||
        committedPoints_ + active_.size() >= maxPoints) return false;
    const QPointF next{x, y};
    if (QLineF(active_.back(), next).length() < 0.75) return true;
    active_.append(next);
    activeDirty_ = true;
    update();
    return true;
}

bool InkProbeItem::endStroke() {
    if (active_.isEmpty()) return false;
    committedPoints_ += static_cast<int>(active_.size());
    strokes_.append(std::move(active_));
    active_.clear();
    strokesDirty_ = true;
    activeDirty_ = true;
    update();
    emit strokeCountChanged();
    emit pointCountChanged();
    QVariantList points;
    points.reserve(strokes_.back().size());
    for (const QPointF& point : strokes_.back()) points.append(point);
    emit strokeFinished(points);
    return true;
}

void InkProbeItem::cancelStroke() {
    if (active_.isEmpty()) return;
    active_.clear();
    activeDirty_ = true;
    update();
}

void InkProbeItem::clear() {
    if (strokes_.isEmpty() && active_.isEmpty()) return;
    strokes_.clear();
    active_.clear();
    committedPoints_ = 0;
    strokesDirty_ = true;
    activeDirty_ = true;
    update();
    emit strokeCountChanged();
    emit pointCountChanged();
}

bool InkProbeItem::loadStrokes(const QVariantList& strokes) {
    QVector<QVector<QPointF>> loaded;
    int count = 0;
    loaded.reserve(strokes.size());
    for (const QVariant& entry : strokes) {
        const QVariantList points = entry.toList();
        if (points.isEmpty() || points.size() > maxPoints - count) return false;
        QVector<QPointF> stroke;
        stroke.reserve(points.size());
        for (const QVariant& value : points) {
            if (!value.canConvert<QPointF>()) return false;
            const QPointF point = value.toPointF();
            if (!std::isfinite(point.x()) || !std::isfinite(point.y())) return false;
            stroke.append(point);
        }
        count += static_cast<int>(stroke.size());
        loaded.append(std::move(stroke));
    }
    strokes_ = std::move(loaded);
    active_.clear();
    committedPoints_ = count;
    strokesDirty_ = true;
    activeDirty_ = true;
    update();
    emit strokeCountChanged();
    emit pointCountChanged();
    return true;
}

QSGNode* InkProbeItem::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData*) {
    auto* nodes = static_cast<InkNodes*>(oldNode);
    const bool newNodes = !nodes;
    if (newNodes) nodes = new InkNodes;
    if (newNodes || strokesDirty_) fillGeometry(nodes->committed, strokes_);
    if (newNodes || activeDirty_) fillGeometry(nodes->active, active_);
    strokesDirty_ = false;
    activeDirty_ = false;
    return nodes;
}
