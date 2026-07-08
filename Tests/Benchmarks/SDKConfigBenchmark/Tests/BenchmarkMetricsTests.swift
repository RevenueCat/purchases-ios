import XCTest

@testable import SDKConfigBenchmarkCore

final class BenchmarkMetricsTests: BenchmarkTestCase {

    private func measurement(totalMs: Double) -> IterationMeasurement {
        return IterationMeasurement(totalMs: totalMs, events: [])
    }

    func testNearestRankPercentiles() {
        let sorted: [Double] = (1...100).map(Double.init)

        XCTAssertEqual(BenchmarkMetrics.percentile(50, of: sorted), 50)
        XCTAssertEqual(BenchmarkMetrics.percentile(90, of: sorted), 90)
        XCTAssertEqual(BenchmarkMetrics.percentile(95, of: sorted), 95)
        XCTAssertEqual(BenchmarkMetrics.percentile(99, of: sorted), 99)
        XCTAssertEqual(BenchmarkMetrics.percentile(99, of: [7]), 7)
    }

    private func decodeRow(_ metrics: BenchmarkMetrics, command: BenchmarkCommand) throws -> [String: Any] {
        let row = metrics.jsonlRow(for: command)
        let object = try JSONSerialization.jsonObject(with: Data(row.utf8))
        return try XCTUnwrap(object as? [String: Any])
    }

    func testJSONLRowDiscardsWarmupIterations() throws {
        var command = BenchmarkCommand()
        command.iterations = 5
        command.warmupIterations = 2

        var metrics = BenchmarkMetrics()
        // Two slow warmup iterations that must not pollute the stats.
        [1_000.0, 900.0, 10.0, 20.0, 30.0].forEach { metrics.record(self.measurement(totalMs: $0)) }

        let row = try self.decodeRow(metrics, command: command)

        XCTAssertEqual(row["warmup_discarded"] as? Int, 2)
        XCTAssertEqual(row["mean_ms"] as? Double, 20)
        XCTAssertEqual(row["max_ms"] as? Double, 30)
    }

    func testJSONLRowCarriesConfigurationAndAnnotations() throws {
        var command = BenchmarkCommand()
        command.mode = .configKillswitch
        command.scenario = .warm
        command.profileName = "lte"
        command.lossPercent = 20
        command.annotations = ["sdk_commit": "abc123"]
        command.warmupIterations = 0

        var metrics = BenchmarkMetrics()
        metrics.record(self.measurement(totalMs: 42))
        metrics.record(error: BenchmarkError.timeout("offerings fetch"))

        let row = try self.decodeRow(metrics, command: command)

        XCTAssertEqual(row["mode"] as? String, "config-killswitch")
        XCTAssertEqual(row["scenario"] as? String, "warm")
        XCTAssertEqual(row["profile"] as? String, "lte")
        XCTAssertEqual(row["loss_percent"] as? Int, 20)
        XCTAssertEqual(row["sdk_commit"] as? String, "abc123")
        XCTAssertEqual(row["error_count"] as? Int, 1)
        XCTAssertNotNil(row["first_error"])
        XCTAssertEqual(row["p50_ms"] as? Double, 42)
    }

    func testMeasurementDerivesPhasesFromEvents() {
        let start = DispatchTime.now()
        func time(_ offsetMs: UInt64) -> DispatchTime {
            return DispatchTime(uptimeNanoseconds: start.uptimeNanoseconds + offsetMs * 1_000_000)
        }
        func event(
            path: String,
            host: String = "api.revenuecat.com",
            from startMs: UInt64,
            until endMs: UInt64,
            status: Int = 200,
            failed: Bool = false
        ) -> TransportEvent {
            return TransportEvent(host: host, path: path, statusCode: status, bytesReceived: 100,
                                  startedAt: time(startMs), endedAt: time(endMs), failed: failed)
        }

        let measurement = IterationMeasurement(totalMs: 100, events: [
            event(path: "/v1/config/app", from: 0, until: 10),
            event(path: "/blobs/aaa", host: "cdn.revenuecat.local", from: 10, until: 20),
            event(path: "/blobs/bbb", host: "cdn.revenuecat.local", from: 12, until: 30),
            event(path: "/v1/subscribers/u/offerings", from: 5, until: 45),
            event(path: "/v1/offerings", host: "api-production.8-lives-cat.io",
                  from: 46, until: 50, status: 0, failed: true)
        ])

        XCTAssertEqual(measurement.requestCount, 5)
        XCTAssertEqual(measurement.bytesReceived, 500)
        XCTAssertEqual(measurement.failedRequestCount, 1)
        XCTAssertEqual(measurement.fallbackHostRequestCount, 1)
        XCTAssertEqual(measurement.configMs ?? 0, 10, accuracy: 0.001)
        XCTAssertEqual(measurement.blobMs ?? 0, 20, accuracy: 0.001)
        XCTAssertEqual(measurement.offeringsMs ?? 0, 45, accuracy: 0.001)
    }

}
