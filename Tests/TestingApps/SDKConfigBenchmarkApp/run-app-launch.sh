#!/usr/bin/env bash
#
# App-host tier of the SDK config benchmark: builds SDKConfigBenchmarkApp twice (legacy SDK
# vs config-endpoint SDK) and drives the XCUITest relaunch loop against the live stress-test
# project, emitting one JSONL row per (variant, scenario) to stdout:
#
#   bash Tests/TestingApps/SDKConfigBenchmarkApp/run-app-launch.sh > app-launch.jsonl
#
# The legacy/config switch is the ENABLE_REMOTE_CONFIG compile condition, which the SPM-built
# RevenueCat reads from the SWIFT_ACTIVE_COMPILATION_CONDITIONS line of CI.xcconfig (if
# present) or Local.xcconfig (see Package.swift). This script rewrites that file per variant,
# restores it on exit, and builds each variant into its own derived data path.
#
# Environment overrides:
#   VARIANTS="legacy config"  # SDK build variants to measure
#   ITERATIONS=10 WARMUP=2    # app relaunches per scenario / discarded from statistics
#   PROJECT_ID=<id>           # target RevenueCat project; key resolved via mafdet
#                             # (test-store app preferred), rows labeled with the id
#   SDK_CONFIG_BENCHMARK_API_KEY=<key>  # skip mafdet and use this key directly
#   DESTINATION="platform=iOS Simulator,id=<udid>"  # default: first available iPhone
#                             # simulator; pass a device destination to measure real radio

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DERIVED_DATA_ROOT="${DERIVED_DATA_ROOT:-$REPO_ROOT/.build/sdk-config-benchmark-app}"
VARIANTS="${VARIANTS:-legacy config}"
ITERATIONS="${ITERATIONS:-10}"
WARMUP="${WARMUP:-2}"
PROJECT_ID="${PROJECT_ID:-5f07e7e3}"

# Package.swift prefers CI.xcconfig over Local.xcconfig, so the variant switch must edit
# whichever file actually wins.
if [[ -f "$REPO_ROOT/CI.xcconfig" ]]; then
    XCCONFIG="$REPO_ROOT/CI.xcconfig"
else
    XCCONFIG="$REPO_ROOT/Local.xcconfig"
fi

XCCONFIG_BACKUP=""
XCCONFIG_EXISTED=0
if [[ -f "$XCCONFIG" ]]; then
    XCCONFIG_EXISTED=1
    XCCONFIG_BACKUP="$(mktemp)"
    cp "$XCCONFIG" "$XCCONFIG_BACKUP"
fi

VARIANT_MARKER="// sdk-config-benchmark-variant:"

restore_xcconfig() {
    if [[ "$XCCONFIG_EXISTED" == "1" ]]; then
        cp "$XCCONFIG_BACKUP" "$XCCONFIG"
        rm -f "$XCCONFIG_BACKUP"
    else
        rm -f "$XCCONFIG"
    fi
    sed -i '' "/^${VARIANT_MARKER//\//\\/}/d" "$REPO_ROOT/Package.swift"
}
trap restore_xcconfig EXIT

# Resolve the API key: env override, else mafdet (no keys live in source).
if [[ -n "${SDK_CONFIG_BENCHMARK_API_KEY:-}" ]]; then
    RESOLVED_KEY="$SDK_CONFIG_BENCHMARK_API_KEY"
else
    if ! command -v mafdet >/dev/null; then
        echo "set SDK_CONFIG_BENCHMARK_API_KEY or install the mafdet CLI to resolve the project key" >&2
        exit 1
    fi
    RESOLVED_KEY="$(mafdet app api-keys --project-id "$PROJECT_ID" 2>/dev/null | python3 -c '
import json, sys
keys = json.load(sys.stdin)
keys.sort(key=lambda entry: entry.get("app_store_type") != "test_store")
print(keys[0]["key"] if keys else "")
')"
fi
if [[ -z "$RESOLVED_KEY" ]]; then
    echo "Could not resolve an API key for project $PROJECT_ID" >&2
    exit 1
fi
echo "Live target: project $PROJECT_ID" >&2

if [[ -z "${DESTINATION:-}" ]]; then
    UDID="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
iphones = [d for ds in devices.values() for d in ds if d["name"].startswith("iPhone")]
print(iphones[0]["udid"] if iphones else "")
')"
    if [[ -z "$UDID" ]]; then
        echo "No available iPhone simulator; pass DESTINATION explicitly" >&2
        exit 1
    fi
    DESTINATION="platform=iOS Simulator,id=$UDID"
fi
echo "Destination: $DESTINATION" >&2

echo "Generating workspace..." >&2
(cd "$REPO_ROOT" && tuist generate --no-open SDKConfigBenchmarkApp SDKConfigBenchmarkAppUITests >&2)

set_swift_conditions() {
    local conditions="$1"
    if [[ -f "$XCCONFIG" ]] && grep -q '^SWIFT_ACTIVE_COMPILATION_CONDITIONS' "$XCCONFIG"; then
        sed -i '' "s/^SWIFT_ACTIVE_COMPILATION_CONDITIONS.*$/SWIFT_ACTIVE_COMPILATION_CONDITIONS = \$(inherited) $conditions/" "$XCCONFIG"
    else
        # shellcheck disable=SC2016 # $(inherited) is an xcconfig token, not shell
        printf '\nSWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) %s\n' "$conditions" >> "$XCCONFIG"
    fi
    # SwiftPM caches manifest evaluations by Package.swift CONTENT (mtime is ignored), and
    # the xcconfig is not part of the cache key: without a content change, a reused derived
    # data path silently builds the previous variant's flags. A marker comment carrying the
    # current conditions (removed on exit) forces re-evaluation exactly when they change.
    sed -i '' "/^${VARIANT_MARKER//\//\\/}/d" "$REPO_ROOT/Package.swift"
    printf '%s %s\n' "$VARIANT_MARKER" "$conditions" >> "$REPO_ROOT/Package.swift"
}

