#include "page_content.h"

#include <algorithm>
#include <cmath>
#include <numbers>
#include <type_traits>
#include <unordered_map>
#include <unordered_set>

namespace mtn::model {
namespace {

bool finite(PagePoint point) noexcept {
    return std::isfinite(point.x) && std::isfinite(point.y);
}

bool valid_transform(const PageTransform& transform) noexcept {
    return finite(transform.translation) && std::isfinite(transform.rotation_degrees) &&
           std::isfinite(transform.scale_x) && std::isfinite(transform.scale_y) &&
           transform.scale_x != 0 && transform.scale_y != 0;
}

bool identity(const PageTransform& transform) noexcept {
    return transform.translation.x == 0 && transform.translation.y == 0 &&
           transform.rotation_degrees == 0 && transform.scale_x == 1 &&
           transform.scale_y == 1;
}

bool positive(double value) noexcept { return std::isfinite(value) && value > 0; }

bool valid_port(AnchorPort port) noexcept {
    switch (port) {
    case AnchorPort::Center:
    case AnchorPort::Top:
    case AnchorPort::Right:
    case AnchorPort::Bottom:
    case AnchorPort::Left:
        return true;
    }
    return false;
}

bool valid_shape(ShapeKind shape) noexcept {
    switch (shape) {
    case ShapeKind::Rectangle:
    case ShapeKind::Ellipse:
    case ShapeKind::Line:
    case ShapeKind::Arrow:
        return true;
    }
    return false;
}

bool connectable(PageObjectKind object_kind) noexcept {
    return object_kind == PageObjectKind::Text || object_kind == PageObjectKind::Image ||
           object_kind == PageObjectKind::GraphicAsset || object_kind == PageObjectKind::Shape;
}

template <typename Order>
std::vector<const PageObject*> sorted(const PageContent& page, Order order) {
    std::vector<const PageObject*> result;
    result.reserve(page.objects.size());
    for (const auto& object : page.objects) result.push_back(&object);
    std::sort(result.begin(), result.end(), [&](const auto* left, const auto* right) {
        const auto a = order(left->common);
        const auto b = order(right->common);
        return a == b ? left->common.id < right->common.id : a < b;
    });
    return result;
}

} // namespace

bool valid_uuid(std::string_view id) noexcept {
    if (id.size() != 36) return false;
    bool nonzero = false;
    for (std::size_t i = 0; i < id.size(); ++i) {
        if (i == 8 || i == 13 || i == 18 || i == 23) {
            if (id[i] != '-') return false;
            continue;
        }
        const char c = id[i];
        if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))) return false;
        if (c != '0') nonzero = true;
    }
    return nonzero;
}

bool valid_ink_stroke(const InkStroke& stroke) noexcept {
    if (!positive(stroke.base_width_pt) || stroke.points.empty() ||
        stroke.points.size() > 250'000 ||
        (stroke.brush != InkBrush::Pen && stroke.brush != InkBrush::Highlighter) ||
        !valid_rgba_color(stroke.color)) return false;
    double last_time = 0;
    for (const auto& point : stroke.points) {
        if (!finite(point.position)) return false;
        if (point.pressure && (!std::isfinite(*point.pressure) ||
                               *point.pressure < 0 || *point.pressure > 1)) return false;
        if (point.relative_time_ms) {
            if (!std::isfinite(*point.relative_time_ms) ||
                *point.relative_time_ms < last_time) return false;
            last_time = *point.relative_time_ms;
        }
        for (const auto* tilt : {&point.tilt_x, &point.tilt_y})
            if (*tilt && (!std::isfinite(**tilt) || **tilt < -90 || **tilt > 90))
                return false;
    }
    return true;
}

PageObjectKind kind(const PageObject& object) {
    return std::visit([](const auto& payload) noexcept {
        using T = std::decay_t<decltype(payload)>;
        if constexpr (std::is_same_v<T, TextContainer>) return PageObjectKind::Text;
        else if constexpr (std::is_same_v<T, InkStroke>) return PageObjectKind::Ink;
        else if constexpr (std::is_same_v<T, ImageObject>) return PageObjectKind::Image;
        else if constexpr (std::is_same_v<T, GraphicAssetObject>) return PageObjectKind::GraphicAsset;
        else if constexpr (std::is_same_v<T, ShapeObject>) return PageObjectKind::Shape;
        else if constexpr (std::is_same_v<T, ConnectorObject>) return PageObjectKind::Connector;
        else return PageObjectKind::Group;
    }, object.payload);
}

