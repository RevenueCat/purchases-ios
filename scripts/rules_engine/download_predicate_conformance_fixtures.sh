#!/usr/bin/env bash
#
# Downloads the khepri-generated audience predicate conformance fixtures.
#
# By default this pulls from the khepri PR branch that introduced the fixtures.
# Override KHEPRI_PREDICATE_CONFORMANCE_REF to pin a different git ref once the
# fixtures land on main.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

KHEPRI_REF="${KHEPRI_PREDICATE_CONFORMANCE_REF:-codex/audience-predicate-fixtures}"
OUTPUT_PATH="${KHEPRI_PREDICATE_CONFORMANCE_FIXTURE_PATH:-${REPO_ROOT}/Tests/RulesEngineTests/Fixtures/predicate_conformance_v1.json}"
KHEPRI_FIXTURE_PATH="khepri/services/audience/fixtures/predicate_conformance_v1.json"
API_URL="https://api.github.com/repos/RevenueCat/khepri/contents/${KHEPRI_FIXTURE_PATH}?ref=${KHEPRI_REF}"

mkdir -p "$(dirname "${OUTPUT_PATH}")"

decode_fixture_content() {
  tr -d '\n' | base64 --decode > "${OUTPUT_PATH}"
}

download_via_gh() {
  gh api "${API_URL#https://api.github.com/}" \
    --jq '.content' \
    | decode_fixture_content
}

download_via_github_api() {
  local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
  if [[ -z "${token}" ]]; then
    echo "error: GITHUB_TOKEN is required to download khepri conformance fixtures without gh CLI" >&2
    exit 1
  fi

  curl -fsSL \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${API_URL}" \
    | python3 -c 'import json, sys; print(json.load(sys.stdin).get("content", "").replace("\n", ""))' \
    | decode_fixture_content
}

if command -v gh >/dev/null 2>&1; then
  download_via_gh
else
  download_via_github_api
fi

echo "Downloaded predicate conformance fixtures to ${OUTPUT_PATH}"
