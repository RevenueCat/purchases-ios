import XCTest

@testable import SDKConfigBenchmarkCore

/// End-to-end: real `OfferingsManager` (and `RemoteConfigManager` for config modes) against
/// the simulated transport. These are the tests that prove the benchmark measures the actual
/// SDK flows rather than a hand-rolled imitation of them.
final class BenchmarkSDKStackTests: BenchmarkTestCase {

    private let factory = BenchmarkPayloadFactory(paywallCount: 3, workflowCount: 4)

    override func tearDown() {
        SimulatedTransportURLProtocol.uninstall()
        super.tearDown()
    }

    private func install(killSwitch: Bool = false) {
        SimulatedTransportURLProtocol.install(
            server: FixtureServer(factory: self.factory, killSwitchConfig: killSwitch),
            profile: .ideal,
            loss: LossModel(lossPercent: 0),
            seed: 42
        )
    }

    private func fetchOfferings(
        _ stack: BenchmarkSDKStack,
        appUserID: String,
        timeout: TimeInterval = 15
    ) throws -> Offerings {
        let expectation = self.expectation(description: "offerings delivered")
        let result = LockedResult<Result<Offerings, OfferingsManager.Error>>()
        stack.offeringsManager.offerings(appUserID: appUserID, fetchCurrent: true) { offerings in
            result.set(offerings)
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: timeout)
        return try XCTUnwrap(result.get()).get()
    }

    func testLegacyModeFetchesOfferingsWithSingleRequest() throws {
        self.install()
        let stack = BenchmarkSDKStack(mode: .legacy, apiKey: "appl_benchmark", appUserID: "legacy-user")
        stack.clearAllDiskState()

        let offerings = try self.fetchOfferings(stack, appUserID: "legacy-user")

        XCTAssertEqual(offerings.all.count, 3)
        XCTAssertNotNil(offerings.current)

        let events = SimulatedTransportURLProtocol.drainEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertTrue(events[0].path.hasSuffix("/offerings"))
    }

    func testConfigModeFetchesConfigBlobsAndOfferings() throws {
        self.install()
        let stack = BenchmarkSDKStack(mode: .config, apiKey: "appl_benchmark", appUserID: "config-user")
        stack.clearAllDiskState()

        stack.refreshRemoteConfigIfWired()
        let offerings = try self.fetchOfferings(stack, appUserID: "config-user")

        XCTAssertEqual(offerings.all.count, 3)

        let events = SimulatedTransportURLProtocol.drainEvents()
        let paths = events.map(\.path)
        XCTAssertTrue(paths.contains { $0.hasSuffix("/config/app") }, "expected a config fetch in \(paths)")
        XCTAssertTrue(paths.contains { $0.contains("/blobs/") }, "expected blob downloads in \(paths)")
        XCTAssertTrue(paths.contains { $0.hasSuffix("/offerings") }, "expected an offerings fetch in \(paths)")

        // The workflows topic marks every workflow blob prefetch, so offerings delivery waits
        // for all of them plus the two ui_config blobs.
        let blobRequests = paths.filter { $0.contains("/blobs/") }
        XCTAssertEqual(Set(blobRequests).count, 4 + 2)
    }

    func testKillSwitchModeStillDeliversOfferings() throws {
        self.install(killSwitch: true)
        let stack = BenchmarkSDKStack(mode: .configKillswitch, apiKey: "appl_benchmark", appUserID: "kill-user")
        stack.clearAllDiskState()

        stack.refreshRemoteConfigIfWired()
        let offerings = try self.fetchOfferings(stack, appUserID: "kill-user")

        XCTAssertEqual(offerings.all.count, 3)
        XCTAssertEqual(stack.remoteConfigManager?.isDisabled, true, "4xx must trip the session kill switch")

        let events = SimulatedTransportURLProtocol.drainEvents()
        let paths = events.map(\.path)
        XCTAssertTrue(paths.contains { $0.hasSuffix("/config/app") })
        XCTAssertFalse(paths.contains { $0.contains("/blobs/") }, "no blobs after a config 4xx")
    }

    func testWarmRelaunchServes304And204() throws {
        self.install()

        // Priming launch populates etags, offerings disk cache, and the persisted config.
        let priming = BenchmarkSDKStack(mode: .config, apiKey: "appl_benchmark", appUserID: "warm-user")
        priming.clearAllDiskState()
        priming.refreshRemoteConfigIfWired()
        _ = try self.fetchOfferings(priming, appUserID: "warm-user")
        _ = SimulatedTransportURLProtocol.drainEvents()

        // Simulated relaunch: fresh in-memory stack, retained disk state.
        let relaunch = BenchmarkSDKStack(mode: .config, apiKey: "appl_benchmark", appUserID: "warm-user")
        relaunch.refreshRemoteConfigIfWired()
        _ = try self.fetchOfferings(relaunch, appUserID: "warm-user")

        let events = SimulatedTransportURLProtocol.drainEvents()
        let statusesByPath = Dictionary(
            events.map { ($0.path, $0.statusCode) },
            uniquingKeysWith: { first, _ in first }
        )

        XCTAssertTrue(
            statusesByPath.contains { $0.key.hasSuffix("/offerings") && $0.value == 304 },
            "warm offerings must be revalidated via 304, got \(statusesByPath)"
        )
        XCTAssertTrue(
            statusesByPath.contains { $0.key.hasSuffix("/config/app") && $0.value == 204 },
            "warm config must be revalidated via manifest 204, got \(statusesByPath)"
        )
        XCTAssertFalse(
            statusesByPath.contains { $0.key.contains("/blobs/") },
            "warm relaunch must not re-download blobs, got \(statusesByPath)"
        )
    }

}

private final class LockedResult<Value>: @unchecked Sendable {

    private let lock = NSLock()
    private var value: Value?

    func set(_ value: Value) {
        self.lock.withLock { self.value = value }
    }

    func get() -> Value? {
        return self.lock.withLock { self.value }
    }

}
