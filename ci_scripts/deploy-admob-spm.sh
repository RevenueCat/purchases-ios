#!/bin/bash
set -euo pipefail

# Deploys the RevenueCatAdMob adapter to the purchases-ios-admob SPM repo.
# Rewrites the local path dependency to a versioned dependency, then commits, tags, and pushes.
#
# Usage:
#   ci_scripts/deploy-admob-spm.sh <version>              # commits, tags, and pushes
#   ci_scripts/deploy-admob-spm.sh <version> --dry-run    # preview changes without pushing

VERSION="${1:?Usage: deploy-admob-spm.sh <version> [--dry-run]}"
DRY_RUN="${2:-}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADAPTER_DIR="${REPO_ROOT}/AdapterSDKs/RevenueCatAdMob"
WORK_DIR="$(mktemp -d)"
if [ "${DRY_RUN}" != "--dry-run" ]; then
    trap 'rm -rf "${WORK_DIR}"' EXIT
fi

# Clone the target repo
git clone git@github.com:RevenueCat/purchases-ios-admob.git "${WORK_DIR}"
cd "${WORK_DIR}"

# Clear existing contents (except .git)
git rm -rf . 2>/dev/null || true

# Copy adapter sources
cp -a "${ADAPTER_DIR}/." .

# Rewrite Package.swift: replace local path dep with versioned dep
# sed -i behaves differently on macOS (requires '') vs Linux (no argument)
if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' 's|.package(name: "purchases-ios", path: "../..")|.package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", exact: "'"${VERSION}"'")|' Package.swift
    sed -i '' 's|package: "purchases-ios"|package: "purchases-ios-spm"|' Package.swift
    sed -i '' 's|from: "[^"]*")|from: "'"${VERSION}"'")|' README.md
else
    sed -i 's|.package(name: "purchases-ios", path: "../..")|.package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", exact: "'"${VERSION}"'")|' Package.swift
    sed -i 's|package: "purchases-ios"|package: "purchases-ios-spm"|' Package.swift
    sed -i 's|from: "[^"]*")|from: "'"${VERSION}"'")|' README.md
fi

if [ "${DRY_RUN}" = "--dry-run" ]; then
    echo "=== Dry run: showing rewritten Package.swift ==="
    cat Package.swift
    echo ""
    echo "=== Files that would be committed ==="
    git add -A
    git status
    echo "=== Dry run complete — remove --dry-run to push ==="
    echo "=== Work dir kept at: ${WORK_DIR} ==="
else
    git add -A
    git commit -m "Release ${VERSION}"
    git tag "${VERSION}"
    git push origin main
    git push origin "${VERSION}"
fi
