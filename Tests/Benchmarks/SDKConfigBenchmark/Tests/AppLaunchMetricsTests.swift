import XCTest

// swiftlint:disable:next attributes
@_spi(Internal) @testable import SDKConfigBenchmarkCore

final class AppLaunchMetricsTests: BenchmarkTestCase {

    private static func sample(_ total: Double) -> LaunchSample {
        var sample = LaunchSample()
        sample.configuredMs = total * 0.1
        sample.customerInfoMs = total * 0.4
        sample.offeringsMs = total * 0.8
        sample.paywallAppearedMs = total * 0.9
        sample.paywallImpressionMs = total
        return sample
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

    func testRowStatisticsUsePaywallImpressionOfPostWarmupSamples() throws {
        // Warmup discards by index: the 500ms first launch never enters the stats. The
        // headline percentiles use the impression mark (content appeared), not the wrapper.
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
        XCTAssertEqual(row["paywall_impression_ms_mean"] as? Double, 200)
        XCTAssertEqual(row["paywall_appeared_ms_mean"] as? Double, 180)
        XCTAssertEqual(row["configured_ms_mean"] as? Double, 20)
        XCTAssertEqual(row["customer_info_ms_mean"] as? Double, 80)
        XCTAssertEqual(row["offerings_ms_mean"] as? Double, 160)
    }

    func testSampleMissingImpressionCountsAsError() {
        var missingImpression = Self.sample(100)
        missingImpression.paywallImpressionMs = nil

        XCTAssertNotNil(AppLaunchMetrics.errorMessage(for: missingImpression))
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
        var sample = Self.sample(123.456)
        sample.configPersistedMs = 88.5
        sample.blobsInline = 2
        sample.blobsDownloaded = 1
        sample.blobBytes = 40_000
        sample.maxInlineBlobBytes = 30_000
        sample.minDownloadedBlobBytes = 10_000
        sample.configPathActive = true
        sample.configOutcome = "persisted"
        let decoded = try XCTUnwrap(LaunchSample.decode(from: sample.jsonString()))
        XCTAssertEqual(decoded, sample)
    }

    func testRowAggregatesBlobAndConfigPathFields() throws {
        var first = Self.sample(100)
        first.configPersistedMs = 80
        first.lastBlobStoredMs = 90
        first.blobsInline = 2
        first.blobsDownloaded = 1
        first.blobBytes = 30_000
        first.maxInlineBlobBytes = 20_000
        first.minDownloadedBlobBytes = 9_000

        var second = Self.sample(200)
        second.configPersistedMs = 120
        second.lastBlobStoredMs = 150
        second.blobsInline = 2
        second.blobsDownloaded = 3
        second.blobBytes = 50_000
        second.maxInlineBlobBytes = 26_000
        second.minDownloadedBlobBytes = 7_000

        let row = try self.decodedRow(warmupDiscarded: 0, samples: [first, second])

        XCTAssertEqual(row["config_persisted_ms_mean"] as? Double, 100)
        XCTAssertEqual(row["last_blob_stored_ms_mean"] as? Double, 120)
        XCTAssertEqual(row["blobs_inline_mean"] as? Double, 2)
        XCTAssertEqual(row["blobs_downloaded_mean"] as? Double, 2)
        XCTAssertEqual(row["blob_bytes_mean"] as? Double, 40_000)
        // Extremes across the run expose the backend's inline-size budget empirically.
        XCTAssertEqual(row["max_inline_blob_bytes"] as? Int, 26_000)
        XCTAssertEqual(row["min_downloaded_blob_bytes"] as? Int, 7_000)
    }

    func testRowOmitsConfigPathFieldsWhenNeverObserved() throws {
        // A legacy-variant run: no config persist, no blobs. Counts stay (provably zero);
        // timing means and size extremes are omitted rather than invented.
        let row = try self.decodedRow(warmupDiscarded: 0, samples: [Self.sample(100)])

        XCTAssertNil(row["config_persisted_ms_mean"])
        XCTAssertNil(row["last_blob_stored_ms_mean"])
        XCTAssertNil(row["max_inline_blob_bytes"])
        XCTAssertNil(row["min_downloaded_blob_bytes"])
        XCTAssertEqual(row["blobs_inline_mean"] as? Double, 0)
        XCTAssertEqual(row["blobs_downloaded_mean"] as? Double, 0)
        XCTAssertEqual(row["blob_bytes_mean"] as? Double, 0)
    }

    // MARK: - Blob log parsing

    /// The app tier observes the config path through the stock SDK's log stream, so the
    /// parser's phrases must track `RemoteConfigStrings` exactly. These build the real SDK
    /// messages; if the log copy changes, this fails instead of the app silently reporting 0.
    func testBlobLogParserMatchesRealSDKLogStrings() throws {
        let url = try XCTUnwrap(URL(string: "https://config.revenuecat-static.com/abc"))
        let downloaded = RemoteConfigStrings.storedBlob("ref-a", byteCount: 41_213, url).description
        XCTAssertEqual(
            BlobLogParser.blobEvent(from: downloaded),
            BlobStorageEvent(source: .downloaded, byteCount: 41_213)
        )

        let inline = RemoteConfigStrings.storedInlineBlob("ref-b", byteCount: 512).description
        XCTAssertEqual(
            BlobLogParser.blobEvent(from: inline),
            BlobStorageEvent(source: .inline, byteCount: 512)
        )

        let persisted = RemoteConfigStrings.persistedConfiguration(
            domain: "app", activeTopicCount: 1, referencedBlobCount: 2
        ).description
        XCTAssertTrue(BlobLogParser.isConfigPersisted(persisted))
        XCTAssertNil(BlobLogParser.blobEvent(from: persisted))

        // Fires on every config-variant launch (cold and warm): the runtime variant proof.
        let refreshing = RemoteConfigStrings.refreshing(
            domain: "app", manifestPresent: false, isAppBackgrounded: false
        ).description
        XCTAssertTrue(BlobLogParser.isConfigRefreshStarted(refreshing))
        XCTAssertFalse(BlobLogParser.isConfigRefreshStarted(persisted))

        // Terminal outcomes: a failed refresh must never pass as a config-path measurement.
        XCTAssertTrue(BlobLogParser.isConfigNotModified(RemoteConfigStrings.notModified.description))
        XCTAssertTrue(BlobLogParser.isConfigRefreshFailed(
            RemoteConfigStrings.refreshFailed(.missingAppUserID()).description
        ))
        XCTAssertFalse(BlobLogParser.isConfigNotModified(refreshing))
        XCTAssertFalse(BlobLogParser.isConfigRefreshFailed(refreshing))
    }

    /// The app decides "content appeared" from event-type strings it copies out of the SDK;
    /// these build the real SDK events and assert the copies still match.
    func testContentAppearedEventTypesMatchRealSDKEvents() throws {
        let paywallData = PaywallEvent.Data(
            paywallIdentifier: nil,
            offeringIdentifier: "offering",
            paywallRevision: 0,
            sessionID: .init(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false,
            source: nil,
            presentedOfferingContext: .init(offeringIdentifier: "offering")
        )
        let impression = PaywallEvent.impression(.init(), paywallData)
        let impressionType = try XCTUnwrap(impression.toMap()["type"] as? String)
        XCTAssertTrue(SDKObservedValues.contentAppearedEventTypes.contains(impressionType))

        let stepStarted = WorkflowEvent.stepStarted(.init(), .init(workflowId: "w", stepId: "s"))
        let stepType = try XCTUnwrap(stepStarted.toMap()["type"] as? String)
        XCTAssertTrue(SDKObservedValues.contentAppearedEventTypes.contains(stepType))
    }

    /// The app wipes the SDK's UserDefaults suite by a copied name (the SDK's constant is
    /// private). Behavioral pin: a value written through the SDK's own suite must be visible
    /// through a suite created with the copied name.
    func testRevenueCatUserDefaultsSuiteNameMatchesRealSDKSuite() throws {
        let key = "benchmark-suite-pin-\(UUID().uuidString)"
        UserDefaults.revenueCatSuite.set(true, forKey: key)
        defer { UserDefaults.revenueCatSuite.removeObject(forKey: key) }

        let mirror = try XCTUnwrap(
            UserDefaults(suiteName: SDKObservedValues.revenueCatUserDefaultsSuiteName)
        )
        XCTAssertTrue(mirror.bool(forKey: key))
    }

    func testBlobLogParserToleratesLoggerPrefixesAndIgnoresOtherMessages() {
        let prefixed = "[Purchases] - VERBOSE: 😻 Stored inline remote config blob 'r' with 77 bytes."
        XCTAssertEqual(BlobLogParser.blobEvent(from: prefixed)?.byteCount, 77)

        XCTAssertNil(BlobLogParser.blobEvent(from: "Prefetching 3 remote config blobs requested."))
        XCTAssertFalse(BlobLogParser.isConfigPersisted("Received remote config with 1 active topics."))
    }

}
