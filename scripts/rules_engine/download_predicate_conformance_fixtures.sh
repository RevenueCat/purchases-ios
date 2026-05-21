#!/usr/bin/env bash
#
# Downloads the khepri-generated audience predicate conformance fixtures from
# RevenueCat/khepri main.
#
# Override KHEPRI_PREDICATE_CONFORMANCE_REF to pin a different git ref.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

KHEPRI_REF="${KHEPRI_PREDICATE_CONFORMANCE_REF:-main}"
OUTPUT_PATH="${KHEPRI_PREDICATE_CONFORMANCE_FIXTURE_PATH:-${REPO_ROOT}/Tests/RulesEngineTests/Fixtures/predicate_conformance_v1.json}"
KHEPRI_FIXTURE_PATH="khepri/services/audience/fixtures/predicate_conformance_v1.json"
KHEPRI_REPO_URL="git@github.com:RevenueCat/khepri.git"
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

download_via_git() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir}"' RETURN

  git clone --quiet --depth 1 --branch "${KHEPRI_REF}" --single-branch \
    "${KHEPRI_REPO_URL}" "${tmpdir}/khepri"

  cp "${tmpdir}/khepri/${KHEPRI_FIXTURE_PATH}" "${OUTPUT_PATH}"
}

download_via_github_api() {
  local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
  if [[ -z "${token}" ]]; then
    echo "error: GITHUB_TOKEN is required to download khepri conformance fixtures without gh CLI or git SSH access" >&2
    exit 1
  fi

  local response http_status encoded_content
  response="$(mktemp)"
  http_status="$(
    curl -fsS \
      -o "${response}" \
      -w "%{http_code}" \
      -H "Authorization: Bearer ${token}" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "${API_URL}" \
      || true
  )"

  if [[ "${http_status}" != "200" ]]; then
    echo "error: GitHub API request failed with HTTP ${http_status} for ${API_URL}" >&2
    echo "error: the CI token may not have read access to RevenueCat/khepri" >&2
    cat "${response}" >&2 || true
    rm -f "${response}"
    exit 1
  fi

  encoded_content="$(
    python3 -c 'import json, sys; print(json.load(open(sys.argv[1])).get("content", "").replace("\n", ""))' \
      "${response}"
  )"
  rm -f "${response}"

  if [[ -z "${encoded_content}" ]]; then
    echo "error: GitHub API response did not include fixture content" >&2
    exit 1
  fi

  echo "${encoded_content}" | decode_fixture_content
}

if command -v gh >/dev/null 2>&1; then
  download_via_gh
elif download_via_git; then
  :
else
  download_via_github_api
fi

echo "Downloaded predicate conformance fixtures to ${OUTPUT_PATH}"
