#pragma once

#include <cstdint>
#include <optional>
#include <string>

namespace mtn::model {

enum class AssetKind { RasterImage, SvgImage };

struct AssetRecord {
    std::string id;            // UUID, stable object reference
    AssetKind kind = AssetKind::RasterImage;
    std::string sha256;        // lowercase hex of original bytes
    std::string mime;          // supported image MIME
    std::uint64_t byte_size = 0;
    std::uint32_t width_px = 0;
    std::uint32_t height_px = 0;
    std::string source_name;   // display-only basename, never used as a path
};

enum class AssetValidation { Valid, InvalidId, InvalidHash, InvalidMime,
                             InvalidSize, InvalidDimensions, InvalidName };

AssetValidation validate_asset(const AssetRecord& asset) noexcept;
// A managed path derived solely from a checked hash and MIME. Importers must
// verify the actual file hash and decode limits before persisting metadata.
std::optional<std::string> asset_relative_path(const AssetRecord& asset);

} // namespace mtn::model
