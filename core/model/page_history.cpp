#include "page_history.h"

#include <algorithm>
#include <exception>
#include <limits>
#include <new>
#include <stdexcept>
#include <string_view>
#include <type_traits>
#include <unordered_map>
#include <utility>

namespace mtn::model {
namespace {

static_assert(std::is_nothrow_move_constructible_v<PageObject>);
static_assert(std::is_nothrow_move_assignable_v<PageObject>);
static_assert(std::is_nothrow_swappable_v<PageObjectPayload>);

constexpr std::size_t missing = std::numeric_limits<std::size_t>::max();

std::size_t find_index(const PageContent& page, std::string_view id) noexcept {
    for (std::size_t i = 0; i < page.objects.size(); ++i)
        if (page.objects[i].common.id == id) return i;
    return missing;
}

class Lookup final {
public:
    Lookup(const PageContent& page, bool indexed) : page_(page), indexed_(indexed) {}

    std::size_t find(std::string_view id) {
        if (!indexed_) return find_index(page_, id);
        if (dirty_) {
            by_id_.clear();
            by_id_.reserve(page_.objects.size());
            for (std::size_t i = 0; i < page_.objects.size(); ++i)
                by_id_.emplace(page_.objects[i].common.id, i);
            dirty_ = false;
        }
        const auto found = by_id_.find(id);
        return found == by_id_.end() ? missing : found->second;
    }

