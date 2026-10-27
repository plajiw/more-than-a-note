#include "page_history.h"

#include <cstdio>
#include <iostream>
#include <stdexcept>
#include <string>
#include <utility>

#define CHECK(condition) do { if (!(condition)) { \
    std::cerr << "Check failed: " #condition " at line " << __LINE__ << '\n'; \
    return 1; \
} } while (false)

namespace {
using namespace mtn::model;

constexpr const char* page_id = "11111111-1111-4111-8111-111111111111";
constexpr const char* text_id = "22222222-2222-4222-8222-222222222222";
constexpr const char* ink_id = "33333333-3333-4333-8333-333333333333";
constexpr const char* shape_id = "44444444-4444-4444-8444-444444444444";
constexpr const char* connector_id = "55555555-5555-4555-8555-555555555555";
constexpr const char* group_id = "66666666-6666-4666-8666-666666666666";

PageObject object(const char* id, PageObjectPayload payload) {
    PageObjectCommon common;
    common.id = id;
    common.page_id = page_id;
    return {std::move(common), std::move(payload)};
}

const PageObject* find(const PageContent& page, const char* id) {
    for (const auto& entry : page.objects)
        if (entry.common.id == id) return &entry;
    return nullptr;
}

PageCommand one(const char* label, PageChange change) {
    PageCommand command;
    command.label = label;
    command.changes.push_back(std::move(change));
    return command;
}
} // namespace

