#!/usr/bin/env python3
"""Run memory benchmarks, compare baselines, or record selected baseline updates."""

import argparse
import json
import math
import os
from pathlib import Path
import plistlib
import statistics
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
BASELINES = ROOT / "Tests/PerformanceTests/Baselines.json"
PEAK_METRIC = "com.apple.dt.XCTMetric_Memory.physical_peak"


def compare(name, sample, baseline):
    if baseline is None:
        raise ValueError(f"{name}: no baseline. Run with --record and review the result.")
    for field in ("environment", "workloadSHA256"):
        if sample[field] != baseline[field]:
            raise ValueError(f"{name}: {field} changed. Record and review a new baseline.")
    limit = baseline["peakMemoryMiB"] * (1 + baseline["tolerancePercent"] / 100)
    measured = sample["peakMemoryMiB"]
    passed = measured <= limit
    return passed, (
        f"{'PASS' if passed else 'FAIL'} {name}: peak {measured:.2f} MiB, "
        f"baseline {baseline['peakMemoryMiB']:.2f} MiB, limit {limit:.2f} MiB"
    )


def capture(*command):
    return subprocess.check_output(command, cwd=ROOT, text=True).strip()


def test_run_file(products, sdk_version):
    matches = list(products.glob(f"PerformanceTests_iphonesimulator{sdk_version}-*.xctestrun"))
    if len(matches) != 1:
        raise ValueError(f"Expected one PerformanceTests xctestrun file for SDK {sdk_version}.")
    return matches[0]


def result_json(result, kind):
    return json.loads(capture("xcrun", "xcresulttool", "get", "test-results", kind,
                              "--path", str(result), "--compact"))


def read_samples(result):
    summary = result_json(result, "summary")
    if summary["result"] != "Passed" or summary["passedTests"] == 0 or summary["skippedTests"]:
        raise ValueError("The benchmark must pass without skipped tests before baseline comparison or recording.")
    devices = summary["devicesAndConfigurations"]
    if len(devices) != 1:
        raise ValueError("Run benchmarks on one destination at a time.")
    device = devices[0]["device"]
    environment = {key: device[key] for key in (
        "modelName", "osVersion", "osBuildNumber", "architecture", "platform"
    )}
    metadata = {}
    for line in result.with_suffix(".log").read_text().splitlines():
        if line.startswith("PERFORMANCE_ENVIRONMENT "):
            environment["xcode"] = json.loads(line.removeprefix("PERFORMANCE_ENVIRONMENT "))["xcode"]
        if line.startswith("PERFORMANCE_WORKLOAD "):
            entry = json.loads(line.removeprefix("PERFORMANCE_WORKLOAD "))
            metadata[entry["test"]] = entry["sha256"]
    if "xcode" not in environment:
        raise ValueError("Missing Xcode version in the benchmark log. Run with performance_tests.py.")
    samples = {}
    for test in result_json(result, "metrics"):
        name = test["testIdentifier"]
        values = []
        for run in test["testRuns"]:
            for metric in run["metrics"]:
                if metric["identifier"] != PEAK_METRIC:
                    continue
                if metric["unitOfMeasurement"] != "kB":
                    raise ValueError(f"{name}: unsupported memory unit: {metric['unitOfMeasurement']}")
                values.extend(metric["measurements"])
        if not values or not all(math.isfinite(value) and value > 0 for value in values):
            raise ValueError(f"{name}: no valid peak memory measurements.")
        if name not in metadata:
            raise ValueError(f"{name}: missing workload hash. Use PerformanceTestCase.measureMemory.")
        samples[name] = {
            "peakMemoryMiB": statistics.mean(values) * 1000 / (1024 ** 2),
            "workloadSHA256": metadata[name],
            "environment": environment,
        }
    if not samples:
        raise ValueError("No performance tests produced memory measurements.")
    return samples


def run_benchmarks(args):
    key = os.environ.get("REVENUECAT_PERFORMANCE_API_KEY")
    if not key:
        raise ValueError("Set REVENUECAT_PERFORMANCE_API_KEY to the benchmark project's SDK key.")
    output = ROOT / ".build/performance-tests"
    output.mkdir(parents=True, exist_ok=True)
    run_dir = Path(tempfile.mkdtemp(prefix="run-", dir=output))
    derived = output / "DerivedData"
    result = run_dir / "PerformanceTests.xcresult"
    log_path = result.with_suffix(".log")
    print(f"Build and test log: {log_path}", flush=True)
    with log_path.open("w") as log:
        environment = {"xcode": capture("xcodebuild", "-version").replace("\n", " / ")}
        log.write("PERFORMANCE_ENVIRONMENT " + json.dumps(environment) + "\n")
        log.flush()
        def run(command):
            subprocess.run(command, cwd=ROOT, check=True, stdout=log, stderr=subprocess.STDOUT)

        run([os.environ.get("TUIST_BIN", "tuist"), "generate", "PerformanceTests", "--no-open"])
        run(["xcodebuild", "build-for-testing", "-workspace", "RevenueCat-Tuist.xcworkspace",
             "-scheme", "PerformanceTests", "-destination", args.destination,
             "-derivedDataPath", str(derived), "ENABLE_TESTABILITY=YES", "CODE_SIGNING_ALLOWED=NO"])
        sdk_version = capture("xcrun", "--sdk", "iphonesimulator", "--show-sdk-version")
        path = test_run_file(derived / "Build/Products", sdk_version)
        settings = plistlib.loads(path.read_bytes())
        settings["PerformanceTests"].setdefault("EnvironmentVariables", {})[
            "REVENUECAT_PERFORMANCE_API_KEY"
        ] = key
        private_run = path.with_name(f"PerformanceTests-{run_dir.name}.xctestrun")
        private_run.write_bytes(plistlib.dumps(settings))
        private_run.chmod(0o600)
        try:
            command = ["xcodebuild", "test-without-building", "-xctestrun", str(private_run),
                       "-destination", args.destination, "-resultBundlePath", str(result)]
            if args.test:
                command.append(f"-only-testing:PerformanceTests/{args.test.removesuffix('()')}")
            run(command)
        finally:
            private_run.unlink()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--record", action="store_true", help="Update baselines for the tests that run.")
    parser.add_argument("--test", help="Run one class or Class/testMethod.")
    parser.add_argument("--destination", default="platform=iOS Simulator,name=iPhone 17 Pro,OS=26.0")
    parser.add_argument("--results", type=Path, help="Use an existing .xcresult and adjacent .log file.")
    args = parser.parse_args()
    if args.results and args.test:
        parser.error("--test cannot filter an existing --results bundle.")
    try:
        result = (args.results or run_benchmarks(args)).resolve()
        samples = read_samples(result)
        baselines = json.loads(BASELINES.read_text()) if BASELINES.exists() else {}
        if args.record:
            for name, sample in samples.items():
                tolerance = baselines.get(name, {}).get("tolerancePercent", 10)
                baselines[name] = dict(
                    sample, peakMemoryMiB=round(sample["peakMemoryMiB"], 2), tolerancePercent=tolerance
                )
                print(f"RECORD {name}: {sample['peakMemoryMiB']:.2f} MiB (+{tolerance}% tolerance)")
            BASELINES.write_text(json.dumps(baselines, indent=2, sort_keys=True) + "\n")
            print(f"Review the diff in {BASELINES.relative_to(ROOT)} before committing.")
            return 0
        passed = True
        for name, sample in samples.items():
            accepted, message = compare(name, sample, baselines.get(name))
            print(message)
            passed &= accepted
        return 0 if passed else 1
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
