#!/usr/bin/env bash
#
# Build the Darwin (iOS) Swift SDK from Xcode and publish it to GHCR as an OCI artifact.
#
# This lets us cross-compile the RevenueCat / RevenueCatUI modules for Apple platforms
# from Linux (e.g. Cursor cloud agents) using xtool's Darwin Swift SDK, without shipping
# Xcode itself. Run this locally whenever we need to bump the Xcode/SDK version; the
# resulting artifact is consumed at Docker-build time (see "Consuming the artifact" below).
#
# What it does:
#   1. Resolves an Xcode source (an existing Xcode.app / Xcode.xip, or downloads one via xcodes).
#   2. Runs `xtool sdk build` to extract a redistributable Darwin Swift SDK (.artifactbundle).
#   3. Packages the bundle as a gzipped tarball and pushes it to GHCR via `oras`.
#
# Usage:
#   ./scripts/build-darwin-sdk.sh --repo ghcr.io/<org>/<name> [options]
#
# Examples:
#   # Use the Xcode already installed on this Mac:
#   ./scripts/build-darwin-sdk.sh -r ghcr.io/revenuecat/xtool-darwin-sdk -t 16.3 --also-latest
#
#   # Download a specific Xcode via xcodes first (needs Apple auth, see below):
#   ./scripts/build-darwin-sdk.sh -r ghcr.io/revenuecat/xtool-darwin-sdk -v 16.3
#
#   # Point at a previously downloaded xip:
#   ./scripts/build-darwin-sdk.sh -r ghcr.io/revenuecat/xtool-darwin-sdk -t 16.3 \
#       -p ~/Downloads/Xcode_16.3.xip
#
# Options:
#   -r, --repo <ref>          GHCR repository WITHOUT a tag, e.g. ghcr.io/org/name. (required)
#   -v, --xcode-version <ver> Xcode version to download via xcodes (e.g. 16.3).
#   -p, --xcode-path <path>   Path to an existing Xcode.app or Xcode.xip (skips downloading).
#   -t, --tag <tag>           Artifact tag (default: the Xcode version, e.g. 16.3).
#   -a, --arch <arch>         Target Linux host arch the SDK will RUN on: x86_64 (default)
#                             or aarch64. This must match the machine that consumes the SDK
#                             (Cursor cloud agents are x86_64), NOT your local machine.
#       --also-latest         Additionally push/overwrite the ":latest" tag.
#   -o, --output <dir>        Working/output directory (default: ./.darwin-sdk-build).
#       --keep                Keep intermediate build artifacts on success.
#   -h, --help                Show this help.
#
# Authentication (provided via environment, never on the command line):
#   GHCR_USER / GHCR_TOKEN    GitHub username + token with `write:packages` scope. Falls back
#                             to GITHUB_ACTOR / GITHUB_TOKEN if unset.
#   XCODES_USERNAME           Apple ID, used only when downloading via xcodes (-v).
#   FASTLANE_SESSION          Pre-generated Apple session (from `fastlane spaceauth -u <id>`),
#                             used only when downloading via xcodes (-v). Avoids interactive 2FA.
#
# Consuming the artifact (in your .cursor environment Dockerfile, public base + Build Secret):
#   RUN --mount=type=secret,id=GHCR_TOKEN,env=GHCR_TOKEN,required=true \
#       oras login ghcr.io -u <user> --password-stdin <<<"$GHCR_TOKEN" \
#       && oras pull ghcr.io/<org>/<name>:16.3 -o /tmp/sdk \
#       && swift sdk install /tmp/sdk/darwin-*.artifactbundle.tar.gz \
#       && rm -rf /tmp/sdk \
#       && swift sdk list   # should print the darwin SDK
#
set -euo pipefail

# --- pretty logging -----------------------------------------------------------
if [ -t 2 ]; then
  _c_red=$'\033[31m'; _c_grn=$'\033[32m'; _c_ylw=$'\033[33m'; _c_dim=$'\033[2m'; _c_rst=$'\033[0m'
else
  _c_red=""; _c_grn=""; _c_ylw=""; _c_dim=""; _c_rst=""
