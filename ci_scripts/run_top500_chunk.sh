#!/usr/bin/env bash

set -euo pipefail

# Runs the Paywall-Screenshots Xcode test plan for the current top500 chunk,
# then extracts the screenshots into a chunk-specific directory.
#
# Usage:
#   ./ci_scripts/run_top500_chunk.sh <chunk_label>
# Example:
#   ./ci_scripts/run_top500_chunk.sh top500-part-1
#
# Assumes:
# - paywall-preview-resources repo is at /Users/cesar/Development/repos/paywall-preview-resources
# - purchases-ios repo is at /Users/cesar/Development/repos/purchases-ios
# - resources/top500-2025-12-04/offerings.json has already been edited to contain
#   the desired slice of offerings for this chunk.

CHUNK_LABEL="${1:-chunk}"

PPR_ROOT="/Users/cesar/Development/repos/paywall-preview-resources"
IOS_ROOT="/Users/cesar/Development/repos/purchases-ios"
OFFERINGS_PATH="$PPR_ROOT/resources/top500-2025-12-04/offerings.json"

if [[ ! -f "$OFFERINGS_PATH" ]]; then
  echo "ERROR: Offerings file not found at $OFFERINGS_PATH"
  exit 1
fi

echo "=== Current top500 offerings count for this chunk ==="
jq '.offerings | length' "$OFFERINGS_PATH" || {
  echo "ERROR: Failed to read offerings.json"
  exit 1
}

echo "=== Running Paywall-Screenshots test plan (top500 only) ==="
cd "$IOS_ROOT"

rm -rf ./test_output
mkdir -p ./test_output

xcodebuild test \
  -workspace RevenueCat.xcworkspace \
  -scheme RevenueCatUITestsDev \
  -testPlan Paywall-Screenshots \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.5" \
  -resultBundlePath ./test_output/RevenueCatUITests.xcresult \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  -quiet

echo "=== Extracting screenshots from xcresult ==="
rm -rf ./test_output/images
mkdir -p ./test_output/images

bundle exec fastlane run extract_xcresult_images \
  xcresult_path:./test_output/RevenueCatUITests.xcresult \
  output_dir:./test_output/images >/tmp/run_top500_chunk_extract.log 2>&1

SCREENSHOT_COUNT=$(ls ./test_output/images/*.png 2>/dev/null | wc -l | tr -d ' ')
echo "Extracted $SCREENSHOT_COUNT screenshots for chunk '$CHUNK_LABEL'"

CHUNK_OUTPUT_DIR="./top500_chunks/$CHUNK_LABEL"
mkdir -p "$CHUNK_OUTPUT_DIR"

mv ./test_output/images/*.png "$CHUNK_OUTPUT_DIR"/ 2>/dev/null || true

echo "Screenshots moved to: $CHUNK_OUTPUT_DIR"


