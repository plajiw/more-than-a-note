#pragma once

#include <string>
#include <vector>

namespace mtn::model
{

    struct Page
    {
        std::string id;
        std::string title;
    };

    struct Section
    {
        std::string id;
        std::string title;
        std::vector<Page> pages;
    };

    class Notebook
    {
    public:
        Notebook(std::string id, std::string title);

        const std::string &id() const noexcept;
        const std::string &title() const noexcept;
        const std::vector<Section> &sections() const noexcept;

        bool add_section(std::string id, std::string title);
        bool add_page(const std::string &section_id, std::string id, std::string title);

    private:
        std::string id_;
        std::string title_;
        std::vector<Section> sections_;
    };

} // namespace mtn::model