    void invalidate() noexcept {
        by_id_.clear(); // string_view keys must go before vector relocation
        dirty_ = true;
    }

private:
    const PageContent& page_;
    bool indexed_ = false;
    bool dirty_ = true;
    std::unordered_map<std::string_view, std::size_t> by_id_;
};

std::size_t lookup(const PageContent& page, Lookup* index, std::string_view id) {
    return index ? index->find(id) : find_index(page, id);
}

bool editable(const PageContent& page, std::size_t index, Lookup* cache) {
    const auto& object = page.objects[index];
    if (object.common.locked) return false;
    if (object.common.group_id) {
        const auto parent = lookup(page, cache, *object.common.group_id);
        if (parent == missing || page.objects[parent].common.locked) return false;
    }
    if (const auto* group = std::get_if<GroupObject>(&object.payload)) {
        for (const auto& child_id : group->child_ids) {
            const auto child = lookup(page, cache, child_id);
            if (child == missing || page.objects[child].common.locked) return false;
        }
    }
    return true;
}

HistoryResult apply_one(PageContent& page, PageChange& change, bool forward,
                        bool enforce_lock, Lookup* cache) {
    return std::visit([&](auto& edit) -> HistoryResult {
        using T = std::decay_t<decltype(edit)>;
        if constexpr (std::is_same_v<T, CreateObject>) {
            if (forward) {
                if (!edit.parked || edit.parked->common.id != edit.id ||
                    edit.index > page.objects.size() || lookup(page, cache, edit.id) != missing)
                    return HistoryResult::InvalidCommand;
                if (cache) cache->invalidate();
                page.objects.insert(page.objects.begin() + edit.index, std::move(*edit.parked));
                edit.parked.reset();
            } else {
                const auto index = lookup(page, cache, edit.id);
                if (index == missing || index != edit.index || edit.parked)
                    return HistoryResult::InvalidCommand;
                if (cache) cache->invalidate();
                edit.parked.emplace(std::move(page.objects[index]));
                page.objects.erase(page.objects.begin() + index);
            }
        } else if constexpr (std::is_same_v<T, DeleteObject>) {
            if (forward) {
                const auto index = lookup(page, cache, edit.id);
                if (index == missing || edit.parked) return HistoryResult::InvalidCommand;
                if (enforce_lock && !editable(page, index, cache)) return HistoryResult::Locked;
                if (cache) cache->invalidate();
                edit.index = index;
                edit.parked.emplace(std::move(page.objects[index]));
                page.objects.erase(page.objects.begin() + index);
            } else {
                if (!edit.parked || edit.parked->common.id != edit.id ||
                    edit.index > page.objects.size() || lookup(page, cache, edit.id) != missing)
                    return HistoryResult::InvalidCommand;
                if (cache) cache->invalidate();
                page.objects.insert(page.objects.begin() + edit.index, std::move(*edit.parked));
                edit.parked.reset();
            }
        } else {
            const auto index = lookup(page, cache, edit.id);
            if (index == missing) return HistoryResult::InvalidCommand;
            auto& object = page.objects[index];
            if constexpr (std::is_same_v<T, SetTransform> ||
                          std::is_same_v<T, SetZOrder> ||
                          std::is_same_v<T, SetReadingOrder> ||
                          std::is_same_v<T, SetGroupId> ||
                          std::is_same_v<T, SetGroupChildren> ||
                          std::is_same_v<T, SetPayload>) {
                if (enforce_lock && !editable(page, index, cache)) return HistoryResult::Locked;
            }
            if constexpr (std::is_same_v<T, SetTransform>) {
                std::swap(object.common.transform, edit.value);
            } else if constexpr (std::is_same_v<T, SetZOrder>) {
                std::swap(object.common.z_order, edit.value);
            } else if constexpr (std::is_same_v<T, SetReadingOrder>) {
                std::swap(object.common.reading_order, edit.value);
            } else if constexpr (std::is_same_v<T, SetLocked>) {
                std::swap(object.common.locked, edit.value);
            } else if constexpr (std::is_same_v<T, SetDescription>) {
                object.common.accessible_description.swap(edit.value);
            } else if constexpr (std::is_same_v<T, SetGroupId>) {
                object.common.group_id.swap(edit.value);
            } else if constexpr (std::is_same_v<T, SetGroupChildren>) {
                auto* group = std::get_if<GroupObject>(&object.payload);
                if (!group) return HistoryResult::InvalidCommand;
                group->child_ids.swap(edit.value);
            } else if constexpr (std::is_same_v<T, SetPayload>) {
                if (object.payload.index() != edit.value.index() ||
                    std::holds_alternative<GroupObject>(object.payload))
                    return HistoryResult::InvalidCommand;
                object.payload.swap(edit.value);
            }
        }
        return HistoryResult::Applied;
    }, change);
}

std::size_t saturating_add(std::size_t a, std::size_t b) noexcept {
    const auto max = std::numeric_limits<std::size_t>::max();
    return b > max - a ? max : a + b;
}

std::size_t saturating_mul(std::size_t a, std::size_t b) noexcept {
    const auto max = std::numeric_limits<std::size_t>::max();
    return a && b > max / a ? max : a * b;
}

std::size_t string_bytes(const std::string& value) noexcept { return value.capacity(); }

std::size_t list_bytes(const std::vector<std::string>& values) noexcept {
    std::size_t bytes = saturating_mul(values.capacity(), sizeof(std::string));
    for (const auto& value : values) bytes = saturating_add(bytes, string_bytes(value));
    return bytes;
}

std::size_t payload_bytes(const PageObjectPayload& payload) noexcept {
    return std::visit([](const auto& value) noexcept -> std::size_t {
        using T = std::decay_t<decltype(value)>;
        if constexpr (std::is_same_v<T, TextContainer>)
            return text_storage_bytes(value.document);
        else if constexpr (std::is_same_v<T, InkStroke>)
            return saturating_add(saturating_mul(value.points.capacity(), sizeof(InkPoint)),
                                  value.color.capacity());
        else if constexpr (std::is_same_v<T, ImageObject> ||
                           std::is_same_v<T, GraphicAssetObject>)
            return string_bytes(value.asset_id);
        else if constexpr (std::is_same_v<T, ConnectorObject>) {
            std::size_t bytes = 0;
            if (value.start.attachment)
                bytes = saturating_add(bytes, string_bytes(value.start.attachment->target_id));
            if (value.end.attachment)
                bytes = saturating_add(bytes, string_bytes(value.end.attachment->target_id));
            return bytes;
        } else if constexpr (std::is_same_v<T, GroupObject>)
            return list_bytes(value.child_ids);
        else return 0;
    }, payload);
}

std::size_t object_bytes(const PageObject& object) noexcept {
    std::size_t bytes = sizeof(PageObject);
    bytes = saturating_add(bytes, string_bytes(object.common.id));
    bytes = saturating_add(bytes, string_bytes(object.common.page_id));
    bytes = saturating_add(bytes, string_bytes(object.common.accessible_description));
    if (object.common.group_id)
        bytes = saturating_add(bytes, string_bytes(*object.common.group_id));
    return saturating_add(bytes, payload_bytes(object.payload));
}

} // namespace

PageSession::PageSession(PageContent page, HistoryLimits limits)
    : page_(std::move(page)), limits_(limits) {
    if (!limits_.max_bytes || !limits_.max_command_bytes || !limits_.max_entries ||
        limits_.max_command_bytes > limits_.max_bytes ||
        limits_.max_bytes > std::numeric_limits<std::size_t>::max() / 2)
        throw std::invalid_argument("invalid page history limits");
    if (!validate_page(page_).empty())
        throw std::invalid_argument("invalid initial page content");
}

std::size_t PageSession::estimated_bytes(const PageCommand& command) const noexcept {
    std::size_t bytes = sizeof(PageCommand);
    bytes = saturating_add(bytes, string_bytes(command.label));
    if (!command.selection_before.empty())
        bytes = saturating_add(bytes, string_bytes(command.selection_before));
    if (!command.selection_after.empty())
        bytes = saturating_add(bytes, string_bytes(command.selection_after));
    bytes = saturating_add(bytes,
                           saturating_mul(command.changes.capacity(), sizeof(PageChange)));
    for (const auto& change : command.changes) {
        bytes = saturating_add(bytes, std::visit([&](const auto& edit) noexcept -> std::size_t {
            using T = std::decay_t<decltype(edit)>;
            std::size_t extra = string_bytes(edit.id);
            if constexpr (std::is_same_v<T, CreateObject>) {
                if (edit.parked) extra = saturating_add(extra, object_bytes(*edit.parked));
            } else if constexpr (std::is_same_v<T, DeleteObject>) {
                const auto index = find_index(page_, edit.id);
                if (index != missing) extra = saturating_add(extra, object_bytes(page_.objects[index]));
            } else if constexpr (std::is_same_v<T, SetDescription>) {
                const auto index = find_index(page_, edit.id);
                extra = saturating_add(extra, std::max(string_bytes(edit.value),
                    index == missing ? std::size_t{0} :
                    string_bytes(page_.objects[index].common.accessible_description)));
            } else if constexpr (std::is_same_v<T, SetGroupId>) {
                const auto index = find_index(page_, edit.id);
                const auto old_bytes = index != missing && page_.objects[index].common.group_id
                    ? string_bytes(*page_.objects[index].common.group_id) : std::size_t{0};
                const auto new_bytes = edit.value ? string_bytes(*edit.value) : std::size_t{0};
                extra = saturating_add(extra, std::max(old_bytes, new_bytes));
            } else if constexpr (std::is_same_v<T, SetGroupChildren>) {
                const auto index = find_index(page_, edit.id);
                std::size_t old_bytes = 0;
                if (index != missing)
                    if (const auto* group = std::get_if<GroupObject>(&page_.objects[index].payload))
                        old_bytes = list_bytes(group->child_ids);
                extra = saturating_add(extra, std::max(list_bytes(edit.value), old_bytes));
            } else if constexpr (std::is_same_v<T, SetPayload>) {
                const auto index = find_index(page_, edit.id);
                extra = saturating_add(extra, std::max(payload_bytes(edit.value),
                    index == missing ? std::size_t{0} :
                    payload_bytes(page_.objects[index].payload)));
            }
            return extra;
        }, change));
    }
    return bytes;
}

HistoryResult PageSession::apply(PageCommand& command, bool forward) {
    std::size_t insertions = 0;
    for (const auto& change : command.changes)
        if ((forward && std::holds_alternative<CreateObject>(change)) ||
            (!forward && std::holds_alternative<DeleteObject>(change))) ++insertions;
    if (insertions > page_.objects.max_size() - page_.objects.size())
        return HistoryResult::BudgetExceeded;

    try {
        page_.objects.reserve(page_.objects.size() + insertions);
    } catch (const std::bad_alloc&) {
        return HistoryResult::OutOfMemory;
    } catch (const std::length_error&) {
        return HistoryResult::BudgetExceeded;
    }

    std::size_t applied = 0;
    HistoryResult result = HistoryResult::Applied;
    Lookup cache(page_, command.changes.size() >= 8);
    try {
        for (std::size_t step = 0; step < command.changes.size(); ++step) {
            const auto index = forward ? step : command.changes.size() - 1 - step;
            result = apply_one(page_, command.changes[index], forward, forward, &cache);
            if (result != HistoryResult::Applied) break;
            ++applied;
        }
        if (result == HistoryResult::Applied && !validate_page(page_).empty())
            result = HistoryResult::InvalidPage;
    } catch (const std::bad_alloc&) {
        result = HistoryResult::OutOfMemory;
    } catch (const std::length_error&) {
        result = HistoryResult::BudgetExceeded;
    }
    if (result == HistoryResult::Applied) return result;

    // All reverse steps use moves/swaps and the vector capacity reserved above.
    // They cannot allocate, including when validation ran out of memory.
    for (std::size_t step = applied; step > 0; --step) {
        const auto index = forward ? step - 1 : command.changes.size() - step;
        if (apply_one(page_, command.changes[index], !forward, false, nullptr) != HistoryResult::Applied)
            std::terminate(); // a broken internal inverse must never be hidden
    }
    return result;
}

HistoryResult PageSession::execute(PageCommand command) {
    if (command.changes.empty()) return HistoryResult::NothingToDo;
    const auto bytes = estimated_bytes(command);
    if (bytes > limits_.max_command_bytes || bytes > limits_.max_bytes)
        return HistoryResult::BudgetExceeded;
    try {
        undo_.push_back({std::move(command), bytes});
    } catch (const std::bad_alloc&) {
        return HistoryResult::OutOfMemory;
    } catch (const std::length_error&) {
        return HistoryResult::BudgetExceeded;
    }
    const auto result = apply(undo_.back().command, true);
    if (result != HistoryResult::Applied) {
        undo_.pop_back();
        return result;
    }
    history_bytes_ += bytes;
    for (const auto& entry : redo_) history_bytes_ -= entry.reserved_bytes;
    redo_.clear();
    prune_history();
    return HistoryResult::Applied;
}

HistoryResult PageSession::undo() {
    if (undo_.empty()) return HistoryResult::NothingToDo;
    try {
        redo_.emplace_back();
    } catch (const std::bad_alloc&) {
        return HistoryResult::OutOfMemory;
    } catch (const std::length_error&) {
        return HistoryResult::BudgetExceeded;
    }
    const auto result = apply(undo_.back().command, false);
    if (result == HistoryResult::Applied) {
        redo_.back() = std::move(undo_.back());
        undo_.pop_back();
    } else redo_.pop_back();
    return result;
}

HistoryResult PageSession::redo() {
    if (redo_.empty()) return HistoryResult::NothingToDo;
    try {
        undo_.emplace_back();
    } catch (const std::bad_alloc&) {
        return HistoryResult::OutOfMemory;
    } catch (const std::length_error&) {
        return HistoryResult::BudgetExceeded;
    }
    const auto result = apply(redo_.back().command, true);
    if (result == HistoryResult::Applied) {
        undo_.back() = std::move(redo_.back());
        redo_.pop_back();
    } else undo_.pop_back();
    return result;
}

HistoryResult PageSession::execute_merged(PageCommand command) {
    const auto mergeable = [&] {
        if (undo_.empty() || !redo_.empty() || command.changes.empty()) return false;
        const auto& top = undo_.back().command.changes;
        if (top.size() != command.changes.size()) return false;
        for (std::size_t i = 0; i < top.size(); ++i) {
            const auto same = std::visit([&](const auto& older) {
                using T = std::decay_t<decltype(older)>;
                if constexpr (std::is_same_v<T, SetTransform> || std::is_same_v<T, SetPayload>) {
                    const auto* newer = std::get_if<T>(&command.changes[i]);
                    return newer && newer->id == older.id;
                } else {
                    return false;
                }
            }, top[i]);
            if (!same) return false;
        }
        return true;
    }();
    if (!mergeable) return execute(std::move(command));

    // The newest entry already holds the values from before the burst; the
    // swaps leave the newer command holding only intermediate values.
    const auto bytes = estimated_bytes(command);
    if (bytes > limits_.max_command_bytes) return HistoryResult::BudgetExceeded;
    const auto result = apply(command, true);
    if (result != HistoryResult::Applied) return result;
    undo_.back().command.selection_after = std::move(command.selection_after);
    return HistoryResult::Applied;
}

HistoryResult PageSession::undo_and_forget() {
    const auto result = undo();
    if (result != HistoryResult::Applied) return result;
    history_bytes_ -= redo_.back().reserved_bytes;
    redo_.pop_back();
    return result;
}

void PageSession::prune_history() noexcept {
    while (undo_.size() > limits_.max_entries || history_bytes_ > limits_.max_bytes) {
        history_bytes_ -= undo_.front().reserved_bytes;
        undo_.pop_front();
    }
}

void PageSession::clear_history() noexcept {
    undo_.clear();
    redo_.clear();
    history_bytes_ = 0;
}

} // namespace mtn::model
