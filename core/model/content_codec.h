#pragma once

#include "page_content.h"

#include <cstdint>
#include <span>
#include <vector>

namespace mtn::model {

enum class CodecStatus { Ok, InvalidData, UnsupportedVersion, LimitExceeded, OutOfMemory };

struct EncodedContent {
    CodecStatus status = CodecStatus::InvalidData;
    std::vector<std::uint8_t> bytes;
};

template <typename T>
struct DecodedContent {
    CodecStatus status = CodecStatus::InvalidData;
    T value;
};

// Binary formats are independent of Qt, host endian and size_t. Each has a
// magic, version, LE marker, reserved flags and bounded counts. Decoded object
// memory can exceed blob size, but counts and blob size both have fixed caps.
EncodedContent encode_text_v1(const RichTextDocument& document);
DecodedContent<RichTextDocument> decode_text_v1(std::span<const std::uint8_t> bytes);
EncodedContent encode_text_v2(const RichTextDocument& document);
DecodedContent<RichTextDocument> decode_text(std::span<const std::uint8_t> bytes);
EncodedContent encode_ink_v1(const InkStroke& stroke);
DecodedContent<InkStroke> decode_ink_v1(std::span<const std::uint8_t> bytes);

} // namespace mtn::model