fi
log()  { printf '%s==>%s %s\n' "$_c_grn" "$_c_rst" "$*" >&2; }
warn() { printf '%swarn:%s %s\n' "$_c_ylw" "$_c_rst" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$_c_red" "$_c_rst" "$*" >&2; exit 1; }

usage() { sed -n '2,/^set -euo pipefail$/{/^set -euo pipefail$/d;s/^# \{0,1\}//;p}' "$0"; }

# --- defaults -----------------------------------------------------------------
REPO=""
XCODE_VERSION=""
XCODE_PATH=""
TAG=""
ARCH="x86_64"
ALSO_LATEST=false
OUTPUT_DIR="./.darwin-sdk-build"
KEEP=false

# --- arg parsing --------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    -r|--repo)          REPO="${2:?--repo needs a value}"; shift 2 ;;
    -v|--xcode-version) XCODE_VERSION="${2:?--xcode-version needs a value}"; shift 2 ;;
    -p|--xcode-path)    XCODE_PATH="${2:?--xcode-path needs a value}"; shift 2 ;;
    -t|--tag)           TAG="${2:?--tag needs a value}"; shift 2 ;;
    -a|--arch)          ARCH="${2:?--arch needs a value}"; shift 2 ;;
    --also-latest)      ALSO_LATEST=true; shift ;;
    -o|--output)        OUTPUT_DIR="${2:?--output needs a value}"; shift 2 ;;
    --keep)             KEEP=true; shift ;;
    -h|--help)          usage; exit 0 ;;
    *)                  die "unknown argument: $1 (use --help)" ;;
  esac
done

# --- validation ---------------------------------------------------------------
[ -n "$REPO" ] || die "--repo is required (e.g. ghcr.io/org/name). See --help."
case "$REPO" in
  *:*[!/]*) die "--repo must NOT include a tag. Use --tag for that. Got: $REPO" ;;
esac
case "$ARCH" in
  x86_64|aarch64) ;;
  arm64) ARCH="aarch64"; warn "normalized arch 'arm64' -> 'aarch64'" ;;
  amd64) ARCH="x86_64";  warn "normalized arch 'amd64' -> 'x86_64'" ;;
  *) die "--arch must be x86_64 or aarch64 (got: $ARCH)" ;;
esac
if [ -z "$XCODE_PATH" ] && [ -z "$XCODE_VERSION" ]; then
  # Default to the currently-selected Xcode on macOS, if present.
  if command -v xcode-select >/dev/null 2>&1 && XSEL="$(xcode-select -p 2>/dev/null)"; then
    XCODE_PATH="${XSEL%%/Contents/Developer}"
    log "No --xcode-path/--xcode-version given; using selected Xcode: $XCODE_PATH"
  else
    die "Provide either --xcode-path or --xcode-version (no Xcode auto-detected)."
  fi
fi

# Derive the tag from the version if not given explicitly.
if [ -z "$TAG" ]; then
  [ -n "$XCODE_VERSION" ] || die "--tag is required when using --xcode-path without --xcode-version."
  TAG="$XCODE_VERSION"
fi
# Use the tag as the version label when we don't have an explicit version.
[ -n "$XCODE_VERSION" ] || XCODE_VERSION="$TAG"

# --- dependency checks --------------------------------------------------------
need() { command -v "$1" >/dev/null 2>&1 || die "missing required tool '$1'. $2"; }
need xtool "Install from https://xtool.sh (xtool sdk build is required)."
need oras  "Install from https://oras.land/docs/installation (used to push the OCI artifact)."
need tar   "tar is required to package the SDK bundle."

# sha256 helper differs across macOS / Linux.
sha256() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else echo "unavailable"; fi
}

# Prints the most recently modified existing path among its arguments (handles spaces).
newest_file() {
  local newest="" f
  for f in "$@"; do
    [ -e "$f" ] || continue
    if [ -z "$newest" ] || [ "$f" -nt "$newest" ]; then newest="$f"; fi
  done
  [ -n "$newest" ] && printf '%s\n' "$newest"
}

# --- resolve GHCR credentials -------------------------------------------------
GHCR_USER="${GHCR_USER:-${GITHUB_ACTOR:-}}"
GHCR_TOKEN="${GHCR_TOKEN:-${GITHUB_TOKEN:-}}"
[ -n "$GHCR_USER" ]  || die "set GHCR_USER (or GITHUB_ACTOR) to your GitHub username."
[ -n "$GHCR_TOKEN" ] || die "set GHCR_TOKEN (or GITHUB_TOKEN) to a token with write:packages."

mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
SDK_OUT="$OUTPUT_DIR/sdk"
rm -rf "$SDK_OUT"; mkdir -p "$SDK_OUT"

