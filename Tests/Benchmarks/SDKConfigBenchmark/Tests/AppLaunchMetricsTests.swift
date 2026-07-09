import XCTest

@testable import SDKConfigBenchmarkCore

final class AppLaunchMetricsTests: BenchmarkTestCase {

    private static func sample(_ total: Double) -> LaunchSample {
        return LaunchSample(
            configuredMs: total * 0.1,
            customerInfoMs: total * 0.4,
            offeringsMs: total * 0.8,
            paywallAppearedMs: total,
            error: nil
        )
    }

    private func decodedRow(
        warmupDiscarded: Int = 1,
        samples: [LaunchSample?]
    ) throws -> [String: Any] {
        let row = AppLaunchMetrics.row(
            mode: "app-launch-config",
            scenario: "cold",
            profile: "simulator",
            projectID: "5f07e7e3",
            warmupDiscarded: warmupDiscarded,
            samples: samples
        )
        let object = try JSONSerialization.jsonObject(with: Data(row.utf8))
        return try XCTUnwrap(object as? [String: Any])
    }

    func testPercentileMatchesCLIBenchmarkFormula() {
        let sorted: [Double] = (1...10).map(Double.init)
        for percentile in [50, 90, 95, 99] {
            XCTAssertEqual(
                AppLaunchMetrics.percentile(percentile, of: sorted),
                BenchmarkMetrics.percentile(percentile, of: sorted),
                "p\(percentile)"
            )
        }
    }

    func testRowCarriesEveryComparisonKeyField() throws {
        let row = try self.decodedRow(samples: [Self.sample(100), Self.sample(200)])

        XCTAssertEqual(row["mode"] as? String, "app-launch-config")
        XCTAssertEqual(row["transport"] as? String, "live")
        XCTAssertEqual(row["scenario"] as? String, "cold")
        XCTAssertEqual(row["profile"] as? String, "simulator")
        XCTAssertEqual(row["loss_percent"] as? Int, 0)
        XCTAssertEqual(row["paywalls"] as? Int, 0)
        XCTAssertEqual(row["workflows"] as? Int, 0)
        XCTAssertEqual(row["seed"] as? Int, 0)
        XCTAssertEqual(row["iterations"] as? Int, 2)
        XCTAssertEqual(row["warmup_discarded"] as? Int, 1)
        XCTAssertEqual(row["project_id"] as? String, "5f07e7e3")
    }

    func testRowStatisticsUsePaywallAppearedOfPostWarmupSamples() throws {
        // Warmup discards by index: the 500ms first launch never enters the stats.
        let row = try self.decodedRow(
            samples: [Self.sample(500), Self.sample(100), Self.sample(300), Self.sample(200)]
        )

        XCTAssertEqual(row["measured_iterations"] as? Int, 3)
        XCTAssertEqual(row["mean_ms"] as? Double, 200)
        XCTAssertEqual(row["min_ms"] as? Double, 100)
        XCTAssertEqual(row["max_ms"] as? Double, 300)
        XCTAssertEqual(row["p50_ms"] as? Double, 200)
        XCTAssertEqual(row["p95_ms"] as? Double, 300)
        XCTAssertEqual(row["post_warmup_error_count"] as? Int, 0)
        XCTAssertEqual(row["paywall_appeared_ms_mean"] as? Double, 200)
        XCTAssertEqual(row["configured_ms_mean"] as? Double, 20)
        XCTAssertEqual(row["customer_info_ms_mean"] as? Double, 80)
        XCTAssertEqual(row["offerings_ms_mean"] as? Double, 160)
    }

    func testIncompleteOrFailedSamplesCountAsErrorsAndNeverEnterStats() throws {
        var failed = Self.sample(50)
        failed.error = "BENCH_API_KEY missing"
        var incomplete = Self.sample(75)
        incomplete.paywallAppearedMs = nil

        let row = try self.decodedRow(
            warmupDiscarded: 0,
            samples: [Self.sample(100), failed, incomplete, nil]
        )

        XCTAssertEqual(row["iterations"] as? Int, 4)
        XCTAssertEqual(row["measured_iterations"] as? Int, 1)
        XCTAssertEqual(row["error_count"] as? Int, 3)
        XCTAssertEqual(row["post_warmup_error_count"] as? Int, 3)
        XCTAssertEqual(row["mean_ms"] as? Double, 100)
        let firstError = try XCTUnwrap(row["first_error"] as? String)
        XCTAssertTrue(firstError.contains("BENCH_API_KEY missing"))
    }

    func testWarmupWindowErrorsAreCountedButNotPostWarmup() throws {
        var failed = Self.sample(50)
        failed.error = "boom"

        let row = try self.decodedRow(warmupDiscarded: 1, samples: [failed, Self.sample(100)])

        XCTAssertEqual(row["error_count"] as? Int, 1)
        XCTAssertEqual(row["post_warmup_error_count"] as? Int, 0)
        XCTAssertEqual(row["measured_iterations"] as? Int, 1)
    }

    func testLaunchSampleJSONRoundTrip() throws {
        let sample = Self.sample(123.456)
        let decoded = try XCTUnwrap(LaunchSample.decode(from: sample.jsonString()))
        XCTAssertEqual(decoded, sample)
    }

}
