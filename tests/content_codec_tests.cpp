#include "asset_record.h"
#include "content_codec.h"
#include "page_content.h"

#include <cmath>
#include <cstdint>
#include <iostream>
#include <limits>
#include <string>
#include <vector>

#define CHECK(condition) do { if (!(condition)) { \
    std::cerr << "Check failed: " #condition " at line " << __LINE__ << '\n'; \
    return 1; \
} } while (false)

int main() {
    using namespace mtn::model;
    const auto empty = encode_text_v1({});
    CHECK(empty.status == CodecStatus::Ok);
    const std::vector<std::uint8_t> emptyGolden = {
        'M', 'T', 'N', 'T', 1, 0, 'L', 'E', 0, 0, 0, 0, 0, 0, 0, 0};
    CHECK(empty.bytes == emptyGolden);
    CHECK(decode_text_v1(empty.bytes).status == CodecStatus::Ok);

    RichTextDocument document;
    RichParagraph first;
    first.kind = ParagraphKind::Heading2;
    first.runs.push_back({"Olá 👩🏽‍💻, שלום\nlinha 2", {true, false, true,
        std::string("#336699FF"), {}, std::string("https://example.org/a?b=1")}});
    document.paragraphs.push_back(std::move(first));
    RichParagraph list;
    list.list = ListKind::Numbered;
    list.list_level = 2;
    list.runs.push_back({"item", {false, true, false, {}, std::string("#FFFF00AA"), {}}});
    document.paragraphs.push_back(std::move(list));
    CHECK(validate_rich_text(document) == TextValidation::Valid);
    auto encoded = encode_text_v1(document);
    CHECK(encoded.status == CodecStatus::Ok);
    auto decoded = decode_text_v1(encoded.bytes);
    CHECK(decoded.status == CodecStatus::Ok);
    CHECK(decoded.value.paragraphs.size() == 2);
    CHECK(decoded.value.paragraphs[0].runs[0].utf8 == document.paragraphs[0].runs[0].utf8);
    CHECK(decoded.value.paragraphs[0].runs[0].style.link ==
          document.paragraphs[0].runs[0].style.link);
    CHECK(decoded.value.paragraphs[1].list_level == 2);
    CHECK(encode_text_v1(decoded.value).bytes == encoded.bytes);
    auto malformed = encoded.bytes;
    malformed[4] = 2;
    CHECK(decode_text_v1(malformed).status == CodecStatus::UnsupportedVersion);
    malformed = encoded.bytes;
    malformed[6] = 'B';
    CHECK(decode_text_v1(malformed).status == CodecStatus::InvalidData);
    malformed = encoded.bytes;
    malformed.pop_back();
    CHECK(decode_text_v1(malformed).status == CodecStatus::InvalidData);
    for (std::size_t size = 0; size < encoded.bytes.size(); ++size)
        CHECK(decode_text_v1(std::span<const std::uint8_t>(encoded.bytes.data(), size)).status !=
              CodecStatus::Ok);
    malformed = encoded.bytes;
    malformed.push_back(0);
    CHECK(decode_text_v1(malformed).status == CodecStatus::InvalidData);
    malformed = encoded.bytes;
    malformed[12] = 255; malformed[13] = 255; malformed[14] = 255; malformed[15] = 127;
    CHECK(decode_text_v1(malformed).status == CodecStatus::InvalidData);
    document.paragraphs[0].runs[0].utf8 = std::string("\xc0\xaf", 2);
    CHECK(validate_rich_text(document) == TextValidation::InvalidUtf8);
    CHECK(encode_text_v1(document).status == CodecStatus::InvalidData);
    document.paragraphs[0].runs[0].utf8 = "safe";
    document.paragraphs[0].runs[0].style.link = "javascript:alert(1)";
    CHECK(validate_rich_text(document) == TextValidation::InvalidStyle);

    InkStroke stroke;
    stroke.base_width_pt = 1.25;
    stroke.brush = InkBrush::Highlighter;
    stroke.color = "#FFCC0080";
    stroke.points = {{{-1.5, 2.75}, {}, {}, {}, {}},
                     {{3.5, -4.25}, 0.75, 12.5, -15.0, 30.0}};
    auto inkBytes = encode_ink_v1(stroke);
    CHECK(inkBytes.status == CodecStatus::Ok);
    CHECK(inkBytes.bytes.size() == 34 + 17 + 49);
    CHECK(inkBytes.bytes[0] == 'M' && inkBytes.bytes[3] == 'I');
    auto ink = decode_ink_v1(inkBytes.bytes);
    CHECK(ink.status == CodecStatus::Ok);
    CHECK(ink.value.points[0].position.x == -1.5);
    CHECK(!ink.value.points[0].pressure);
    CHECK(ink.value.points[1].pressure == 0.75);
    CHECK(ink.value.points[1].tilt_y == 30.0);
    CHECK(ink.value.brush == InkBrush::Highlighter);
    CHECK(ink.value.color == "#FFCC0080");
    CHECK(encode_ink_v1(ink.value).bytes == inkBytes.bytes);
    malformed = inkBytes.bytes;
    malformed[12] = 255; malformed[13] = 255; malformed[14] = 255; malformed[15] = 127;
    CHECK(decode_ink_v1(malformed).status == CodecStatus::InvalidData);
    malformed = inkBytes.bytes;
    malformed[50] = 0x80; // unknown flags on first point
    CHECK(decode_ink_v1(malformed).status == CodecStatus::InvalidData);
    malformed = inkBytes.bytes;
    malformed.pop_back();
    CHECK(decode_ink_v1(malformed).status == CodecStatus::InvalidData);
    for (std::size_t size = 0; size < inkBytes.bytes.size(); ++size)
        CHECK(decode_ink_v1(std::span<const std::uint8_t>(inkBytes.bytes.data(), size)).status !=
              CodecStatus::Ok);
    stroke.points[1].pressure = std::numeric_limits<double>::quiet_NaN();
    CHECK(encode_ink_v1(stroke).status == CodecStatus::InvalidData);

    AssetRecord asset{"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", AssetKind::SvgImage,
        std::string(64, 'a'), "image/svg+xml", 4096, 800, 600, "gráfico.svg"};
    CHECK(validate_asset(asset) == AssetValidation::Valid);
    CHECK(asset_relative_path(asset) ==
          "assets/aa/" + std::string(64, 'a') + ".svg");
    asset.source_name = "../outside.svg";
    CHECK(validate_asset(asset) == AssetValidation::InvalidName);
    CHECK(!asset_relative_path(asset));
    asset.source_name = "safe.svg";
    asset.width_px = 100'000;
    CHECK(validate_asset(asset) == AssetValidation::InvalidDimensions);

    PageObject text;
    text.common.id = "22222222-2222-4222-8222-222222222222";
    text.common.page_id = "11111111-1111-4111-8111-111111111111";
    TextContainer container;
    container.document.paragraphs.push_back({});
    container.document.paragraphs[0].runs.push_back({"\xc0\xaf", {}});
    text.payload = std::move(container);
    CHECK(!validate_page({text.common.page_id, {text}}).empty());
    return 0;
}
