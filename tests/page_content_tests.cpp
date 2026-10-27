#include "page_content.h"

#include <cmath>
#include <iostream>
#include <limits>
#include <optional>
#include <string>
#include <vector>

#define CHECK(condition) do { if (!(condition)) { \
    std::cerr << "Check failed: " #condition " at line " << __LINE__ << '\n'; \
    return 1; \
} } while (false)

namespace {
using namespace mtn::model;

constexpr const char* page_id = "11111111-1111-4111-8111-111111111111";
constexpr const char* text_id = "22222222-2222-4222-8222-222222222222";
constexpr const char* ink_id = "33333333-3333-4333-8333-333333333333";
constexpr const char* image_id = "44444444-4444-4444-8444-444444444444";
constexpr const char* graphic_id = "55555555-5555-4555-8555-555555555555";
constexpr const char* shape_id = "66666666-6666-4666-8666-666666666666";
constexpr const char* connector_id = "77777777-7777-4777-8777-777777777777";
constexpr const char* group_id = "88888888-8888-4888-8888-888888888888";
constexpr const char* second_group_id = "99999999-9999-4999-8999-999999999999";
constexpr const char* asset_id = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";

PageObject make_object(const char* id, PageObjectPayload payload, std::int64_t z = 0,
                       std::int64_t reading = 0) {
    PageObjectCommon common;
    common.id = id;
    common.page_id = page_id;
    common.z_order = z;
    common.reading_order = reading;
    return {std::move(common), std::move(payload)};
}

PageContent sample_page() {
    PageContent page{page_id, {}};
    page.objects.push_back(make_object(text_id, TextContainer{}, 1, 2));
    page.objects.push_back(make_object(ink_id, InkStroke{{InkPoint{{-2, 4}, 0.5, 0.0, {}, {}},
                                                           InkPoint{{3, 9}, {}, 4.0, {}, {}}}, 2},
                                      5, 1));
    page.objects.push_back(make_object(image_id, ImageObject{asset_id, 100, 80}, 2, 3));
    page.objects.push_back(make_object(graphic_id, GraphicAssetObject{asset_id, 120, 90}, 2, 4));
    page.objects.push_back(make_object(shape_id, ShapeObject{ShapeKind::Rectangle, 50, 40}, 3, 5));
    ConnectorObject connector;
    connector.start = {{0, 0}, ConnectorAttachment{shape_id, AnchorPort::Right}};
    connector.end = {{100, 20}, std::nullopt};
    page.objects.push_back(make_object(connector_id, connector, 4, 6));
    page.objects.push_back(make_object(group_id, GroupObject{{text_id, image_id}}, 9, 0));
    page.objects[0].common.group_id = group_id;
    page.objects[2].common.group_id = group_id;
    return page;
}

bool has_issue(const PageContent& page, PageValidationCode code) {
    for (const auto& issue : validate_page(page))
        if (issue.code == code) return true;
    return false;
}
} // namespace

