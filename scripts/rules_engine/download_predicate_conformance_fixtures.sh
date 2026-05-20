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

mkdir -p "$(dirname "${OUTPUT_PATH}")"

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI is required to download khepri conformance fixtures" >&2
  exit 1
fi

gh api \
  "repos/RevenueCat/khepri/contents/${KHEPRI_FIXTURE_PATH}?ref=${KHEPRI_REF}" \
  --jq '.content' \
  | tr -d '\n' \
  | base64 --decode \
  > "${OUTPUT_PATH}"

echo "Downloaded predicate conformance fixtures to ${OUTPUT_PATH}"
