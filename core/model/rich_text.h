#pragma once

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace mtn::model {

enum class ParagraphKind : std::uint8_t { Body, Heading1, Heading2, Heading3 };
enum class ListKind : std::uint8_t { None, Bullet, Numbered };

struct TextStyle {
    friend bool operator==(const TextStyle&, const TextStyle&) = default;
    bool bold = false;
    bool italic = false;
    bool underline = false;
    std::optional<std::string> color;      // canonical #RRGGBBAA
    std::optional<std::string> highlight;  // canonical #RRGGBBAA
    std::optional<std::string> link;       // absolute http(s) or mailto URL
    std::optional<std::string> font_family; // bundled families only
    std::optional<double> font_size_pt;
};

struct TextRun {
    friend bool operator==(const TextRun&, const TextRun&) = default;
    std::string utf8;
    TextStyle style;
};

struct RichParagraph {
    friend bool operator==(const RichParagraph&, const RichParagraph&) = default;
    ParagraphKind kind = ParagraphKind::Body;
    ListKind list = ListKind::None;
    std::uint8_t list_level = 0; // 0 without list; 1..8 with list
    std::vector<TextRun> runs;
};

struct RichTextDocument {
    friend bool operator==(const RichTextDocument&, const RichTextDocument&) = default;
    std::vector<RichParagraph> paragraphs; // empty document is valid
};

enum class TextValidation { Valid, InvalidUtf8, InvalidStructure, InvalidStyle, TooLarge };

// UTF-8 is preserved byte for byte; adapters convert CRLF to LF before creating
// a run. No NFC rewrite is performed, so combining characters remain intact.
bool valid_utf8(std::string_view text, bool allow_line_breaks = true) noexcept;
bool valid_rgba_color(std::string_view color) noexcept;
TextValidation validate_rich_text(const RichTextDocument& document) noexcept;
std::size_t text_storage_bytes(const RichTextDocument& document) noexcept;

} // namespace mtn::model
