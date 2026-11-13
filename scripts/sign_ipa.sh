#!/usr/bin/env bash
# ==============================================================================
# sign_ipa.sh - Signs BoosterPro.ipa with Apple Development or Distribution cert
# Usage:
#   ./scripts/sign_ipa.sh <input.ipa> <"Identity Name"> <profile.mobileprovision> [output.ipa]
# Example:
#   ./scripts/sign_ipa.sh BoosterPro.ipa "Apple Development: John Doe (XYZ)" profile.mobileprovision BoosterPro-Signed.ipa
# ==============================================================================
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <input.ipa> <signing_identity> <provisioning_profile> [output.ipa]"
  exit 1
fi

INPUT_IPA="$1"
SIGNING_IDENTITY="$2"
PROVISION_PROFILE="$3"
OUTPUT_IPA="${4:-${INPUT_IPA%.ipa}-signed.ipa}"

WORK_DIR=$(mktemp -d /tmp/sign_boosterpro.XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "==> Unpacking $INPUT_IPA..."
unzip -q "$INPUT_IPA" -d "$WORK_DIR"

APP_PATH=$(find "$WORK_DIR/Payload" -maxdepth 1 -name "*.app" | head -n 1)
if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
  echo "ERROR: No .app bundle found in $INPUT_IPA"
  exit 1
fi

echo "==> Embedding provisioning profile..."
cp "$PROVISION_PROFILE" "$APP_PATH/embedded.mobileprovision"

echo "==> Extracting entitlements from profile..."
ENTITLEMENTS="$WORK_DIR/entitlements.plist"
security cms -D -i "$PROVISION_PROFILE" > "$WORK_DIR/profile.plist"
/usr/libexec/PlistBuddy -x -c "Print :Entitlements" "$WORK_DIR/profile.plist" > "$ENTITLEMENTS"

echo "==> Signing frameworks & plugins..."
if [ -d "$APP_PATH/Frameworks" ]; then
  find "$APP_PATH/Frameworks" -type f -name "*.dylib" -o -name "*.framework" | while read -r item; do
    codesign --force --sign "$SIGNING_IDENTITY" "$item"
  done
fi

echo "==> Signing main bundle ($APP_PATH) with identity: $SIGNING_IDENTITY..."
codesign --force --sign "$SIGNING_IDENTITY" --entitlements "$ENTITLEMENTS" --timestamp=none "$APP_PATH"

echo "==> Verifying signature..."
codesign -dvv "$APP_PATH"

echo "==> Packaging into $OUTPUT_IPA..."
(cd "$WORK_DIR" && zip -qr "$OUTPUT_IPA" Payload)
mv "$WORK_DIR/$OUTPUT_IPA" "$OUTPUT_IPA"

echo "==> SUCCESS! Signed IPA created at: $OUTPUT_IPA"
