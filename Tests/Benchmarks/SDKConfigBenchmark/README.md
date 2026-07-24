# SDKConfigBenchmark

A macOS command-line benchmark that measures the SDK's **legacy offerings flow** against the
**remote config endpoint flow** (and its kill switch) through the real manager-level code paths.

Two transports:

- **`--transport simulated`** (default): in-process fixtures with seeded network profiles
  (ideal/wifi/lte), packet-loss modeling, and a forced kill-switch 4xx. Deterministic and
  CI-friendly.
- **`--transport live`**: real requests against the production backend, defaulting to the
  prepared stress-test project
  ([`5f07e7e3`](https://app.revenuecat.com/projects/5f07e7e3)). No keys live in source: the
  matrix script resolves the key via mafdet; direct binary runs take `--api-key` or the
  `SDK_CONFIG_BENCHMARK_API_KEY` environment variable, either of which also requires
  `--project-id` so rows are labeled with the key's real project. Same recorded per-request metrics; real
  CDN/TLS/latency behavior. Kill-switch, profiles, and loss are simulated-only (you cannot
  force a 4xx or packet loss on production).

See `CONFIG_ENDPOINT_BENCHMARKS.md` for methodology, scenario definitions, sample numbers, and
known limitations.

## Setup

```sh
tuist install
tuist generate SDKConfigBenchmark SDKConfigBenchmarkTests
```

## Run the matrix

```sh
bash Tests/Benchmarks/SDKConfigBenchmark/run-matrix.sh > results.jsonl        # simulated
TRANSPORT=live bash Tests/Benchmarks/SDKConfigBenchmark/run-matrix.sh > live.jsonl
```

Live runs default to the pinned stress-test project. To measure a different project, pass its
id; the key is resolved via the mafdet CLI (test-store app preferred) and every row is labeled
with `project_id`, so results from different projects can never be compared as equivalents:

```sh
PROJECT_ID=<dashboard-project-id> TRANSPORT=live \
  bash Tests/Benchmarks/SDKConfigBenchmark/run-matrix.sh > other-project.jsonl
```

(The target project's keyed app needs at least one package with a product attached, or the
offerings fetch fails with a configuration error.)

Compare two runs (e.g. baseline branch vs candidate branch):

```sh
python3 Tests/Benchmarks/SDKConfigBenchmark/compare.py baseline.jsonl candidate.jsonl
```

Render one run as a table:

```sh
python3 Tests/Benchmarks/SDKConfigBenchmark/compare.py results.jsonl
```

## Run a single configuration

```sh
xcodebuild -workspace RevenueCat-Tuist.xcworkspace -scheme SDKConfigBenchmark \
  -configuration Release -destination platform=macOS build

# --transport: simulated | live
# --mode: legacy | config | config-killswitch (kill switch is simulated-only)
# --profile (ideal | wifi | lte) and --loss-percent are simulated-only
SDKConfigBenchmark \
  --transport simulated \
  --mode config \
  --scenario cold \
  --profile lte \
  --loss-percent 20 \
  --iterations 25 \
  --warmup-iterations 3 \
  --paywalls 50 \
  --workflows 100 \
  --seed 42 \
  --annotation sdk_commit=$(git rev-parse --short HEAD)
```

Output is one JSON object (a JSONL row) on stdout.

Every run isolates the SDK's disk caches (ETags, offerings, remote config, blobs) under a
fresh temporary directory that is removed on exit, so runs never touch the real user Library
and concurrent runs cannot corrupt each other.

## App-launch tier (simulator or device)

The CLI above measures the manager-level flows in isolation. The app-host tier measures what
a customer actually experiences: a real iOS app (`SDKConfigBenchmarkApp`, linking the stock
`RevenueCat`/`RevenueCatUI` products) that runs `Purchases.configure` and reports the time to
configure, first customer info, offerings, and paywall appeared. An XCUITest relaunches the
app once per iteration, so every sample is a true process cold start; the runner script
builds the app twice, once per SDK variant, by rewriting `SWIFT_ACTIVE_COMPILATION_CONDITIONS`
in `Local.xcconfig` (restored on exit):

```sh
bash Tests/TestingApps/SDKConfigBenchmarkApp/run-app-launch.sh > app-launch.jsonl
python3 Tests/Benchmarks/SDKConfigBenchmark/compare.py app-launch.jsonl
```

Rows are `compare.py`-compatible, with `mode` = `app-launch-legacy` / `app-launch-config` and
`profile` = `simulator` / `device`. Knobs: `ITERATIONS`, `WARMUP`, `PROJECT_ID`,
`SDK_CONFIG_BENCHMARK_API_KEY` (skips mafdet; requires an explicit `PROJECT_ID`), and `DESTINATION` (pass
`DESTINATION="platform=iOS,id=<udid>"` to measure a physical device's real radio). Live only:
there is no simulated transport, no kill-switch mode, and no loss model in this tier.

Each launch also registers the config path when it runs: config persisted time, blob counts
split inline vs CDN-downloaded with byte totals, and size extremes that bracket the backend's
inline-size budget. The headline percentile is `Purchases.configure` + `getOfferings`
completed, with or without workflows compiled in (matching the CLI tier's total); paywall
render marks stay in the row as secondary phases. Tests run under Release and fail if a
launch's observed SDK variant contradicts the row's label. The intent is that any automation
able to drive `xcodebuild test` (CI, the baguette CLI, a cron box) can run the app N times
and collect the same gateable JSONL as the CLI matrix.

## Unit tests

```sh
xcodebuild -workspace RevenueCat-Tuist.xcworkspace -scheme SDKConfigBenchmarkTests \
  -destination platform=macOS test
```

The tests validate that fixtures decode into the real SDK response models, that the RC-Container
encoder round-trips through the SDK parser, that the transport is deterministic per seed, and
that each benchmark mode drives the expected SDK flow end to end (including warm 304/204
revalidation and the kill-switch fallback).
