#!/usr/bin/env python3
"""
Packages the iCleanerPro bundle structure into iCleanerPro.ipa (standard ZIP with Payload/iCleanerPro.app/).
Generates iOS icon sizes (120x120, 180x180, 152x152) for CFBundleIcons so Feather / ESign display the app icon properly.
Note: Compiling Swift/SwiftUI into an arm64 Mach-O binary (`Payload/iCleanerPro.app/iCleanerPro`) requires
macOS + Xcode iOS SDK (use `.github/workflows/build-ipa.yml` or `scripts/build_ipa.sh` on macOS).
"""

import math
import plistlib
import struct
import zipfile
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP_SRC = ROOT / "iCleanerPro"
OUT_IPA = ROOT / "iCleanerPro.ipa"


def render_icon_png(size: int) -> bytes:
    rows = []
    for y in range(size):
        row = bytearray([0])
        ny = y / max(1, size - 1)
        for x in range(size):
            nx = x / max(1, size - 1)
            r = int(24 * (1 - nx) + 16 * nx + 10 * ny)
            g = int(105 * (1 - nx) + 185 * nx)
            b = int(248 * (1 - ny) + 215 * ny)
            dx = nx - 0.5
            dy = ny - 0.5
            dist = math.hypot(dx, dy)
            if 0.27 <= dist <= 0.33:
                r, g, b = 255, 255, 255
            elif dist < 0.22 and (abs(dx) + abs(dy) * 0.45 < 0.14 or abs(dy) + abs(dx) * 0.45 < 0.14):
                r, g, b = 255, 255, 255
            row.extend((max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b))))
        rows.append(bytes(row))
    raw = b"".join(rows)

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack("!I", len(data)) + tag + data + struct.pack("!I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack("!IIBBBBB", size, size, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 6))
        + chunk(b"IEND", b"")
    )


def build_resolved_info_plist() -> bytes:
    with (APP_SRC / "Info.plist").open("rb") as f:
        info = plistlib.load(f)

    info["CFBundleExecutable"] = "iCleanerPro"
    info["CFBundleIdentifier"] = "com.icleanerpro.app"
    info["CFBundleName"] = "iCleanerPro"
    info["CFBundlePackageType"] = "APPL"
    info["MinimumOSVersion"] = "16.0"
    info["UIDeviceFamily"] = [1, 2]
    info["CFBundleSupportedPlatforms"] = ["iPhoneOS"]

    return plistlib.dumps(info, fmt=plistlib.FMT_XML)


def main() -> None:
    app_prefix = "Payload/iCleanerPro.app"

    with zipfile.ZipFile(OUT_IPA, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        # 1. Resolved Info.plist & PkgInfo
        zf.writestr(f"{app_prefix}/Info.plist", build_resolved_info_plist())
        zf.writestr(f"{app_prefix}/PkgInfo", b"APPL????")

        # 2. AppIcon variants referenced by CFBundleIcons & Localization
        zf.writestr(f"{app_prefix}/AppIcon60x60@2x.png", render_icon_png(120))
        zf.writestr(f"{app_prefix}/AppIcon60x60@3x.png", render_icon_png(180))
        zf.writestr(f"{app_prefix}/AppIcon76x76@2x~ipad.png", render_icon_png(152))

        icon_path = APP_SRC / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon-1024.png"
        if icon_path.exists():
            zf.write(icon_path, f"{app_prefix}/AppIcon-1024.png")

        strings_path = APP_SRC / "Resources" / "Localizable.strings"
        if strings_path.exists():
            zf.write(strings_path, f"{app_prefix}/vi.lproj/Localizable.strings")

        # 3. Self-contained SourceBundle
        for path in sorted(APP_SRC.rglob("*")):
            if path.is_file():
                rel = path.relative_to(ROOT).as_posix()
                zf.write(path, f"{app_prefix}/SourceBundle/{rel}")

        xcodeproj_dir = ROOT / "iCleanerPro.xcodeproj"
        for path in sorted(xcodeproj_dir.rglob("*")):
            if path.is_file():
                rel = path.relative_to(ROOT).as_posix()
                zf.write(path, f"{app_prefix}/SourceBundle/{rel}")

        for extra_rel in [
            "ExportOptions.plist",
            "project.yml",
            "scripts/build_ipa.sh",
            "ARCHITECTURE_AND_IPA_GUIDE.md",
        ]:
            extra_path = ROOT / extra_rel
            if extra_path.exists():
                zf.write(extra_path, f"{app_prefix}/SourceBundle/{extra_rel}")

    # Verify archive structure
    with zipfile.ZipFile(OUT_IPA, "r") as zf:
        bad = zf.testzip()
        if bad is not None:
            raise RuntimeError(f"Corrupted zip entry: {bad}")
        names = zf.namelist()
        assert f"{app_prefix}/Info.plist" in names
        assert f"{app_prefix}/PkgInfo" in names
        assert f"{app_prefix}/AppIcon60x60@2x.png" in names
        assert f"{app_prefix}/AppIcon60x60@3x.png" in names
        plist_check = plistlib.loads(zf.read(f"{app_prefix}/Info.plist"))
        assert plist_check["CFBundleIdentifier"] == "com.icleanerpro.app"
        assert plist_check["MinimumOSVersion"] == "16.0"

    size_kb = OUT_IPA.stat().st_size / 1024.0
    print(f"Created {OUT_IPA} ({size_kb:.1f} KB), entries: {len(names)}, ZIP integrity OK.")


if __name__ == "__main__":
    main()