FAILED_VARIANTS=0
TOTAL_ROWS=0

for variant in $VARIANTS; do
    # BYPASS_SIMULATED_STORE_RELEASE_CHECK: tests build Release (shipping-SDK numbers), and
    # live runs use the project's Test Store key, which the SDK otherwise refuses (by
    # crashing) in Release builds. This is the SDK's designed opt-out for that guard.
    case "$variant" in
        legacy)
            CONDITIONS="BYPASS_SIMULATED_STORE_RELEASE_CHECK"
            EXPECT_CONFIG_PATH=0
            ;;
        config)
            CONDITIONS="ENABLE_REMOTE_CONFIG BYPASS_SIMULATED_STORE_RELEASE_CHECK"
            EXPECT_CONFIG_PATH=1
            ;;
        *) echo "Unknown variant $variant (expected legacy or config)" >&2; exit 1 ;;
    esac

    echo "=== Variant $variant (conditions: '${CONDITIONS:-none}') ===" >&2
    set_swift_conditions "$CONDITIONS"

    LOG="$(mktemp)"
    DERIVED_DATA="$DERIVED_DATA_ROOT/$variant"
    if ! env TEST_RUNNER_BENCH_API_KEY="$RESOLVED_KEY" \
             TEST_RUNNER_BENCH_MODE_LABEL="app-launch-$variant" \
             TEST_RUNNER_BENCH_ITERATIONS="$ITERATIONS" \
             TEST_RUNNER_BENCH_WARMUP="$WARMUP" \
             TEST_RUNNER_BENCH_PROJECT_ID="$PROJECT_ID" \
             TEST_RUNNER_BENCH_EXPECT_CONFIG_PATH="$EXPECT_CONFIG_PATH" \
        xcodebuild -workspace "$REPO_ROOT/RevenueCat-Tuist.xcworkspace" \
            -scheme SDKConfigBenchmarkApp \
            -destination "$DESTINATION" \
            -derivedDataPath "$DERIVED_DATA" \
            test > "$LOG" 2>&1; then
        echo "Variant $variant FAILED; last log lines:" >&2
        tail -25 "$LOG" >&2
        FAILED_VARIANTS=$((FAILED_VARIANTS + 1))
        # A failed invocation must not leak rows into the JSONL: the tests print
        # BENCHMARK_ROW before their validity assertions, so rows from a failed run may
        # look clean while measuring the wrong thing.
        rm -f "$LOG"
        continue
    fi

    # Prove the variant flag reached the SDK compile (guards the manifest-cache hazard).
    # Only checkable when this run actually compiled the SDK; cached builds still get
    # runtime verification via BENCH_EXPECT_CONFIG_PATH (each launched binary reports
    # whether the config path ran, and the tests fail on a mismatch).
    if grep -q "SwiftCompile.*RevenueCat" "$LOG"; then
        # The rows claim shipping-SDK numbers: refuse Debug-built frameworks.
        if ! grep -q "Release-iphone" "$LOG"; then
            echo "Variant $variant compiled without a Release configuration; refusing its rows" >&2
            FAILED_VARIANTS=$((FAILED_VARIANTS + 1))
            rm -f "$LOG"
            continue
        fi
        if [[ "$EXPECT_CONFIG_PATH" == "1" ]] && ! grep -q -- "-DENABLE_REMOTE_CONFIG" "$LOG"; then
            echo "Variant $variant compiled WITHOUT ENABLE_REMOTE_CONFIG; refusing its rows" >&2
            FAILED_VARIANTS=$((FAILED_VARIANTS + 1))
            rm -f "$LOG"
            continue
        fi
        if [[ "$EXPECT_CONFIG_PATH" == "0" ]] && grep -q -- "-DENABLE_REMOTE_CONFIG" "$LOG"; then
            echo "Variant $variant compiled WITH ENABLE_REMOTE_CONFIG; refusing its rows" >&2
            FAILED_VARIANTS=$((FAILED_VARIANTS + 1))
            rm -f "$LOG"
            continue
        fi
    else
        echo "Warning: SDK not recompiled for variant $variant (cached build); flag not re-verified" >&2
    fi

    ROWS="$(grep -o 'BENCHMARK_ROW: {.*}' "$LOG" | sed 's/^BENCHMARK_ROW: //' | sort -u || true)"
    ROW_COUNT=0
    if [[ -n "$ROWS" ]]; then
        ROW_COUNT="$(printf '%s\n' "$ROWS" | wc -l | tr -d ' ')"
        printf '%s\n' "$ROWS"
    fi
    TOTAL_ROWS=$((TOTAL_ROWS + ROW_COUNT))
    if [[ "$ROW_COUNT" -lt 2 ]]; then
        echo "Variant $variant produced $ROW_COUNT row(s), expected 2 (cold + warm)" >&2
        FAILED_VARIANTS=$((FAILED_VARIANTS + 1))
    fi
    rm -f "$LOG"
done

if (( FAILED_VARIANTS > 0 )); then
    echo "$FAILED_VARIANTS variant check(s) failed" >&2
    exit 1
fi
echo "Done: $TOTAL_ROWS row(s)" >&2