std::optional<PagePoint> to_page(const PageTransform& transform, PagePoint local) noexcept {
    if (!valid_transform(transform) || !finite(local)) return std::nullopt;
    const double angle = transform.rotation_degrees * std::numbers::pi / 180.0;
    const double c = std::cos(angle);
    const double s = std::sin(angle);
    const double x = local.x * transform.scale_x;
    const double y = local.y * transform.scale_y;
    PagePoint result{transform.translation.x + x * c - y * s,
                     transform.translation.y + x * s + y * c};
    return finite(result) ? std::optional<PagePoint>(result) : std::nullopt;
}

std::optional<PagePoint> from_page(const PageTransform& transform, PagePoint page) noexcept {
    if (!valid_transform(transform) || !finite(page)) return std::nullopt;
    const double angle = transform.rotation_degrees * std::numbers::pi / 180.0;
    const double c = std::cos(angle);
    const double s = std::sin(angle);
    const double x = page.x - transform.translation.x;
    const double y = page.y - transform.translation.y;
    PagePoint result{(x * c + y * s) / transform.scale_x,
                     (-x * s + y * c) / transform.scale_y};
    return finite(result) ? std::optional<PagePoint>(result) : std::nullopt;
}

std::vector<PageValidationIssue> validate_page(const PageContent& page) {
    std::vector<PageValidationIssue> issues;
    const auto add = [&](PageValidationCode code, const std::string& id) {
        issues.push_back({code, id});
    };
    if (!valid_uuid(page.page_id)) add(PageValidationCode::InvalidPageId, page.page_id);

    std::unordered_map<std::string, const PageObject*> by_id;
    by_id.reserve(page.objects.size());
    for (const auto& object : page.objects) {
        const auto& common = object.common;
        if (!valid_uuid(common.id)) add(PageValidationCode::InvalidObjectId, common.id);
        if (!by_id.emplace(common.id, &object).second)
            add(PageValidationCode::DuplicateObjectId, common.id);
        if (common.page_id != page.page_id) add(PageValidationCode::WrongPage, common.id);
        if (!valid_transform(common.transform)) add(PageValidationCode::InvalidTransform, common.id);
        const auto object_kind = kind(object);
        if ((object_kind == PageObjectKind::Text || object_kind == PageObjectKind::Ink) &&
            (common.transform.rotation_degrees != 0 || common.transform.scale_x != 1 ||
             common.transform.scale_y != 1))
            add(PageValidationCode::InvalidTransform, common.id);
        if (object_kind == PageObjectKind::Connector && !identity(common.transform))
            add(PageValidationCode::InvalidTransform, common.id);

        std::visit([&](const auto& payload) {
            using T = std::decay_t<decltype(payload)>;
            if constexpr (std::is_same_v<T, TextContainer>) {
                if (!positive(payload.width_pt) || !positive(payload.max_width_pt))
                    add(PageValidationCode::InvalidGeometry, common.id);
                if (validate_rich_text(payload.document) != TextValidation::Valid)
                    add(PageValidationCode::InvalidText, common.id);
            } else if constexpr (std::is_same_v<T, InkStroke>) {
                if (!valid_ink_stroke(payload)) add(PageValidationCode::InvalidInk, common.id);
            } else if constexpr (std::is_same_v<T, ImageObject> ||
                                 std::is_same_v<T, GraphicAssetObject>) {
                if (!valid_uuid(payload.asset_id))
                    add(PageValidationCode::InvalidAssetId, common.id);
                if (!positive(payload.width_pt) || !positive(payload.height_pt))
                    add(PageValidationCode::InvalidGeometry, common.id);
            } else if constexpr (std::is_same_v<T, ShapeObject>) {
                if (!valid_shape(payload.shape) || !std::isfinite(payload.width_pt) ||
                    !std::isfinite(payload.height_pt) || payload.width_pt < 0 ||
                    payload.height_pt < 0 ||
                    ((payload.shape == ShapeKind::Rectangle || payload.shape == ShapeKind::Ellipse)
                         ? (payload.width_pt == 0 || payload.height_pt == 0)
                         : (payload.width_pt == 0 && payload.height_pt == 0)))
                    add(PageValidationCode::InvalidGeometry, common.id);
            } else if constexpr (std::is_same_v<T, ConnectorObject>) {
                if (!finite(payload.start.fallback) || !finite(payload.end.fallback))
                    add(PageValidationCode::InvalidGeometry, common.id);
            } else if constexpr (std::is_same_v<T, GroupObject>) {
                if (payload.child_ids.empty() || common.group_id || !identity(common.transform))
                    add(PageValidationCode::InvalidGroup, common.id);
            }
        }, object.payload);
    }

    std::unordered_map<std::string, std::string> owner;
    for (const auto& object : page.objects) {
        const auto& id = object.common.id;
        if (const auto* group = std::get_if<GroupObject>(&object.payload)) {
            std::unordered_set<std::string> children;
            for (const auto& child_id : group->child_ids) {
                if (!children.insert(child_id).second) add(PageValidationCode::InvalidGroup, id);
                const auto child = by_id.find(child_id);
                if (child == by_id.end() || child_id == id ||
                    kind(*child->second) == PageObjectKind::Group) {
                    add(PageValidationCode::InvalidGroup, id);
                    continue;
                }
                if (!owner.emplace(child_id, id).second ||
                    child->second->common.group_id != id)
                    add(PageValidationCode::InvalidGroup, id);
            }
        }
    }
    for (const auto& object : page.objects) {
        const auto& id = object.common.id;
        if (object.common.group_id) {
            const auto group = by_id.find(*object.common.group_id);
            if (group == by_id.end() || kind(*group->second) != PageObjectKind::Group ||
                owner.find(id) == owner.end() || owner.at(id) != *object.common.group_id)
                add(PageValidationCode::InvalidGroup, id);
        }
        if (const auto* connector = std::get_if<ConnectorObject>(&object.payload)) {
            for (const auto* endpoint : {&connector->start, &connector->end}) {
                if (!endpoint->attachment) continue;
                const auto& attachment = *endpoint->attachment;
                const auto target = by_id.find(attachment.target_id);
                if (target == by_id.end() || attachment.target_id == id ||
                    !valid_port(attachment.port) ||
                    !connectable(kind(*target->second)) ||
                    target->second->common.page_id != page.page_id)
                    add(PageValidationCode::InvalidReference, id);
            }
        }
    }
    return issues;
}

