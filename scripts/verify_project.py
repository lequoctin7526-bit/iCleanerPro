#!/usr/bin/env python3
"""
Verifies the structural integrity of BoosterPro Xcode project:
1. Every .swift file under BoosterPro/ and BoosterProTests/ is registered in project.pbxproj.
2. Info.plist and ExportOptions.plist are valid XML plists with required privacy & deployment settings.
3. All Assets.xcassets JSON files are valid JSON.
4. All Swift files have balanced delimiters ({} () []) and zero forbidden private API calls.
"""

import json
import os
import plistlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP_DIR = ROOT / "BoosterPro"
TEST_DIR = ROOT / "BoosterProTests"
PBXPROJ = ROOT / "BoosterPro.xcodeproj" / "project.pbxproj"

FORBIDDEN_PATTERNS = [
    r"\bdlopen\s*\(",
    r"\bdlsym\s*\(",
    r"LSApplicationWorkspace",
    r"SpringBoardServices",
    r"MobileInstallation",
    r"NSSelectorFromString\s*\(\s*\"_",
]


def strip_swift_strings_and_comments(code: str) -> str:
    # Remove single-line comments, multi-line comments, and string literals for delimiter checking
    pattern = re.compile(
        r'//.*?$|/\*.*?\*/|"(?:\\.|[^"\\])*"',
        re.DOTALL | re.MULTILINE,
    )
    return pattern.sub(" ", code)


def check_balanced_delimiters(path: Path, text: str) -> list[str]:
    errors = []
    cleaned = strip_swift_strings_and_comments(text)
    pairs = {"{": "}", "(": ")", "[": "]"}
    closing = {v: k for k, v in pairs.items()}
    stack = []
    for ch in cleaned:
        if ch in pairs:
            stack.append(ch)
        elif ch in closing:
            if not stack or stack[-1] != closing[ch]:
                errors.append(f"{path.relative_to(ROOT)}: unmatched closing '{ch}'")
                return errors
            stack.pop()
    if stack:
        errors.append(f"{path.relative_to(ROOT)}: unclosed delimiters {stack}")
    return errors


def main() -> int:
    errors: list[str] = []

    if not PBXPROJ.exists():
        print(f"ERROR: Missing {PBXPROJ}")
        return 1

    pbx_text = PBXPROJ.read_text(encoding="utf-8")

    # 1. Collect all Swift files
    app_swift_files = sorted(APP_DIR.rglob("*.swift"))
    test_swift_files = sorted(TEST_DIR.rglob("*.swift"))
    all_swift_files = app_swift_files + test_swift_files

    print(f"Found {len(app_swift_files)} app Swift files and {len(test_swift_files)} test Swift files.")

    for swift_file in all_swift_files:
        name = swift_file.name
        if name not in pbx_text:
            errors.append(f"Swift file not registered in project.pbxproj: {swift_file.relative_to(ROOT)}")

        content = swift_file.read_text(encoding="utf-8")
        errors.extend(check_balanced_delimiters(swift_file, content))

        for pat in FORBIDDEN_PATTERNS:
            if re.search(pat, content):
                errors.append(f"Forbidden private API pattern '{pat}' found in {swift_file.relative_to(ROOT)}")

    # 2. Verify Info.plist & ExportOptions.plist
    info_plist = APP_DIR / "Info.plist"
    try:
        with info_plist.open("rb") as f:
            plist_data = plistlib.load(f)
        for required_key in [
            "NSPhotoLibraryUsageDescription",
            "NSPhotoLibraryAddUsageDescription",
            "CFBundleIdentifier",
            "CFBundleDisplayName",
        ]:
            if required_key not in plist_data or not str(plist_data[required_key]).strip():
                errors.append(f"Info.plist missing required key: {required_key}")
    except Exception as exc:
        errors.append(f"Invalid Info.plist: {exc}")

    export_plist = ROOT / "ExportOptions.plist"
    try:
        with export_plist.open("rb") as f:
            plistlib.load(f)
    except Exception as exc:
        errors.append(f"Invalid ExportOptions.plist: {exc}")

    # 3. Verify Deployment Target & Bundle ID in project.pbxproj
    if "IPHONEOS_DEPLOYMENT_TARGET = 16.0;" not in pbx_text:
        errors.append("project.pbxproj missing IPHONEOS_DEPLOYMENT_TARGET = 16.0")
    if "PRODUCT_BUNDLE_IDENTIFIER = com.boosterpro.app;" not in pbx_text:
        errors.append("project.pbxproj missing PRODUCT_BUNDLE_IDENTIFIER = com.boosterpro.app")

    # 4. Verify Assets.xcassets JSON files
    for json_file in (APP_DIR / "Assets.xcassets").rglob("*.json"):
        try:
            json.loads(json_file.read_text(encoding="utf-8"))
        except Exception as exc:
            errors.append(f"Invalid JSON in {json_file.relative_to(ROOT)}: {exc}")

    app_icon = APP_DIR / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon-1024.png"
    if not app_icon.exists():
        errors.append("Missing AppIcon-1024.png")

    if errors:
        print("VERIFICATION FAILED:")
        for err in errors:
            print(f"  - {err}")
        return 1

    print("ALL CHECKS PASSED SUCCESSFULLY!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
