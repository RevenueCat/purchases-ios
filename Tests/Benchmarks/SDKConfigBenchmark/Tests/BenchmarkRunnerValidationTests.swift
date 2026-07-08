import XCTest

@testable import SDKConfigBenchmarkCore

final class BenchmarkRunnerValidationTests: BenchmarkTestCase {

    private func measurement(
        offeringsStatuses: [Int],
        configStatuses: [Int] = [],
        blobPaths: [String] = []
    ) -> IterationMeasurement {
        let start = DispatchTime.now()
        var events: [TransportEvent] = []
        for status in offeringsStatuses {
            events.append(TransportEvent(host: "api.revenuecat.com", path: "/v1/subscribers/u/offerings",
                                         statusCode: status, bytesReceived: 0,
                                         startedAt: start, endedAt: start, failed: false))
        }
        for status in configStatuses {
            events.append(TransportEvent(host: "api.revenuecat.com", path: "/v1/config/app",
                                         statusCode: status, bytesReceived: 0,
                                         startedAt: start, endedAt: start, failed: false))
        }
        for path in blobPaths {
            events.append(TransportEvent(host: "cdn.revenuecat.local", path: path,
                                         statusCode: 200, bytesReceived: 100,
                                         startedAt: start, endedAt: start, failed: false))
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

    func testWarmKillSwitchIterationAllowsConfig4xx() throws {
        try BenchmarkRunner.validateWarmMeasurement(
            self.measurement(offeringsStatuses: [304], configStatuses: [400]),
            mode: .configKillswitch,
            iteration: 3
        )
    }

    func testWarmIterationReDownloadingBlobsFails() {
        XCTAssertThrowsError(try BenchmarkRunner.validateWarmMeasurement(
            self.measurement(offeringsStatuses: [304], configStatuses: [204], blobPaths: ["/blobs/aaa"]),
            mode: .config,
            iteration: 3
        ))
    }

}
