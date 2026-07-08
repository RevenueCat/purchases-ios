#!/usr/bin/env bash
#
# Runs the SDK config benchmark matrix and emits one JSONL row per configuration to stdout.
# Build logs and progress go to stderr, so redirecting stdout captures clean JSONL:
#
#   bash Tests/Benchmarks/SDKConfigBenchmark/run-matrix.sh > baseline.jsonl
#
# Requires the Tuist workspace: tuist install && tuist generate SDKConfigBenchmark
#
# Override the matrix through environment variables:
#   TRANSPORT=live            # hit the real backend (pinned stress-test project) instead of
#                             # the simulated transport; forces ideal profile, no loss, and
#                             # drops the kill-switch mode (cannot force 4xx on production)
#   MODES="legacy config config-killswitch"
#   SCENARIOS="cold warm"
#   PROFILES="ideal lte"
#   LOSSES="0"                # extra loss sweep applies to config/cold/lte below
#   LOSS_SWEEP="10 20 30"
#   ITERATIONS=25 WARMUP=3 PAYWALLS=50 WORKFLOWS=100 SEED=42
#   SKIP_BUILD=1              # reuse the previously built binary

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DERIVED_DATA="${DERIVED_DATA:-$REPO_ROOT/.build/sdk-config-benchmark-derived-data}"
BINARY="$DERIVED_DATA/Build/Products/Release/SDKConfigBenchmark"

TRANSPORT="${TRANSPORT:-simulated}"
if [[ "$TRANSPORT" == "live" ]]; then
    MODES="${MODES:-legacy config}"
    PROFILES="ideal"
    LOSSES="0"
    LOSS_SWEEP=""
else
    MODES="${MODES:-legacy config config-killswitch}"
    PROFILES="${PROFILES:-ideal lte}"
    LOSSES="${LOSSES:-0}"
    LOSS_SWEEP="${LOSS_SWEEP:-10 20 30}"
fi
SCENARIOS="${SCENARIOS:-cold warm}"
ITERATIONS="${ITERATIONS:-25}"
WARMUP="${WARMUP:-3}"
PAYWALLS="${PAYWALLS:-50}"
WORKFLOWS="${WORKFLOWS:-100}"
SEED="${SEED:-42}"

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
    echo "Building SDKConfigBenchmark (Release)..." >&2
    xcodebuild -workspace "$REPO_ROOT/RevenueCat-Tuist.xcworkspace" \
        -scheme SDKConfigBenchmark \
        -configuration Release \
        -destination platform=macOS \
        -derivedDataPath "$DERIVED_DATA" \
        build >&2
fi

if [[ ! -x "$BINARY" ]]; then
    echo "Benchmark binary not found at $BINARY" >&2
    exit 1
fi

SDK_COMMIT="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
BENCH_HOME="$(mktemp -d)"
trap 'rm -rf "$BENCH_HOME"' EXIT

run_row() {
    local mode="$1" scenario="$2" profile="$3" loss="$4"
    echo "Running transport=$TRANSPORT mode=$mode scenario=$scenario profile=$profile loss=$loss%..." >&2
    HOME="$BENCH_HOME" "$BINARY" \
        --transport "$TRANSPORT" \
        --mode "$mode" \
        --scenario "$scenario" \
        --profile "$profile" \
        --loss-percent "$loss" \
        --iterations "$ITERATIONS" \
        --warmup-iterations "$WARMUP" \
        --paywalls "$PAYWALLS" \
        --workflows "$WORKFLOWS" \
        --seed "$SEED" \
        --annotation "sdk_commit=$SDK_COMMIT"
}

for mode in $MODES; do
    for scenario in $SCENARIOS; do
        for profile in $PROFILES; do
            for loss in $LOSSES; do
                run_row "$mode" "$scenario" "$profile" "$loss"
            done
        done
    done
done

# Loss sweep: degraded LTE for the two systems' cold starts. Warm scenarios are skipped here
# because loss-induced request failures make the 304/204 verification nondeterministic.
if [[ -n "$LOSS_SWEEP" ]]; then
    for loss in $LOSS_SWEEP; do
        for mode in legacy config; do
            run_row "$mode" cold lte "$loss"
        done
    done
fi
