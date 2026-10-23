#include "notebook.h"

#include <iostream>
#include <stdexcept>

// Unlike assert, CHECK stays active in Release builds (NDEBUG).
#define CHECK(condition) do { if (!(condition)) { \
    std::cerr << "Check failed: " #condition " at line " << __LINE__ << '\n'; \
    return 1; \
} } while (false)

int main() {
    using mtn::model::Notebook;
    bool rejected_empty_id = false;
    try {
        Notebook invalid("", "Untitled");
    } catch (const std::invalid_argument&) {
        rejected_empty_id = true;
    }
    CHECK(rejected_empty_id);

    Notebook notebook("notebook-1", "Architecture");
    CHECK(notebook.add_section("section-1", "Processor"));
    CHECK(!notebook.add_section("section-1", "Duplicate"));
    CHECK(notebook.add_page("section-1", "page-1", "Pipeline"));
    CHECK(!notebook.add_page("missing", "page-2", "Missing section"));
    CHECK(!notebook.add_page("section-1", "page-1", "Duplicate"));
    CHECK(notebook.sections().size() == 1);
    CHECK(notebook.sections().front().pages.size() == 1);
}
