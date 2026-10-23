#include "notebook.h"

#include <algorithm>
#include <stdexcept>
#include <utility>

namespace mtn::model
{

    Notebook::Notebook(std::string id, std::string title)
        : id_(std::move(id)), title_(std::move(title))
    {
        if (id_.empty())
        {
            throw std::invalid_argument("notebook id cannot be empty");
        }
    }

    const std::string &Notebook::id() const noexcept { return id_; }
    const std::string &Notebook::title() const noexcept { return title_; }
    const std::vector<Section> &Notebook::sections() const noexcept { return sections_; }

    bool Notebook::add_section(std::string id, std::string title)
    {
        if (id.empty() || std::any_of(sections_.begin(), sections_.end(),
                                      [&](const Section &section)
                                      { return section.id == id; }))
        {
            return false;
        }
        sections_.push_back({std::move(id), std::move(title), {}});
        return true;
    }

    bool Notebook::add_page(const std::string &section_id, std::string id, std::string title)
    {
        if (id.empty())
        {
            return false;
        }
        auto section = std::find_if(sections_.begin(), sections_.end(),
                                    [&](const Section &item)
                                    { return item.id == section_id; });
        if (section == sections_.end())
        {
            return false;
        }
        const bool duplicate = std::any_of(sections_.begin(), sections_.end(),
                                           [&](const Section &item)
                                           {
                                               return std::any_of(item.pages.begin(), item.pages.end(),
                                                                  [&](const Page &page)
                                                                  { return page.id == id; });
                                           });
        if (duplicate)
        {
            return false;
        }
        section->pages.push_back({std::move(id), std::move(title)});
        return true;
    }

} // namespace mtn::model
