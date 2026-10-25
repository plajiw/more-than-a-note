#pragma once

#include "rich_text.h"

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <variant>
#include <vector>

namespace mtn::model {

// All geometry is in page points (1/72 inch), never screen pixels or DPI.
struct PagePoint {
    double x = 0;
    double y = 0;
};

struct PageTransform {
    PagePoint translation;
    double rotation_degrees = 0;
    double scale_x = 1;
    double scale_y = 1;
};

struct PageObjectCommon {
    std::string id;
    std::string page_id;
    PageTransform transform;
    std::int64_t z_order = 0;
    std::int64_t reading_order = 0;
    bool locked = false;
    std::string accessible_description;
    std::optional<std::string> group_id;
};

struct TextContainer {
    double width_pt = 240;
    double max_width_pt = 500;
    bool fixed_width = false;
    RichTextDocument document;
};

struct InkPoint {
    PagePoint position;
    std::optional<double> pressure;
    std::optional<double> relative_time_ms;
    std::optional<double> tilt_x;
    std::optional<double> tilt_y;
};

enum class InkBrush : std::uint8_t { Pen, Highlighter };

struct InkStroke {
    std::vector<InkPoint> points;
    double base_width_pt = 2;
    InkBrush brush = InkBrush::Pen;
    std::string color = "#000000FF";
};

struct ImageObject {
    std::string asset_id;
    double width_pt = 1;
    double height_pt = 1;
};

struct GraphicAssetObject {
    std::string asset_id;
    double width_pt = 1;
    double height_pt = 1;
};

enum class ShapeKind { Rectangle, Ellipse, Line, Arrow };

struct ShapeObject {
    ShapeKind shape = ShapeKind::Rectangle;
    double width_pt = 1;
    double height_pt = 1;
};

enum class AnchorPort { Center, Top, Right, Bottom, Left };

struct ConnectorAttachment {
    std::string target_id;
    AnchorPort port = AnchorPort::Center;
};

struct ConnectorEndpoint {
    PagePoint fallback;
    std::optional<ConnectorAttachment> attachment;
};

struct ConnectorObject {
    ConnectorEndpoint start;
    ConnectorEndpoint end;
};

// Flat groups organize objects but do not create another painted layer.
// Member transforms and z-order remain authoritative.
struct GroupObject {
    std::vector<std::string> child_ids;
};

using PageObjectPayload = std::variant<TextContainer, InkStroke, ImageObject,
                                       GraphicAssetObject, ShapeObject,
                                       ConnectorObject, GroupObject>;

enum class PageObjectKind { Text, Ink, Image, GraphicAsset, Shape, Connector, Group };

struct PageObject {
    PageObjectCommon common;
    PageObjectPayload payload;
};

struct PageContent {
    std::string page_id;
    std::vector<PageObject> objects;
};

enum class PageValidationCode {
    InvalidPageId,
    InvalidObjectId,
    DuplicateObjectId,
    WrongPage,
    InvalidTransform,
    InvalidGeometry,
    InvalidText,
    InvalidInk,
    InvalidAssetId,
    InvalidReference,
    InvalidGroup
};

struct PageValidationIssue {
    PageValidationCode code;
    std::string object_id;
};

bool valid_uuid(std::string_view id) noexcept;
bool valid_ink_stroke(const InkStroke& stroke) noexcept;
PageObjectKind kind(const PageObject& object);
std::vector<PageValidationIssue> validate_page(const PageContent& page);

// Empty result means a non-finite input or output, or a singular transform.
std::optional<PagePoint> to_page(const PageTransform& transform, PagePoint local) noexcept;
std::optional<PagePoint> from_page(const PageTransform& transform, PagePoint page) noexcept;

// Group nodes have no visual layer. Accessible order contains the group,
// followed by its children, and does not depend on paint order.
std::vector<std::string> visual_order(const PageContent& page);
std::vector<std::string> accessible_order(const PageContent& page);

// Locks are checked at the object and its flat parent group. A group can move
// only when none of its members are locked.
bool can_transform(const PageContent& page, std::string_view object_id);

} // namespace mtn::model
