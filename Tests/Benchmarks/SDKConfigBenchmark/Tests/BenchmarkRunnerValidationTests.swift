import XCTest

@testable import SDKConfigBenchmarkCore

final class BenchmarkRunnerValidationTests: BenchmarkTestCase {

    private func events(path: String, host: String, statuses: [Int]) -> [TransportEvent] {
        let start = DispatchTime.now()
        return statuses.compactMap { status in
            guard let url = URL(string: "https://\(host)\(path)") else { return nil }
            return TransportEvent(kind: RequestKind(url: url), iteration: 0, host: host, path: path,
                                  statusCode: status, bytesReceived: 0,
                                  startedAt: start, endedAt: start, failed: false)
        }
    }

    private func measurement(
        offeringsStatuses: [Int],
        configStatuses: [Int] = [],
        blobPaths: [String] = []
    ) -> IterationMeasurement {
        var events = self.events(path: "/v1/subscribers/u/offerings",
                                 host: "api.revenuecat.com",
                                 statuses: offeringsStatuses)
        events += self.events(path: "/v1/config/app", host: "api.revenuecat.com", statuses: configStatuses)
        for path in blobPaths {
            events += self.events(path: path, host: "cdn.revenuecat.local", statuses: [200])
        }
        return IterationMeasurement(totalMs: 1, events: events)
    }

    func testWarmLegacyIterationWithOnly304Passes() throws {
        try BenchmarkRunner.validateWarmMeasurement(
            self.measurement(offeringsStatuses: [304]),
            mode: .legacy,
            iteration: 3
        )
    }

    func testWarmIterationWithFull200OfferingsFails() {
        XCTAssertThrowsError(try BenchmarkRunner.validateWarmMeasurement(
            self.measurement(offeringsStatuses: [200]),
            mode: .legacy,
            iteration: 3
        ))
    }

    func testWarmIterationMixing304And200Fails() {
        XCTAssertThrowsError(try BenchmarkRunner.validateWarmMeasurement(
            self.measurement(offeringsStatuses: [304, 200]),
            mode: .legacy,
            iteration: 3
        ))
    }

    func testWarmConfigIterationRequires204() {
        XCTAssertThrowsError(try BenchmarkRunner.validateWarmMeasurement(
            self.measurement(offeringsStatuses: [304], configStatuses: [200]),
            mode: .config,
            iteration: 3
        ))

        XCTAssertNoThrow(try BenchmarkRunner.validateWarmMeasurement(
            self.measurement(offeringsStatuses: [304], configStatuses: [204]),
            mode: .config,
            iteration: 3
        ))
    }

    func testWarmKillSwitchIterationRequiresConfig4xx() throws {
        try BenchmarkRunner.validateWarmMeasurement(
            self.measurement(offeringsStatuses: [304], configStatuses: [400]),
            mode: .configKillswitch,
            iteration: 3
        )

        // Missing the config request, or getting a non-4xx, means the kill switch was not
        // actually exercised and the row would measure something else.
        XCTAssertThrowsError(try BenchmarkRunner.validateWarmMeasurement(
            self.measurement(offeringsStatuses: [304]),
            mode: .configKillswitch,
            iteration: 3
        ))
        XCTAssertThrowsError(try BenchmarkRunner.validateWarmMeasurement(
            self.measurement(offeringsStatuses: [304], configStatuses: [200]),
            mode: .configKillswitch,
            iteration: 3
        ))
    }

    func testWarmIterationReDownloadingBlobsFails() {
        XCTAssertThrowsError(try BenchmarkRunner.validateWarmMeasurement(
            self.measurement(offeringsStatuses: [304], configStatuses: [204], blobPaths: ["/blobs/aaa"]),
            mode: .config,
            iteration: 3
        ))
    }

    // MARK: - Blob accounting

    func testBlobAccountingCountsOnlyRefsStoredThisIterationAndAttributesByRequest() throws {
        let store = InMemoryBlobStore(contents: [
            "pre-existing": Data(count: 100),
            "inline-new": Data(count: 2_000),
            "cdn-new": Data(count: 8_000)
        ])
        let url = try XCTUnwrap(URL(string: "https://cdn.revenuecat.local/blobs/cdn-new"))
        let events = [
            TransportEvent.success(url: url, iteration: 0, statusCode: 200,
                                   bytesReceived: 8_000, startedAt: DispatchTime.now())
        ]

        let accounting = BenchmarkRunner.blobAccounting(
            blobStore: store,
            refsBeforeLaunch: ["pre-existing"],
            events: events
        )

        XCTAssertEqual(accounting.inlineCount, 1)
        XCTAssertEqual(accounting.downloadedCount, 1)
        XCTAssertEqual(accounting.totalBytes, 10_000)
        XCTAssertEqual(accounting.maxInlineBytes, 2_000)
        XCTAssertEqual(accounting.minDownloadedBytes, 8_000)
    }

    func testBlobAccountingIsEmptyForLegacyModeWithoutABlobStore() {
        let accounting = BenchmarkRunner.blobAccounting(blobStore: nil, refsBeforeLaunch: [], events: [])

        XCTAssertEqual(accounting.inlineCount, 0)
        XCTAssertEqual(accounting.downloadedCount, 0)
        XCTAssertNil(accounting.maxInlineBytes)
        XCTAssertNil(accounting.minDownloadedBytes)
    }

}

private final class InMemoryBlobStore: RemoteConfigBlobStoreType {

    private var contents: [String: Data]

    init(contents: [String: Data]) {
        self.contents = contents
    }

    func contains(ref: String) -> Bool { return self.contents[ref] != nil }
    func read(ref: String) -> Data? { return self.contents[ref] }
    func write(ref: String, bytes: UnsafeRawBufferPointer) -> Bool {
        self.contents[ref] = Data(bytes.bindMemory(to: UInt8.self))
        return true
    }
    func cachedRefs() -> Set<String> { return Set(self.contents.keys) }
    func retainOnly(_ refs: Set<String>) { self.contents = self.contents.filter { refs.contains($0.key) } }
    func clear() { self.contents = [:] }

}
