#include "asset_record.h"

#include "page_content.h"
#include "rich_text.h"

namespace mtn::model {

AssetValidation validate_asset(const AssetRecord& asset) noexcept {
    if (!valid_uuid(asset.id)) return AssetValidation::InvalidId;
    if (asset.sha256.size() != 64) return AssetValidation::InvalidHash;
    for (const char c : asset.sha256)
        if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')))
            return AssetValidation::InvalidHash;
    if ((asset.kind == AssetKind::SvgImage && asset.mime != "image/svg+xml") ||
        (asset.kind == AssetKind::RasterImage && asset.mime != "image/png" &&
         asset.mime != "image/jpeg" && asset.mime != "image/webp") ||
        (asset.kind != AssetKind::SvgImage && asset.kind != AssetKind::RasterImage))
        return AssetValidation::InvalidMime;
    if (asset.byte_size == 0 || asset.byte_size > 256ull * 1024ull * 1024ull)
        return AssetValidation::InvalidSize;
    if (!asset.width_px || !asset.height_px || asset.width_px > 32768 ||
        asset.height_px > 32768 ||
        static_cast<std::uint64_t>(asset.width_px) * asset.height_px > 128'000'000)
        return AssetValidation::InvalidDimensions;
    if (asset.source_name.empty() || asset.source_name.size() > 255 ||
        asset.source_name == "." || asset.source_name == ".." ||
        asset.source_name.find('/') != std::string::npos ||
        asset.source_name.find('\\') != std::string::npos ||
        !valid_utf8(asset.source_name, false))
        return AssetValidation::InvalidName;
    return AssetValidation::Valid;
}

std::optional<std::string> asset_relative_path(const AssetRecord& asset) {
    if (validate_asset(asset) != AssetValidation::Valid) return std::nullopt;
    const char* extension = asset.mime == "image/png" ? ".png" :
        asset.mime == "image/jpeg" ? ".jpg" :
        asset.mime == "image/webp" ? ".webp" : ".svg";
    return "assets/" + asset.sha256.substr(0, 2) + "/" + asset.sha256 + extension;
}

} // namespace mtn::model