int main() {
    using namespace mtn::model;

    PageContent initial{page_id, {object(text_id, TextContainer{})}};
    PageSession session(std::move(initial));
    CHECK(session.execute({}) == HistoryResult::NothingToDo);
    CHECK(session.undo() == HistoryResult::NothingToDo);

    InkStroke stroke;
    stroke.points = {{{0, 0}, 0.4, 0.0, {}, {}},
                     {{5, 8}, 0.8, 12.0, {}, {}}};
    auto ink = object(ink_id, std::move(stroke));
    auto create_ink = one("Draw", CreateObject{ink_id, 1, std::move(ink)});
    CHECK(session.execute(std::move(create_ink)) == HistoryResult::Applied);
    CHECK(session.page().objects.size() == 2);
    CHECK(std::get<InkStroke>(find(session.page(), ink_id)->payload).points.size() == 2);

    PageTransform moved;
    moved.translation = {12, -7};
    CHECK(session.execute(one("Move text", SetTransform{text_id, moved})) == HistoryResult::Applied);
    CHECK(find(session.page(), text_id)->common.transform.translation.x == 12);

    auto group = object(group_id, GroupObject{{text_id, ink_id}});
    PageCommand make_group;
    make_group.label = "Group text and ink";
    make_group.changes.emplace_back(CreateObject{group_id, 2, std::move(group)});
    make_group.changes.emplace_back(SetGroupId{text_id, std::string(group_id)});
    make_group.changes.emplace_back(SetGroupId{ink_id, std::string(group_id)});
    CHECK(session.execute(std::move(make_group)) == HistoryResult::Applied);
    CHECK(session.page().objects.size() == 3);
    CHECK(validate_page(session.page()).empty());
    CHECK(session.undo_depth() == 3);

    // One undo reverses the whole group, then movement, then the stroke.
    CHECK(session.undo() == HistoryResult::Applied);
    CHECK(!find(session.page(), group_id));
    CHECK(!find(session.page(), text_id)->common.group_id);
    CHECK(session.undo() == HistoryResult::Applied);
    CHECK(find(session.page(), text_id)->common.transform.translation.x == 0);
    CHECK(session.undo() == HistoryResult::Applied);
    CHECK(!find(session.page(), ink_id));
    CHECK(session.redo_depth() == 3);
    CHECK(session.redo() == HistoryResult::Applied);
    CHECK(session.redo() == HistoryResult::Applied);
    CHECK(session.redo() == HistoryResult::Applied);
    CHECK(find(session.page(), text_id)->common.transform.translation.x == 12);
    CHECK(std::get<InkStroke>(find(session.page(), ink_id)->payload).points[1].pressure == 0.8);
    CHECK(validate_page(session.page()).empty());

    // The transaction is rejected atomically if a later change is invalid.
    PageCommand broken;
    broken.changes.emplace_back(SetTransform{text_id, PageTransform{{80, 0}, 0, 1, 1}});
    broken.changes.emplace_back(SetPayload{text_id, ShapeObject{}});
    CHECK(session.execute(std::move(broken)) == HistoryResult::InvalidCommand);
    CHECK(find(session.page(), text_id)->common.transform.translation.x == 12);
    CHECK(session.undo_depth() == 3);
    CHECK(validate_page(session.page()).empty());

    // Deleting a grouped child without updating membership must roll back.
    CHECK(session.execute(one("Invalid delete", DeleteObject{text_id})) ==
          HistoryResult::InvalidPage);
    CHECK(find(session.page(), text_id));
    CHECK(session.page().objects.size() == 3);

    // Lock checks cover members and their parent; unlocking remains possible.
    CHECK(session.execute(one("Lock group", SetLocked{group_id, true})) == HistoryResult::Applied);
    CHECK(session.execute(one("Move locked child", SetTransform{text_id, moved})) ==
          HistoryResult::Locked);
    CHECK(session.undo() == HistoryResult::Applied);
    CHECK(!find(session.page(), group_id)->common.locked);

    // New successful work clears redo. A rejected command above did not.
    CHECK(session.redo_depth() == 1);
    CHECK(session.execute(one("Describe", SetDescription{text_id, "Lecture text"})) ==
          HistoryResult::Applied);
    CHECK(session.redo_depth() == 0);
    CHECK(find(session.page(), text_id)->common.accessible_description == "Lecture text");
    CHECK(session.undo() == HistoryResult::Applied);
    CHECK(find(session.page(), text_id)->common.accessible_description.empty());

    // A node deletion needs a connector update in the same transaction.
    ConnectorObject connector;
    connector.start = {{3, 4}, ConnectorAttachment{shape_id, AnchorPort::Right}};
    connector.end = {{20, 4}, {}};
    PageContent diagram{page_id, {object(shape_id, ShapeObject{}),
                                  object(connector_id, connector)}};
    PageSession diagram_session(std::move(diagram));
    CHECK(diagram_session.execute(one("Dangling", DeleteObject{shape_id})) ==
          HistoryResult::InvalidPage);
    CHECK(find(diagram_session.page(), shape_id));
    ConnectorObject detached = connector;
    detached.start.attachment.reset();
    PageCommand remove_node;
    remove_node.changes.emplace_back(SetPayload{connector_id, detached});
    remove_node.changes.emplace_back(DeleteObject{shape_id});
    CHECK(diagram_session.execute(std::move(remove_node)) == HistoryResult::Applied);
    CHECK(!find(diagram_session.page(), shape_id));
    CHECK(!std::get<ConnectorObject>(find(diagram_session.page(), connector_id)->payload)
               .start.attachment);
    CHECK(diagram_session.undo() == HistoryResult::Applied);
    CHECK(find(diagram_session.page(), shape_id));
    CHECK(std::get<ConnectorObject>(find(diagram_session.page(), connector_id)->payload)
              .start.attachment->target_id == shape_id);

    // History accounts for a large stroke but moving it stores only a small
    // transform. A full replacement is refused when it exceeds the budget.
    InkStroke large;
    large.points.resize(20'000);
    for (std::size_t i = 0; i < large.points.size(); ++i)
        large.points[i].position = {static_cast<double>(i), 2};
    PageContent dense{page_id, {object(ink_id, std::move(large))}};
    // The byte budget fits more than eight small commands (each carries its
    // label and the restorable selection), so the entry limit is what binds.
    PageSession limited(std::move(dense), HistoryLimits{8192, 2048, 8});
    PageTransform shift;
    shift.translation = {4, 5};
    CHECK(limited.execute(one("Move ink", SetTransform{ink_id, shift})) == HistoryResult::Applied);
    CHECK(limited.history_bytes() < 1024);
    CHECK(std::get<InkStroke>(find(limited.page(), ink_id)->payload).points.size() == 20'000);
    InkStroke replacement = std::get<InkStroke>(find(limited.page(), ink_id)->payload);
    CHECK(limited.execute(one("Replace ink", SetPayload{ink_id, std::move(replacement)})) ==
          HistoryResult::BudgetExceeded);
    CHECK(limited.undo_depth() == 1);
    CHECK(std::get<InkStroke>(find(limited.page(), ink_id)->payload).points.size() == 20'000);

    for (int i = 0; i < 100; ++i) {
        shift.translation.x = i;
        CHECK(limited.execute(one("Move ink", SetTransform{ink_id, shift})) ==
              HistoryResult::Applied);
        CHECK(limited.history_bytes() <= 8192);
        CHECK(limited.undo_depth() <= 8);
    }
    CHECK(limited.undo_depth() == 8);
    for (int i = 0; i < 8; ++i) CHECK(limited.undo() == HistoryResult::Applied);
    CHECK(limited.undo() == HistoryResult::NothingToDo);
    for (int i = 0; i < 8; ++i) CHECK(limited.redo() == HistoryResult::Applied);
    limited.clear_history();
    CHECK(limited.history_bytes() == 0);
    CHECK(limited.undo_depth() == 0);

    // A large batch exercises the indexed lookup, one undo for the whole
    // group, and rollback after several successful edits.
    PageSession many(PageContent{page_id, {}});
    PageCommand create_many;
    std::vector<std::string> ids;
    for (unsigned i = 0; i < 16; ++i) {
        char buffer[37];
        std::snprintf(buffer, sizeof(buffer), "%08x-aaaa-4aaa-8aaa-aaaaaaaaaaaa", i + 1);
        ids.emplace_back(buffer);
        create_many.changes.emplace_back(CreateObject{ids.back(), i,
            object(ids.back().c_str(), TextContainer{})});
    }
    CHECK(many.execute(std::move(create_many)) == HistoryResult::Applied);
    PageCommand group_many;
    group_many.changes.emplace_back(CreateObject{group_id, ids.size(),
        object(group_id, GroupObject{ids})});
    for (const auto& id : ids)
        group_many.changes.emplace_back(SetGroupId{id, std::string(group_id)});
    CHECK(many.execute(std::move(group_many)) == HistoryResult::Applied);
    CHECK(validate_page(many.page()).empty());
    CHECK(many.undo() == HistoryResult::Applied);
    CHECK(!find(many.page(), group_id));
    CHECK(many.redo() == HistoryResult::Applied);
    CHECK(find(many.page(), group_id));
    PageCommand fail_late;
    for (int i = 0; i < 9; ++i)
        fail_late.changes.emplace_back(SetTransform{ids[i], PageTransform{{30, 0}, 0, 1, 1}});
    fail_late.changes.emplace_back(SetPayload{ids[9], ShapeObject{}});
    CHECK(many.execute(std::move(fail_late)) == HistoryResult::InvalidCommand);
    for (int i = 0; i < 9; ++i)
        CHECK(find(many.page(), ids[i].c_str())->common.transform.translation.x == 0);
    CHECK(validate_page(many.page()).empty());
    PageCommand move_group;
    for (const auto& id : ids)
        move_group.changes.emplace_back(SetTransform{id, PageTransform{{7, 9}, 0, 1, 1}});
    CHECK(many.execute(std::move(move_group)) == HistoryResult::Applied);
    for (const auto& id : ids)
        CHECK(find(many.page(), id.c_str())->common.transform.translation.x == 7);
    CHECK(many.undo() == HistoryResult::Applied);
    for (const auto& id : ids)
        CHECK(find(many.page(), id.c_str())->common.transform.translation.x == 0);
    CHECK(many.redo() == HistoryResult::Applied);

    // Bursts fold into one entry that still restores the value from before
    // the burst, and redo returns the last value of the burst.
    PageSession burst(PageContent{page_id, {object(text_id, TextContainer{})}});
    for (int step = 1; step <= 5; ++step) {
        auto nudge = one("Nudge", SetTransform{text_id, PageTransform{{double(step), 0}, 0, 1, 1}});
        nudge.selection_before = "before-" + std::to_string(step);
        nudge.selection_after = "after-" + std::to_string(step);
        CHECK(burst.execute_merged(std::move(nudge)) == HistoryResult::Applied);
    }
    CHECK(burst.undo_depth() == 1);
    CHECK(burst.next_undo()->selection_before == "before-1");
    CHECK(burst.next_undo()->selection_after == "after-5");
    CHECK(find(burst.page(), text_id)->common.transform.translation.x == 5);
    CHECK(burst.undo() == HistoryResult::Applied);
    CHECK(find(burst.page(), text_id)->common.transform.translation.x == 0);
    CHECK(burst.redo() == HistoryResult::Applied);
    CHECK(find(burst.page(), text_id)->common.transform.translation.x == 5);
    // A different field or object is never folded into the previous entry.
    TextContainer wider;
    wider.width_pt = 300;
    CHECK(burst.execute_merged(one("Resize", SetPayload{text_id, wider})) == HistoryResult::Applied);
    CHECK(burst.undo_depth() == 2);
    // Pending redo blocks folding, so an undone burst is not rewritten.
    CHECK(burst.undo() == HistoryResult::Applied);
    CHECK(burst.execute_merged(one("Nudge", SetTransform{text_id, PageTransform{{9, 0}, 0, 1, 1}}))
          == HistoryResult::Applied);
    CHECK(burst.undo_depth() == 2);
    CHECK(burst.redo_depth() == 0);
    // An abandoned creation leaves no undo or redo entry.
    const auto depth = burst.undo_depth();
    CHECK(burst.execute(one("Draw", CreateObject{ink_id, 1, object(ink_id, InkStroke{{{{0, 0}, 0.5, 0, {}, {}}}})}))
          == HistoryResult::Applied);
    CHECK(burst.undo_and_forget() == HistoryResult::Applied);
    CHECK(!find(burst.page(), ink_id));
    CHECK(burst.undo_depth() == depth);
    CHECK(burst.redo_depth() == 0);

    bool rejected = false;
    try { PageSession invalid(PageContent{"invalid", {}}); }
    catch (const std::invalid_argument&) { rejected = true; }
    CHECK(rejected);
    return 0;
}
