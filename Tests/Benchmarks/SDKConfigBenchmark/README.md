# SDKConfigBenchmark

A macOS command-line benchmark that measures the SDK's **legacy offerings flow** against the
**remote config endpoint flow** (and its kill switch) through the real manager-level code paths,
under simulated network conditions.

See `CONFIG_ENDPOINT_BENCHMARKS.md` for methodology, scenario definitions, sample numbers, and
known limitations.

## Setup

```sh
tuist install
tuist generate SDKConfigBenchmark SDKConfigBenchmarkTests
```

## Run the matrix

```sh
bash Tests/Benchmarks/SDKConfigBenchmark/run-matrix.sh > results.jsonl
```

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

SDKConfigBenchmark \
  --mode config \            # legacy | config | config-killswitch
  --scenario cold \          # cold | warm
  --profile lte \            # ideal | wifi | lte
  --loss-percent 20 \
  --iterations 25 \
  --warmup-iterations 3 \
  --paywalls 50 \
  --workflows 100 \
  --seed 42 \
  --annotation sdk_commit=$(git rev-parse --short HEAD)
```

Output is one JSON object (a JSONL row) on stdout.

Run the benchmark with a scratch `HOME` (the matrix script does this automatically) so the
SDK's disk caches don't touch your real user directory:

```sh
HOME=$(mktemp -d) SDKConfigBenchmark --mode legacy --scenario cold --profile ideal
```

## Unit tests

```sh
xcodebuild -workspace RevenueCat-Tuist.xcworkspace -scheme SDKConfigBenchmarkTests \
  -destination platform=macOS test
```

The tests validate that fixtures decode into the real SDK response models, that the RC-Container
encoder round-trips through the SDK parser, that the transport is deterministic per seed, and
that each benchmark mode drives the expected SDK flow end to end (including warm 304/204
revalidation and the kill-switch fallback).
