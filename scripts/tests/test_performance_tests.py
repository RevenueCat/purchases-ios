import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch
import tempfile

spec = importlib.util.spec_from_file_location(
    "performance_tests", Path(__file__).parents[1] / "performance_tests.py"
)
performance = importlib.util.module_from_spec(spec)
spec.loader.exec_module(performance)


class BaselineTests(unittest.TestCase):
    def setUp(self):
        self.sample = {
            "peakMemoryMiB": 55.0,
            "workloadSHA256": "same-workload",
            "environment": {"modelName": "iPhone 17 Pro", "osVersion": "26.0"},
        }
        self.baseline = dict(self.sample, tolerancePercent=10)

    def test_memory_above_tolerance_fails_with_values(self):
        sample = dict(self.sample, peakMemoryMiB=61.0)
        passed, message = performance.compare("Workflow/testMemory()", sample, self.baseline)
        self.assertFalse(passed)
        self.assertIn("61.00 MiB", message)
        self.assertIn("55.00 MiB", message)
        self.assertIn("60.50 MiB", message)

    def test_memory_at_limit_or_lower_passes(self):
        for peak in (40.0, 55.0, 60.5):
            with self.subTest(peak=peak):
                passed, _ = performance.compare(
                    "Workflow/testMemory()", dict(self.sample, peakMemoryMiB=peak), self.baseline
                )
                self.assertTrue(passed)

    def test_different_workload_requires_new_baseline(self):
        with self.assertRaisesRegex(ValueError, "workload"):
            performance.compare(
                "Workflow/testMemory()",
                dict(self.sample, workloadSHA256="changed-workload"),
                self.baseline,
            )

    def test_different_environment_requires_new_baseline(self):
        with self.assertRaisesRegex(ValueError, "environment"):
            performance.compare(
                "Workflow/testMemory()", dict(self.sample, environment={}), self.baseline
            )

    def test_missing_baseline_fails(self):
        with self.assertRaisesRegex(ValueError, "--record"):
            performance.compare("Workflow/testMemory()", self.sample, None)


class TestRunSelectionTests(unittest.TestCase):
    def test_selects_current_sdk_when_old_build_artifacts_remain(self):
        with tempfile.TemporaryDirectory() as directory:
            products = Path(directory)
            old = products / "PerformanceTests_iphonesimulator25.0-arm64-x86_64.xctestrun"
            current = products / "PerformanceTests_iphonesimulator26.0-arm64-x86_64.xctestrun"
            old.touch()
            current.touch()
            self.assertEqual(performance.test_run_file(products, "26.0"), current)


class MetricParsingTests(unittest.TestCase):
    def test_uses_peak_kilobytes_and_ignores_memory_growth(self):
        with tempfile.TemporaryDirectory() as directory:
            result = Path(directory) / "run.xcresult"
            result.with_suffix(".log").write_text(
                'PERFORMANCE_ENVIRONMENT {"xcode":"Xcode 26.0"}\n'
                'PERFORMANCE_WORKLOAD {"test":"Workflow/testMemory()","sha256":"abc"}\n'
            )
            summary = {
                "result": "Passed", "passedTests": 1, "skippedTests": 0,
                "devicesAndConfigurations": [{"device": {
                    "modelName": "iPhone 17 Pro", "osVersion": "26.0", "osBuildNumber": "23A343",
                    "architecture": "arm64", "platform": "iOS Simulator",
                }}],
            }
            metrics = [{
                "testIdentifier": "Workflow/testMemory()", "testRuns": [{"metrics": [
                    {"identifier": performance.PEAK_METRIC, "unitOfMeasurement": "kB",
                     "measurements": [1048.576, 3145.728]},
                    {"identifier": "com.apple.dt.XCTMetric_Memory.physical",
                     "unitOfMeasurement": "kB", "measurements": [99999]},
                ]}],
            }]
            with patch.object(performance, "result_json", side_effect=[summary, metrics]):
                sample = performance.read_samples(result)["Workflow/testMemory()"]
            self.assertAlmostEqual(sample["peakMemoryMiB"], 2.0)
            self.assertEqual(sample["workloadSHA256"], "abc")
            self.assertEqual(sample["environment"]["xcode"], "Xcode 26.0")

    def test_failed_or_skipped_runs_cannot_create_baselines(self):
        for summary in (
            {"result": "Failed", "passedTests": 0, "skippedTests": 0},
            {"result": "Passed", "passedTests": 1, "skippedTests": 1},
        ):
            with patch.object(performance, "result_json", return_value=summary):
                with self.assertRaisesRegex(ValueError, "must pass"):
                    performance.read_samples(Path("unused.xcresult"))


if __name__ == "__main__":
    unittest.main()
