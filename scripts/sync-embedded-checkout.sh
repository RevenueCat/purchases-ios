#!/bin/bash
# Copies purchases-js UMD into RevenueCatUI so the in-app checkout drawer
# does not need a network fetch for the SDK. Run from anywhere:
#   ./scripts/sync-embedded-checkout.sh
# Requires a built purchases-js dist (pnpm build in that repo).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JS_ROOT="$(cd "$ROOT/../purchases-js" && pwd)"
JS_DIST="$JS_ROOT/dist/Purchases.umd.js"
DEST="$ROOT/RevenueCatUI/Resources/EmbeddedCheckout"
PKG="$JS_ROOT/package.json"

if [[ ! -f "$JS_DIST" ]]; then
  echo "Missing $JS_DIST"
  echo "Build purchases-js first (pnpm build in $JS_ROOT)."
  exit 1
fi

mkdir -p "$DEST"
cp "$JS_DIST" "$DEST/Purchases.umd.js"

VERSION="$(node -p "require('$PKG').version")"
printf '%s\n' "$VERSION" > "$DEST/VERSION"

echo "Synced purchases-js $VERSION -> $DEST/Purchases.umd.js"
