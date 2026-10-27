#pragma once

#include "page_content.h"

#include <cstddef>
#include <cstdint>
#include <deque>
#include <optional>
#include <string>
#include <vector>

namespace mtn::model {

// Changes store only the fields that change. A whole InkStroke is never copied
// just to move it. Object ownership moves between the page and history for
// creation/deletion, and values are swapped for edits.
struct CreateObject {
    std::string id;
    std::size_t index = 0;
    std::optional<PageObject> parked;
};

struct DeleteObject {
    std::string id;
    std::size_t index = 0; // filled on first execution
    std::optional<PageObject> parked;
};

struct SetTransform { std::string id; PageTransform value; };
struct SetZOrder { std::string id; std::int64_t value = 0; };
struct SetReadingOrder { std::string id; std::int64_t value = 0; };
struct SetLocked { std::string id; bool value = false; };
struct SetDescription { std::string id; std::string value; };
struct SetGroupId { std::string id; std::optional<std::string> value; };
struct SetGroupChildren { std::string id; std::vector<std::string> value; };
struct SetPayload { std::string id; PageObjectPayload value; };

using PageChange = std::variant<CreateObject, DeleteObject, SetTransform,
                                SetZOrder, SetReadingOrder, SetLocked,
                                SetDescription, SetGroupId, SetGroupChildren,
                                SetPayload>;

struct PageCommand {
    std::string label;
    std::vector<PageChange> changes;
    // Opaque UI state (for example a caret range) restored by undo and redo.
    std::string selection_before;
    std::string selection_after;
};

enum class HistoryResult {
    Applied,
    NothingToDo,
    InvalidCommand,
    InvalidPage,
    Locked,
    BudgetExceeded,
    OutOfMemory
};

struct HistoryLimits {
    std::size_t max_bytes = 64u * 1024u * 1024u;
    std::size_t max_command_bytes = 16u * 1024u * 1024u;
    std::size_t max_entries = 512;
};

// Owns the page so callers cannot bypass the history and leave undo/redo stale.
// Throws std::invalid_argument for an invalid initial page or limits.
class PageSession final {
public:
    explicit PageSession(PageContent page, HistoryLimits limits = {});

    const PageContent& page() const noexcept { return page_; }
    HistoryResult execute(PageCommand command);
    // Folds the command into the newest entry when both edit the same fields
    // of the same objects, so a held arrow key or a typing burst is one step.
    // The newest entry keeps its original values; nothing to redo is required.
    // Falls back to a normal execute when the commands are not compatible.
    HistoryResult execute_merged(PageCommand command);
    HistoryResult undo();
    HistoryResult redo();
    // Undoes the newest entry and drops it instead of offering it to redo,
    // for edits that should leave no trace (an empty text box abandoned).
    HistoryResult undo_and_forget();
    void clear_history() noexcept;

    const PageCommand* next_undo() const noexcept { return undo_.empty() ? nullptr : &undo_.back().command; }
    const PageCommand* next_redo() const noexcept { return redo_.empty() ? nullptr : &redo_.back().command; }

    std::size_t undo_depth() const noexcept { return undo_.size(); }
    std::size_t redo_depth() const noexcept { return redo_.size(); }
    std::size_t history_bytes() const noexcept { return history_bytes_; }

private:
    struct RecordedCommand {
        PageCommand command;
        std::size_t reserved_bytes = 0;
    };

    PageContent page_;
    HistoryLimits limits_;
    std::deque<RecordedCommand> undo_;
    std::deque<RecordedCommand> redo_;
    std::size_t history_bytes_ = 0;

    std::size_t estimated_bytes(const PageCommand& command) const noexcept;
    HistoryResult apply(PageCommand& command, bool forward);
    void prune_history() noexcept;
};

} // namespace mtn::model
