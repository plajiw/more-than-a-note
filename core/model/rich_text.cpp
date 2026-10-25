#include "rich_text.h"

#include <limits>

namespace mtn::model {
namespace {
constexpr std::size_t max_text_bytes = 16u * 1024u * 1024u;
constexpr std::size_t max_paragraphs = 100'000;
constexpr std::size_t max_runs = 100'000;

bool link_valid(const std::string& link) noexcept {
    if (link.size() > 4096) return false;
    if (link.starts_with("https://") || link.starts_with("http://")) {
        const auto host_start = link.starts_with("https://") ? 8u : 7u;
        if (host_start >= link.size() || link.find_first_of("/?#", host_start) == host_start)
            return false;
    } else if (link.starts_with("mailto:")) {
        const auto at = link.find('@', 7);
        if (at == std::string::npos || at == 7 || at + 1 == link.size()) return false;
    } else return false;
    for (const unsigned char c : link)
        if (c <= 0x20 || c >= 0x7f) return false;
    return true;
}

std::size_t add(std::size_t a, std::size_t b) noexcept {
    const auto max = std::numeric_limits<std::size_t>::max();
    return b > max - a ? max : a + b;
}
} // namespace

bool valid_rgba_color(std::string_view color) noexcept {
    if (color.size() != 9 || color[0] != '#') return false;
    for (std::size_t i = 1; i < color.size(); ++i) {
        const auto c = color[i];
        if (!((c >= '0' && c <= '9') || (c >= 'A' && c <= 'F'))) return false;
    }
    return true;
}

bool valid_utf8(std::string_view text, bool allow_line_breaks) noexcept {
    for (std::size_t i = 0; i < text.size();) {
        const auto first = static_cast<unsigned char>(text[i]);
        if (first < 0x80) {
            if (first == 0 || first == 0x7f ||
                (first < 0x20 && !(allow_line_breaks && (first == '\n' || first == '\t'))))
                return false;
            ++i;
            continue;
        }
        std::size_t count = 0;
        std::uint32_t scalar = 0;
        if (first >= 0xc2 && first <= 0xdf) { count = 2; scalar = first & 0x1f; }
        else if (first >= 0xe0 && first <= 0xef) { count = 3; scalar = first & 0x0f; }
        else if (first >= 0xf0 && first <= 0xf4) { count = 4; scalar = first & 0x07; }
        else return false;
        if (count > text.size() - i) return false;
        for (std::size_t j = 1; j < count; ++j) {
            const auto next = static_cast<unsigned char>(text[i + j]);
            if ((next & 0xc0) != 0x80) return false;
            scalar = (scalar << 6) | (next & 0x3f);
        }
        if ((count == 3 && scalar < 0x800) || (count == 4 && scalar < 0x10000) ||
            (scalar >= 0xd800 && scalar <= 0xdfff) || scalar > 0x10ffff ||
            (scalar >= 0x80 && scalar <= 0x9f)) return false;
        i += count;
    }
    return true;
}

TextValidation validate_rich_text(const RichTextDocument& document) noexcept {
    if (document.paragraphs.size() > max_paragraphs) return TextValidation::TooLarge;
    std::size_t bytes = 0;
    std::size_t runs = 0;
    for (const auto& paragraph : document.paragraphs) {
        if (paragraph.kind > ParagraphKind::Heading3 || paragraph.list > ListKind::Numbered ||
            (paragraph.list == ListKind::None ? paragraph.list_level != 0 :
             paragraph.list_level == 0 || paragraph.list_level > 8))
            return TextValidation::InvalidStructure;
        runs = add(runs, paragraph.runs.size());
        if (runs > max_runs) return TextValidation::TooLarge;
        for (const auto& run : paragraph.runs) {
            bytes = add(bytes, run.utf8.size());
            if (!valid_utf8(run.utf8)) return TextValidation::InvalidUtf8;
            if ((run.style.color && !valid_rgba_color(*run.style.color)) ||
                (run.style.highlight && !valid_rgba_color(*run.style.highlight)) ||
                (run.style.link && !link_valid(*run.style.link)))
                return TextValidation::InvalidStyle;
            if (run.style.link) bytes = add(bytes, run.style.link->size());
            if (bytes > max_text_bytes) return TextValidation::TooLarge;
        }
    }
    return TextValidation::Valid;
}

std::size_t text_storage_bytes(const RichTextDocument& document) noexcept {
    const auto max = std::numeric_limits<std::size_t>::max();
    std::size_t bytes = document.paragraphs.capacity() > max / sizeof(RichParagraph)
        ? max : document.paragraphs.capacity() * sizeof(RichParagraph);
    for (const auto& paragraph : document.paragraphs) {
        bytes = add(bytes, paragraph.runs.capacity() > max / sizeof(TextRun)
            ? max : paragraph.runs.capacity() * sizeof(TextRun));
        for (const auto& run : paragraph.runs) {
            bytes = add(bytes, run.utf8.capacity());
            if (run.style.color) bytes = add(bytes, run.style.color->capacity());
            if (run.style.highlight) bytes = add(bytes, run.style.highlight->capacity());
            if (run.style.link) bytes = add(bytes, run.style.link->capacity());
        }
    }
    return bytes;
}

} // namespace mtn::model