int main() {
    using namespace mtn::model;
    CHECK(valid_uuid(page_id));
    CHECK(!valid_uuid("not-an-id"));
    CHECK(!valid_uuid("00000000-0000-0000-0000-000000000000"));
    CHECK(!valid_uuid("AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA"));

    const PageContent valid = sample_page();
    CHECK(validate_page(valid).empty());
    CHECK(kind(valid.objects[0]) == PageObjectKind::Text);
    CHECK(kind(valid.objects[3]) == PageObjectKind::GraphicAsset);
    CHECK((visual_order(valid) == std::vector<std::string>{text_id, image_id, graphic_id,
                                                           shape_id, connector_id, ink_id}));
    CHECK((accessible_order(valid) == std::vector<std::string>{group_id, text_id, image_id,
                                                               ink_id, graphic_id, shape_id,
                                                               connector_id}));
    CHECK(can_transform(valid, group_id));
    CHECK(can_transform(valid, text_id));
    CHECK(!can_transform(valid, "missing"));

    PageTransform transform{{-20, 10}, 90, 2, 3};
    const auto mapped = to_page(transform, {4, 5});
    CHECK(mapped.has_value());
    CHECK(std::abs(mapped->x - (-35)) < 1e-10);
    CHECK(std::abs(mapped->y - 18) < 1e-10);
    const auto roundtrip = from_page(transform, *mapped);
    CHECK(roundtrip.has_value());
    CHECK(std::abs(roundtrip->x - 4) < 1e-10);
    CHECK(std::abs(roundtrip->y - 5) < 1e-10);
    transform.scale_x = 0;
    CHECK(!to_page(transform, {1, 1}));

    auto page = valid;
    page.objects.push_back(page.objects.front());
    CHECK(has_issue(page, PageValidationCode::DuplicateObjectId));
    page = valid;
    page.objects[0].common.id = "broken";
    CHECK(has_issue(page, PageValidationCode::InvalidObjectId));
    page = valid;
    page.objects[0].common.page_id = second_group_id;
    CHECK(has_issue(page, PageValidationCode::WrongPage));
    page = valid;
    page.objects[0].common.transform.scale_y = 0;
    CHECK(has_issue(page, PageValidationCode::InvalidTransform));
    page = valid;
    page.objects[0].common.transform.rotation_degrees = 20;
    CHECK(has_issue(page, PageValidationCode::InvalidTransform));
    page = valid;
    page.objects[5].common.transform.translation.x = 1;
    CHECK(has_issue(page, PageValidationCode::InvalidTransform));
    page = valid;
    std::get<TextContainer>(page.objects[0].payload).width_pt =
        std::numeric_limits<double>::quiet_NaN();
    CHECK(has_issue(page, PageValidationCode::InvalidGeometry));
    page = valid;
    std::get<InkStroke>(page.objects[1].payload).points[0].pressure = 1.5;
    CHECK(has_issue(page, PageValidationCode::InvalidInk));
    page = valid;
    std::get<ImageObject>(page.objects[2].payload).asset_id = "../outside";
    CHECK(has_issue(page, PageValidationCode::InvalidAssetId));
    page = valid;
    std::get<ConnectorObject>(page.objects[5].payload).start.attachment->target_id = asset_id;
    CHECK(has_issue(page, PageValidationCode::InvalidReference));
    page = valid;
    page.objects[4].common.page_id = second_group_id;
    CHECK(has_issue(page, PageValidationCode::InvalidReference));
    page = valid;
    std::get<ConnectorObject>(page.objects[5].payload).end.fallback.x =
        std::numeric_limits<double>::infinity();
    CHECK(has_issue(page, PageValidationCode::InvalidGeometry));

    page = valid;
    std::get<GroupObject>(page.objects[6].payload).child_ids.push_back(text_id);
    CHECK(has_issue(page, PageValidationCode::InvalidGroup));
    page = valid;
    std::get<GroupObject>(page.objects[6].payload).child_ids.push_back(group_id);
    CHECK(has_issue(page, PageValidationCode::InvalidGroup));
    page = valid;
    page.objects[6].common.transform.translation.x = 2;
    CHECK(has_issue(page, PageValidationCode::InvalidGroup));
    page = valid;
    page.objects[0].common.group_id = second_group_id;
    CHECK(has_issue(page, PageValidationCode::InvalidGroup));
    page = valid;
    page.objects.push_back(make_object(second_group_id, GroupObject{{text_id}}, 10, 7));
    CHECK(has_issue(page, PageValidationCode::InvalidGroup));
    page = valid;
    page.objects[6].common.locked = true;
    CHECK(!can_transform(page, text_id));
    CHECK(!can_transform(page, group_id));
    page = valid;
    page.objects[2].common.locked = true;
    CHECK(!can_transform(page, group_id));
    CHECK(can_transform(page, text_id));
    return 0;
}