# --- 1. resolve / download Xcode ---------------------------------------------
if [ -z "$XCODE_PATH" ]; then
  need xcodes "Install from https://github.com/XcodesOrg/xcodes (needed to download Xcode)."
  log "Downloading Xcode $XCODE_VERSION via xcodes (using FASTLANE_SESSION if set)..."
  XCODE_DL_DIR="$OUTPUT_DIR/xcode"
  mkdir -p "$XCODE_DL_DIR"
  xcodes_args=(download "$XCODE_VERSION" --directory "$XCODE_DL_DIR")
  if [ -n "${FASTLANE_SESSION:-}" ]; then
    xcodes_args+=(--use-fastlane-auth)
  else
    warn "FASTLANE_SESSION not set; xcodes may prompt for Apple ID / 2FA interactively."
  fi
  xcodes "${xcodes_args[@]}"
  # xcodes saves something like "Xcode-16.3.xip" or "Xcode 16.3.xip".
  shopt -s nullglob
  xips=("$XCODE_DL_DIR"/Xcode*.xip)
  shopt -u nullglob
  [ "${#xips[@]}" -gt 0 ] || die "could not locate the downloaded Xcode xip in $XCODE_DL_DIR."
  XCODE_PATH="$(newest_file "${xips[@]}")"
fi
[ -e "$XCODE_PATH" ] || die "Xcode source not found: $XCODE_PATH"
log "Xcode source: $XCODE_PATH"

# --- 2. build the Darwin Swift SDK -------------------------------------------
log "Building Darwin Swift SDK (target host arch: $ARCH). This can take a while..."
xtool sdk build "$XCODE_PATH" "$SDK_OUT" --arch "$ARCH"

shopt -s nullglob
bundles=("$SDK_OUT"/*.artifactbundle)
shopt -u nullglob
[ "${#bundles[@]}" -gt 0 ] || die "xtool did not produce an .artifactbundle in $SDK_OUT."
BUNDLE="$(newest_file "${bundles[@]}")"
log "Built SDK bundle: $BUNDLE"

# --- 3. package --------------------------------------------------------------
TARBALL_NAME="darwin-${XCODE_VERSION}-${ARCH}.artifactbundle.tar.gz"
TARBALL="$OUTPUT_DIR/$TARBALL_NAME"
log "Packaging -> $TARBALL_NAME"
tar -czf "$TARBALL" -C "$SDK_OUT" "$(basename "$BUNDLE")"
SHA="$(sha256 "$TARBALL")"
SIZE="$(du -h "$TARBALL" | awk '{print $1}')"
log "Tarball ready ($SIZE, sha256=$SHA)"

# --- 4. push to GHCR via oras ------------------------------------------------
log "Logging in to ghcr.io as $GHCR_USER"
printf '%s' "$GHCR_TOKEN" | oras login ghcr.io -u "$GHCR_USER" --password-stdin

created="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
swift_ver="$(swift --version 2>/dev/null | head -1 || echo unknown)"
push_one() {
  local ref="$1"
  log "Pushing $ref"
  ( cd "$OUTPUT_DIR" && oras push "$ref" \
      --artifact-type "application/vnd.revenuecat.darwin-sdk.v1+gzip" \
      --annotation "org.opencontainers.image.created=$created" \
      --annotation "org.opencontainers.image.title=Darwin Swift SDK (Xcode $XCODE_VERSION, $ARCH)" \
      --annotation "org.opencontainers.image.description=xtool-extracted Darwin Swift SDK for cross-compiling Apple targets from Linux" \
      --annotation "sh.xtool.darwin-sdk.xcode-version=$XCODE_VERSION" \
      --annotation "sh.xtool.darwin-sdk.host-arch=$ARCH" \
      --annotation "sh.xtool.darwin-sdk.sha256=$SHA" \
      --annotation "sh.xtool.darwin-sdk.builder-swift=$swift_ver" \
      "$TARBALL_NAME:application/gzip" )
}

push_one "${REPO}:${TAG}"
[ "$ALSO_LATEST" = true ] && push_one "${REPO}:latest"

# --- 5. cleanup + summary -----------------------------------------------------
if [ "$KEEP" = false ]; then
  log "Cleaning up intermediates (use --keep to retain)"
  rm -rf "$SDK_OUT" "$OUTPUT_DIR/xcode"
fi

cat >&2 <<EOF

${_c_grn}Done.${_c_rst} Published Darwin Swift SDK:
  ${REPO}:${TAG}$( [ "$ALSO_LATEST" = true ] && printf ' and %s:latest' "$REPO" )
  Xcode:   ${XCODE_VERSION}
  Arch:    ${ARCH} (must match the host that consumes it, e.g. x86_64 cloud agents)
  sha256:  ${SHA}

${_c_dim}Consume it in your .cursor environment Dockerfile (public base + Build Secret):${_c_rst}
  RUN --mount=type=secret,id=GHCR_TOKEN,env=GHCR_TOKEN,required=true \\
      oras login ghcr.io -u <user> --password-stdin <<<"\$GHCR_TOKEN" \\
      && oras pull ${REPO}:${TAG} -o /tmp/sdk \\
      && swift sdk install /tmp/sdk/${TARBALL_NAME} \\
      && rm -rf /tmp/sdk && swift sdk list
EOF