std::vector<std::string> visual_order(const PageContent& page) {
    const auto ordered = sorted(page, [](const PageObjectCommon& common) { return common.z_order; });
    std::vector<std::string> ids;
    ids.reserve(ordered.size());
    for (const auto* object : ordered)
        if (kind(*object) != PageObjectKind::Group) ids.push_back(object->common.id);
    return ids;
}

std::vector<std::string> accessible_order(const PageContent& page) {
    const auto ordered = sorted(page, [](const PageObjectCommon& common) { return common.reading_order; });
    std::unordered_map<std::string, std::vector<std::string>> children;
    for (const auto* object : ordered)
        if (object->common.group_id)
            children[*object->common.group_id].push_back(object->common.id);
    std::vector<std::string> ids;
    ids.reserve(ordered.size());
    for (const auto* object : ordered) {
        if (object->common.group_id) continue;
        ids.push_back(object->common.id);
        if (kind(*object) == PageObjectKind::Group)
            for (const auto& id : children[object->common.id]) ids.push_back(id);
    }
    return ids;
}

bool can_transform(const PageContent& page, std::string_view object_id) {
    std::unordered_map<std::string_view, const PageObject*> by_id;
    by_id.reserve(page.objects.size());
    for (const auto& object : page.objects) by_id.emplace(object.common.id, &object);
    const auto found = by_id.find(object_id);
    const PageObject* selected = found == by_id.end() ? nullptr : found->second;
    if (!selected || selected->common.locked) return false;
    if (selected->common.group_id) {
        const auto parent = by_id.find(*selected->common.group_id);
        return parent != by_id.end() && kind(*parent->second) == PageObjectKind::Group &&
               !parent->second->common.locked;
    }
    if (const auto* group = std::get_if<GroupObject>(&selected->payload)) {
        for (const auto& id : group->child_ids) {
            const auto child = by_id.find(id);
            if (child == by_id.end() || child->second->common.locked ||
                child->second->common.group_id != selected->common.id) return false;
        }
    }
    return true;
}

} // namespace mtn::model
