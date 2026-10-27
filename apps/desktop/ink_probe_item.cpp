#include "ink_probe_item.h"

#include <QLineF>
#include <QQuickWindow>
#include <QSGGeometry>
#include <QSGGeometryNode>
#include <QSGVertexColorMaterial>

#include <cmath>
#include <numbers>
#include <utility>

namespace {
constexpr float halfWidth = 1.6f;
// Joints sharper than this get a round cap so the outline has no notches.
constexpr float roundJoinAngle = 0.3f;
constexpr int capSegments = 12;
const QColor inkColor("#9B6336");

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
        auto* geometry = new QSGGeometry(QSGGeometry::defaultAttributes_ColoredPoint2D(), 0);
        geometry->setDrawingMode(QSGGeometry::DrawTriangles);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);
        node->setMaterial(new QSGVertexColorMaterial);
        node->setFlag(QSGNode::OwnsMaterial);
        return node;
    }
};

// Antialiased stroke mesh: an opaque core plus a `feather` wide fringe (one
// device pixel) whose alpha falls to zero, so edges stay smooth without MSAA.
class StrokeMesh {
public:
    explicit StrokeMesh(float feather) : feather_(feather) {}

    void addStroke(const QVector<QPointF>& stroke) {
        if (stroke.isEmpty()) return;
        addCap(stroke.front());
        for (int i = 1; i < stroke.size(); ++i) {
            addSegment(stroke[i - 1], stroke[i]);
            if (i + 1 < stroke.size() && turns(stroke[i - 1], stroke[i], stroke[i + 1])) addCap(stroke[i]);
        }
        if (stroke.size() > 1) addCap(stroke.back());
    }

    void writeTo(QSGGeometryNode* node) const {
        auto* geometry = node->geometry();
        geometry->allocate(static_cast<int>(vertices_.size()));
        std::copy(vertices_.cbegin(), vertices_.cend(), geometry->vertexDataAsColoredPoint2D());
        node->markDirty(QSGNode::DirtyGeometry);
    }

private:
    struct Vertex { float x, y, alpha; };

    static bool turns(const QPointF& a, const QPointF& b, const QPointF& c) {
        const QLineF first(a, b), second(b, c);
        if (first.length() < 0.001 || second.length() < 0.001) return false;
        const double angle = std::abs(first.angleTo(second));
        return std::min(angle, 360.0 - angle) * std::numbers::pi / 180.0 > roundJoinAngle;
    }

    void push(const Vertex& v) {
        QSGGeometry::ColoredPoint2D point;
        const auto a = static_cast<uchar>(std::lround(v.alpha * 255));
        // Premultiplied alpha, as QSGVertexColorMaterial expects.
        point.set(v.x, v.y, static_cast<uchar>(inkColor.red() * v.alpha), static_cast<uchar>(inkColor.green() * v.alpha),
                  static_cast<uchar>(inkColor.blue() * v.alpha), a);
        vertices_.append(point);
    }
    void quad(const Vertex& a, const Vertex& b, const Vertex& c, const Vertex& d) {
        push(a); push(b); push(c);
        push(c); push(b); push(d);
    }

    void addSegment(const QPointF& from, const QPointF& to) {
        const float dx = static_cast<float>(to.x() - from.x());
        const float dy = static_cast<float>(to.y() - from.y());
        const float length = std::hypot(dx, dy);
        if (length < 0.001f) return;
        const float nx = -dy / length, ny = dx / length;
        const float ax = static_cast<float>(from.x()), ay = static_cast<float>(from.y());
        const float bx = static_cast<float>(to.x()), by = static_cast<float>(to.y());
        const float core = halfWidth, outer = halfWidth + feather_;
        quad({ax + nx * core, ay + ny * core, 1}, {ax - nx * core, ay - ny * core, 1},
             {bx + nx * core, by + ny * core, 1}, {bx - nx * core, by - ny * core, 1});
        quad({ax + nx * outer, ay + ny * outer, 0}, {ax + nx * core, ay + ny * core, 1},
             {bx + nx * outer, by + ny * outer, 0}, {bx + nx * core, by + ny * core, 1});
        quad({ax - nx * core, ay - ny * core, 1}, {ax - nx * outer, ay - ny * outer, 0},
             {bx - nx * core, by - ny * core, 1}, {bx - nx * outer, by - ny * outer, 0});
    }

    void addCap(const QPointF& center) {
        const float cx = static_cast<float>(center.x()), cy = static_cast<float>(center.y());
        const float core = halfWidth, outer = halfWidth + feather_;
        for (int i = 0; i < capSegments; ++i) {
            const float a0 = 2 * std::numbers::pi_v<float> * i / capSegments;
            const float a1 = 2 * std::numbers::pi_v<float> * (i + 1) / capSegments;
            const float c0 = std::cos(a0), s0 = std::sin(a0), c1 = std::cos(a1), s1 = std::sin(a1);
            push({cx, cy, 1}); push({cx + c0 * core, cy + s0 * core, 1}); push({cx + c1 * core, cy + s1 * core, 1});
            quad({cx + c0 * outer, cy + s0 * outer, 0}, {cx + c0 * core, cy + s0 * core, 1},
                 {cx + c1 * outer, cy + s1 * outer, 0}, {cx + c1 * core, cy + s1 * core, 1});
        }
    }

    float feather_;
    QVector<QSGGeometry::ColoredPoint2D> vertices_;
};
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
    // One device pixel of feather, whatever the screen scale and page zoom.
    const qreal scale = mapRectToScene(QRectF(0, 0, 1, 1)).width() * (window() ? window()->effectiveDevicePixelRatio() : 1.0);
    const float feather = static_cast<float>(1.0 / std::max<qreal>(scale, 0.01));
    if (!qFuzzyCompare(feather, feather_)) {
        feather_ = feather;
        strokesDirty_ = activeDirty_ = true;
    }
    if (newNodes || strokesDirty_) {
        StrokeMesh mesh(feather_);
        for (const auto& stroke : strokes_) mesh.addStroke(stroke);
        mesh.writeTo(nodes->committed);
    }
    if (newNodes || activeDirty_) {
        StrokeMesh mesh(feather_);
        mesh.addStroke(active_);
        mesh.writeTo(nodes->active);
    }
    strokesDirty_ = false;
    activeDirty_ = false;
    return nodes;
}
