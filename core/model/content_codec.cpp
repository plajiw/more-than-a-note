#include "content_codec.h"

#include <bit>
#include <cstring>
#include <limits>
#include <new>
#include <optional>
#include <string_view>

namespace mtn::model {
namespace {
constexpr std::size_t max_text_blob = 32u * 1024u * 1024u;
constexpr std::size_t max_ink_blob = 16u * 1024u * 1024u;
constexpr std::uint16_t le_marker = 0x454c; // bytes 'L', 'E'
static_assert(sizeof(double) == 8 && std::numeric_limits<double>::is_iec559);

class Writer {
public:
    Writer(std::size_t limit, std::size_t expected) : limit_(limit) {
        data_.reserve(expected);
    }
    bool u8(std::uint8_t n) { return raw(&n, 1); }
    bool u16(std::uint16_t n) {
        const std::uint8_t b[] = {static_cast<std::uint8_t>(n),
                                  static_cast<std::uint8_t>(n >> 8)};
        return raw(b, 2);
    }
    bool u32(std::uint32_t n) {
        for (unsigned shift = 0; shift < 32; shift += 8)
            if (!u8(static_cast<std::uint8_t>(n >> shift))) return false;
        return true;
    }
    bool f64(double n) {
        const auto bits = std::bit_cast<std::uint64_t>(n);
        for (unsigned shift = 0; shift < 64; shift += 8)
            if (!u8(static_cast<std::uint8_t>(bits >> shift))) return false;
        return true;
    }
    bool raw(const void* ptr, std::size_t count) {
        if (count > limit_ - data_.size()) return false;
        if (count == 0) return true;
        const auto* first = static_cast<const std::uint8_t*>(ptr);
        data_.insert(data_.end(), first, first + count);
        return true;
    }
    bool string(const std::string& text) {
        return text.size() <= std::numeric_limits<std::uint32_t>::max() &&
               u32(static_cast<std::uint32_t>(text.size())) &&
               raw(text.data(), text.size());
    }
    std::vector<std::uint8_t> finish() && { return std::move(data_); }
private:
    std::size_t limit_;
    std::vector<std::uint8_t> data_;
};

class Reader {
public:
    explicit Reader(std::span<const std::uint8_t> data) : data_(data) {}
    bool u8(std::uint8_t& out) {
        if (remaining() < 1) return false;
        out = data_[pos_++]; return true;
    }
    bool u16(std::uint16_t& out) {
        std::uint8_t a, b;
        if (!u8(a) || !u8(b)) return false;
        out = static_cast<std::uint16_t>(a | (static_cast<unsigned>(b) << 8));
        return true;
    }
    bool u32(std::uint32_t& out) {
        out = 0;
        for (unsigned shift = 0; shift < 32; shift += 8) {
            std::uint8_t byte;
            if (!u8(byte)) return false;
            out |= static_cast<std::uint32_t>(byte) << shift;
        }
        return true;
    }
    bool f64(double& out) {
        std::uint64_t bits = 0;
        for (unsigned shift = 0; shift < 64; shift += 8) {
            std::uint8_t byte;
            if (!u8(byte)) return false;
            bits |= static_cast<std::uint64_t>(byte) << shift;
        }
        out = std::bit_cast<double>(bits);
        return true;
    }
    bool raw(void* ptr, std::size_t count) {
        if (remaining() < count) return false;
        if (count) std::memcpy(ptr, data_.data() + pos_, count);
        pos_ += count; return true;
    }
    bool string(std::string& out, std::size_t max_length) {
        std::uint32_t count;
        if (!u32(count) || count > max_length || remaining() < count) return false;
        out.assign(reinterpret_cast<const char*>(data_.data() + pos_), count);
        pos_ += count; return true;
    }
    std::size_t remaining() const noexcept { return data_.size() - pos_; }
private:
    std::span<const std::uint8_t> data_;
    std::size_t pos_ = 0;
};

bool header(Writer& out, const char* magic, std::uint32_t count) {
    return out.raw(magic, 4) && out.u16(1) && out.u16(le_marker) &&
           out.u32(0) && out.u32(count);
}

CodecStatus read_header(Reader& in, const char* magic, std::uint32_t& count) {
    char actual[4];
    std::uint16_t version, endian;
    std::uint32_t flags;
    if (!in.raw(actual, 4) || std::memcmp(actual, magic, 4) != 0 ||
        !in.u16(version) || !in.u16(endian) || !in.u32(flags) || !in.u32(count))
        return CodecStatus::InvalidData;
    if (version != 1) return CodecStatus::UnsupportedVersion;
    return endian == le_marker && flags == 0 ? CodecStatus::Ok : CodecStatus::InvalidData;
}

} // namespace

EncodedContent encode_text_v1(const RichTextDocument& document) {
    const auto validation = validate_rich_text(document);
    if (validation != TextValidation::Valid)
        return {validation == TextValidation::TooLarge ? CodecStatus::LimitExceeded :
            CodecStatus::InvalidData, {}};
    std::size_t expected = 16;
    for (const auto& paragraph : document.paragraphs) {
        expected += 8;
        for (const auto& run : paragraph.runs)
            expected += 5 + run.utf8.size() + (run.style.color ? 9 : 0) +
                (run.style.highlight ? 9 : 0) +
                (run.style.link ? 4 + run.style.link->size() : 0);
    }
    if (expected > max_text_blob) return {CodecStatus::LimitExceeded, {}};
    try {
        Writer out(max_text_blob, expected);
        if (!header(out, "MTNT", static_cast<std::uint32_t>(document.paragraphs.size())))
            return {CodecStatus::LimitExceeded, {}};
        for (const auto& paragraph : document.paragraphs) {
            if (!out.u8(static_cast<std::uint8_t>(paragraph.kind)) ||
                !out.u8(static_cast<std::uint8_t>(paragraph.list)) ||
                !out.u8(paragraph.list_level) || !out.u8(0) ||
                !out.u32(static_cast<std::uint32_t>(paragraph.runs.size())))
                return {CodecStatus::LimitExceeded, {}};
            for (const auto& run : paragraph.runs) {
                const auto& s = run.style;
                const std::uint8_t flags = (s.bold ? 1 : 0) | (s.italic ? 2 : 0) |
                    (s.underline ? 4 : 0) | (s.color ? 8 : 0) |
                    (s.highlight ? 16 : 0) | (s.link ? 32 : 0);
                if (!out.u8(flags) || !out.string(run.utf8) ||
                    (s.color && !out.raw(s.color->data(), 9)) ||
                    (s.highlight && !out.raw(s.highlight->data(), 9)) ||
                    (s.link && !out.string(*s.link)))
                    return {CodecStatus::LimitExceeded, {}};
            }
        }
        return {CodecStatus::Ok, std::move(out).finish()};
    } catch (const std::bad_alloc&) { return {CodecStatus::OutOfMemory, {}}; }
}

DecodedContent<RichTextDocument> decode_text_v1(std::span<const std::uint8_t> bytes) {
    if (bytes.size() > max_text_blob) return {CodecStatus::LimitExceeded, {}};
    try {
        Reader in(bytes);
        std::uint32_t count = 0;
        const auto status = read_header(in, "MTNT", count);
        if (status != CodecStatus::Ok) return {status, {}};
        if (count > 100'000 || count > in.remaining() / 8)
            return {CodecStatus::InvalidData, {}};
        RichTextDocument document;
        document.paragraphs.reserve(count);
        std::size_t total_runs = 0;
        for (std::uint32_t p = 0; p < count; ++p) {
            std::uint8_t kind, list, level, reserved;
            std::uint32_t run_count;
            if (!in.u8(kind) || !in.u8(list) || !in.u8(level) || !in.u8(reserved) ||
                reserved != 0 || !in.u32(run_count) || run_count > 100'000 - total_runs ||
                run_count > in.remaining() / 5)
                return {CodecStatus::InvalidData, {}};
            total_runs += run_count;
            RichParagraph paragraph;
            paragraph.kind = static_cast<ParagraphKind>(kind);
            paragraph.list = static_cast<ListKind>(list);
            paragraph.list_level = level;
            paragraph.runs.reserve(run_count);
            for (std::uint32_t r = 0; r < run_count; ++r) {
                std::uint8_t flags;
                TextRun run;
                if (!in.u8(flags) || (flags & ~std::uint8_t{0x3f}) ||
                    !in.string(run.utf8, 16u * 1024u * 1024u))
                    return {CodecStatus::InvalidData, {}};
                run.style.bold = flags & 1;
                run.style.italic = flags & 2;
                run.style.underline = flags & 4;
                if (flags & 8) {
                    std::string value(9, '\0');
                    if (!in.raw(value.data(), 9)) return {CodecStatus::InvalidData, {}};
                    run.style.color = std::move(value);
                }
                if (flags & 16) {
                    std::string value(9, '\0');
                    if (!in.raw(value.data(), 9)) return {CodecStatus::InvalidData, {}};
                    run.style.highlight = std::move(value);
                }
                if (flags & 32) {
                    std::string value;
                    if (!in.string(value, 4096)) return {CodecStatus::InvalidData, {}};
                    run.style.link = std::move(value);
                }
                paragraph.runs.push_back(std::move(run));
            }
            document.paragraphs.push_back(std::move(paragraph));
        }
        if (in.remaining() || validate_rich_text(document) != TextValidation::Valid)
            return {CodecStatus::InvalidData, {}};
        return {CodecStatus::Ok, std::move(document)};
    } catch (const std::bad_alloc&) { return {CodecStatus::OutOfMemory, {}}; }
}

EncodedContent encode_ink_v1(const InkStroke& stroke) {
    if (!valid_ink_stroke(stroke)) return {};
    std::size_t expected = 34;
    for (const auto& point : stroke.points)
        expected += 17 + 8 * (static_cast<int>(point.pressure.has_value()) +
            static_cast<int>(point.relative_time_ms.has_value()) +
            static_cast<int>(point.tilt_x.has_value()) +
            static_cast<int>(point.tilt_y.has_value()));
    if (expected > max_ink_blob) return {CodecStatus::LimitExceeded, {}};
    try {
        Writer out(max_ink_blob, expected);
        if (!header(out, "MTNI", static_cast<std::uint32_t>(stroke.points.size())) ||
            !out.f64(stroke.base_width_pt) ||
            !out.u8(static_cast<std::uint8_t>(stroke.brush)) ||
            !out.raw(stroke.color.data(), 9)) return {CodecStatus::LimitExceeded, {}};
        for (const auto& point : stroke.points) {
            const std::uint8_t flags = (point.pressure ? 1 : 0) |
                (point.relative_time_ms ? 2 : 0) | (point.tilt_x ? 4 : 0) |
                (point.tilt_y ? 8 : 0);
            if (!out.f64(point.position.x) || !out.f64(point.position.y) || !out.u8(flags) ||
                (point.pressure && !out.f64(*point.pressure)) ||
                (point.relative_time_ms && !out.f64(*point.relative_time_ms)) ||
                (point.tilt_x && !out.f64(*point.tilt_x)) ||
                (point.tilt_y && !out.f64(*point.tilt_y)))
                return {CodecStatus::LimitExceeded, {}};
        }
        return {CodecStatus::Ok, std::move(out).finish()};
    } catch (const std::bad_alloc&) { return {CodecStatus::OutOfMemory, {}}; }
}

DecodedContent<InkStroke> decode_ink_v1(std::span<const std::uint8_t> bytes) {
    if (bytes.size() > max_ink_blob) return {CodecStatus::LimitExceeded, {}};
    try {
        Reader in(bytes);
        std::uint32_t count = 0;
        const auto status = read_header(in, "MTNI", count);
        if (status != CodecStatus::Ok) return {status, {}};
        InkStroke stroke;
        std::uint8_t brush;
        std::string color(9, '\0');
        if (!in.f64(stroke.base_width_pt) || !in.u8(brush) || !in.raw(color.data(), 9) ||
            count == 0 || count > 250'000 ||
            count > in.remaining() / 17) return {CodecStatus::InvalidData, {}};
        stroke.brush = static_cast<InkBrush>(brush);
        stroke.color = std::move(color);
        stroke.points.reserve(count);
        for (std::uint32_t i = 0; i < count; ++i) {
            InkPoint point;
            std::uint8_t flags;
            if (!in.f64(point.position.x) || !in.f64(point.position.y) ||
                !in.u8(flags) || (flags & ~std::uint8_t{0x0f}))
                return {CodecStatus::InvalidData, {}};
            if (flags & 1) { double n; if (!in.f64(n)) return {CodecStatus::InvalidData, {}}; point.pressure = n; }
            if (flags & 2) { double n; if (!in.f64(n)) return {CodecStatus::InvalidData, {}}; point.relative_time_ms = n; }
            if (flags & 4) { double n; if (!in.f64(n)) return {CodecStatus::InvalidData, {}}; point.tilt_x = n; }
            if (flags & 8) { double n; if (!in.f64(n)) return {CodecStatus::InvalidData, {}}; point.tilt_y = n; }
            stroke.points.push_back(std::move(point));
        }
        if (in.remaining() || !valid_ink_stroke(stroke)) return {CodecStatus::InvalidData, {}};
        return {CodecStatus::Ok, std::move(stroke)};
    } catch (const std::bad_alloc&) { return {CodecStatus::OutOfMemory, {}}; }
}

} // namespace mtn::model
