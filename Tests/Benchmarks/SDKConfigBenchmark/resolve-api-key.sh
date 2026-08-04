#!/usr/bin/env bash
#
# Shared API-key resolution for both benchmark tiers (run-matrix.sh and run-app-launch.sh),
# so live runs of the two tiers always resolve the same key for the same project and stay
# comparable. No keys live in source.
#
# Usage (from a script with `set -euo pipefail`):
#   source ".../resolve-api-key.sh"
#   KEY="$(resolve_benchmark_api_key "$PROJECT_ID")"
#
# Resolution order: the SDK_CONFIG_BENCHMARK_API_KEY environment variable, else mafdet
# (preferring the project's test-store app, whose products actually exist). Exits nonzero
# with a message on stderr when no key can be resolved.

# Resolves the project id BEFORE any default applies. A custom key via
# SDK_CONFIG_BENCHMARK_API_KEY requires an explicit PROJECT_ID: otherwise rows would carry
# the pinned default project label with another project's key, and live rows from different
# projects would compare as equivalents.
default_benchmark_project_id() {
    if [[ -z "${PROJECT_ID:-}" ]]; then
        if [[ -n "${SDK_CONFIG_BENCHMARK_API_KEY:-}" ]]; then
            echo "SDK_CONFIG_BENCHMARK_API_KEY requires an explicit PROJECT_ID so rows are labeled with the key's real project" >&2
            return 1
        fi
        printf '5f07e7e3'
    else
        printf '%s' "$PROJECT_ID"
    fi
}

resolve_benchmark_api_key() {
    local project_id="$1"
    local key

    if [[ -n "${SDK_CONFIG_BENCHMARK_API_KEY:-}" ]]; then
        key="$SDK_CONFIG_BENCHMARK_API_KEY"
    else
        if ! command -v mafdet >/dev/null; then
            echo "set SDK_CONFIG_BENCHMARK_API_KEY or install the mafdet CLI to resolve the project key" >&2
            return 1
        fi
        key="$(mafdet app api-keys --project-id "$project_id" 2>/dev/null | python3 -c '
import json, sys
keys = json.load(sys.stdin)
keys.sort(key=lambda entry: entry.get("app_store_type") != "test_store")
print(keys[0]["key"] if keys else "")
')"
    fi

    if [[ -z "$key" ]]; then
        echo "Could not resolve an API key for project $project_id" >&2
        return 1
    fi

    printf '%s' "$key"
}
