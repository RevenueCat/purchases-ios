import XCTest

@testable import SDKConfigBenchmarkCore

final class BenchmarkRunnerValidationTests: BenchmarkTestCase {

    private func events(path: String, host: String, statuses: [Int]) -> [TransportEvent] {
        let start = DispatchTime.now()
        return statuses.compactMap { status in
            guard let url = URL(string: "https://\(host)\(path)") else { return nil }
            return TransportEvent(kind: RequestKind(url: url), host: host, path: path,
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

}
