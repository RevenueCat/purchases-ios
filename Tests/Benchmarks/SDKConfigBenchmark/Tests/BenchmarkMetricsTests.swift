import XCTest

@testable import SDKConfigBenchmarkCore

final class BenchmarkMetricsTests: BenchmarkTestCase {

    private func measurement(
        totalMs: Double,
        blobAccounting: BlobAccounting = .empty
    ) -> IterationMeasurement {
        return IterationMeasurement(totalMs: totalMs, events: [], blobAccounting: blobAccounting)
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

    func testJSONLRowDiscardsWarmupIterationsByIndex() throws {
        var command = BenchmarkCommand()
        command.iterations = 5
        command.warmupIterations = 2

        var metrics = BenchmarkMetrics()
        // Two slow warmup iterations that must not pollute the stats.
        for (index, totalMs) in [1_000.0, 900.0, 10.0, 20.0, 30.0].enumerated() {
            metrics.record(self.measurement(totalMs: totalMs), iteration: index)
        }

        let row = try self.decodeRow(metrics, command: command)

        XCTAssertEqual(row["warmup_discarded"] as? Int, 2)
        XCTAssertEqual(row["measured_iterations"] as? Int, 3)
        XCTAssertEqual(row["mean_ms"] as? Double, 20)
        XCTAssertEqual(row["max_ms"] as? Double, 30)
    }

    func testFailedWarmupIterationDoesNotShiftDiscardWindow() throws {
        var command = BenchmarkCommand()
        command.iterations = 4
        command.warmupIterations = 2

        var metrics = BenchmarkMetrics()
        metrics.record(self.measurement(totalMs: 1_000), iteration: 0)
        metrics.record(error: BenchmarkError.timeout("offerings fetch"), iteration: 1)
        metrics.record(self.measurement(totalMs: 10), iteration: 2)
        metrics.record(self.measurement(totalMs: 30), iteration: 3)

        let row = try self.decodeRow(metrics, command: command)

        // A failed warmup iteration must not shift a measured iteration into the discard
        // window: iterations 2 and 3 are measured, the warmup error is visible but separate.
        XCTAssertEqual(row["measured_iterations"] as? Int, 2)
        XCTAssertEqual(row["mean_ms"] as? Double, 20)
        XCTAssertEqual(row["error_count"] as? Int, 1)
        XCTAssertEqual(row["post_warmup_error_count"] as? Int, 0)
    }

    func testPostWarmupErrorsAreCalledOut() throws {
        var command = BenchmarkCommand()
        command.iterations = 3
        command.warmupIterations = 1

        var metrics = BenchmarkMetrics()
        metrics.record(self.measurement(totalMs: 10), iteration: 0)
        metrics.record(self.measurement(totalMs: 20), iteration: 1)
        metrics.record(error: BenchmarkError.timeout("offerings fetch"), iteration: 2)

        let row = try self.decodeRow(metrics, command: command)

        XCTAssertEqual(row["post_warmup_error_count"] as? Int, 1)
        XCTAssertEqual(metrics.postWarmupErrorCount(warmupIterations: command.warmupIterations), 1)
        let firstError = try XCTUnwrap(row["first_error"] as? String)
        XCTAssertTrue(firstError.hasPrefix("iteration 2:"))
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
        metrics.record(self.measurement(totalMs: 42), iteration: 0)
        metrics.record(error: BenchmarkError.timeout("offerings fetch"), iteration: 1)

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

    func testMeasurementDerivesPhasesFromEvents() throws {
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
        ) throws -> TransportEvent {
            let url = try XCTUnwrap(URL(string: "https://\(host)\(path)"))
            return TransportEvent(kind: RequestKind(url: url), iteration: 0, host: host, path: path,
                                  statusCode: status, bytesReceived: 100,
                                  startedAt: time(startMs), endedAt: time(endMs), failed: failed)
        }

        let measurement = IterationMeasurement(totalMs: 100, events: [
            try event(path: "/v1/config/app", from: 0, until: 10),
            try event(path: "/blobs/aaa", host: "cdn.revenuecat.local", from: 10, until: 20),
            try event(path: "/blobs/bbb", host: "cdn.revenuecat.local", from: 12, until: 30),
            try event(path: "/v1/subscribers/u/offerings", from: 5, until: 45),
            try event(path: "/v1/offerings", host: "api-production.8-lives-cat.io",
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

    // MARK: - Blob accounting

    func testBlobAccountingAttributesInlineVersusDownloadedAndTracksExtremes() {
        let accounting = BlobAccounting(
            newRefSizes: ["inline-big": 30_000, "inline-small": 500, "cdn-a": 9_000, "cdn-b": 12_000],
            downloadedRefs: ["cdn-a", "cdn-b", "cdn-never-stored"]
        )

        XCTAssertEqual(accounting.inlineCount, 2)
        XCTAssertEqual(accounting.downloadedCount, 2)
        XCTAssertEqual(accounting.totalBytes, 51_500)
        // The extremes bracket the backend's inline-size budget.
        XCTAssertEqual(accounting.maxInlineBytes, 30_000)
        XCTAssertEqual(accounting.minDownloadedBytes, 9_000)
    }

    func testBlobAccountingAttributesRefsToTopics() {
        // Which topic each stored blob belongs to, from the persisted topic index; a stored
        // ref no topic references is labeled explicitly rather than dropped.
        let accounting = BlobAccounting(
            newRefSizes: ["wf-1": 40_000, "wf-2": 30_000, "ui-app": 5_000, "mystery": 100],
            downloadedRefs: ["ui-app"],
            topicByRef: ["wf-1": "workflows", "wf-2": "workflows", "ui-app": "ui_config"]
        )

        XCTAssertEqual(accounting.countsByTopic, ["workflows": 2, "ui_config": 1, "unreferenced": 1])
        XCTAssertEqual(accounting.bytesByTopic, ["workflows": 70_000, "ui_config": 5_000, "unreferenced": 100])
    }

    func testJSONLRowCarriesBlobAccountingAggregates() throws {
        var command = BenchmarkCommand()
        command.iterations = 2
        command.warmupIterations = 0

        var metrics = BenchmarkMetrics()
        metrics.record(self.measurement(totalMs: 10, blobAccounting: BlobAccounting(
            newRefSizes: ["i1": 1_000, "d1": 4_000], downloadedRefs: ["d1"],
            topicByRef: ["i1": "workflows", "d1": "ui_config"]
        )), iteration: 0)
        metrics.record(self.measurement(totalMs: 20, blobAccounting: BlobAccounting(
            newRefSizes: ["i2": 3_000, "d2": 2_000], downloadedRefs: ["d2"],
            topicByRef: ["i2": "workflows", "d2": "ui_config"]
        )), iteration: 1)

        let row = try self.decodeRow(metrics, command: command)

        XCTAssertEqual(row["blobs_inline_mean"] as? Double, 1)
        XCTAssertEqual(row["blobs_downloaded_mean"] as? Double, 1)
        XCTAssertEqual(row["blob_bytes_mean"] as? Double, 5_000)
        XCTAssertEqual(row["max_inline_blob_bytes"] as? Int, 3_000)
        XCTAssertEqual(row["min_downloaded_blob_bytes"] as? Int, 2_000)

        let byTopic = try XCTUnwrap(row["blobs_by_topic"] as? [String: [String: Double]])
        XCTAssertEqual(byTopic["workflows"]?["count_mean"], 1)
        XCTAssertEqual(byTopic["workflows"]?["bytes_mean"], 2_000)
        XCTAssertEqual(byTopic["ui_config"]?["count_mean"], 1)
        XCTAssertEqual(byTopic["ui_config"]?["bytes_mean"], 3_000)
    }

    func testJSONLRowOmitsBlobExtremesWhenNoBlobsWereStored() throws {
        var command = BenchmarkCommand()
        command.iterations = 1
        command.warmupIterations = 0

        var metrics = BenchmarkMetrics()
        metrics.record(self.measurement(totalMs: 10), iteration: 0)

        let row = try self.decodeRow(metrics, command: command)

        XCTAssertEqual(row["blobs_inline_mean"] as? Double, 0)
        XCTAssertEqual(row["blobs_downloaded_mean"] as? Double, 0)
        XCTAssertNil(row["max_inline_blob_bytes"])
        XCTAssertNil(row["min_downloaded_blob_bytes"])
    }

}
