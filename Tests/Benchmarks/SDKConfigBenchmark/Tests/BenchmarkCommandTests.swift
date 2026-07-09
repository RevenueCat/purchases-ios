import XCTest

@testable import SDKConfigBenchmarkCore

final class BenchmarkCommandTests: BenchmarkTestCase {

    func testParseDefaults() throws {
        let command = try BenchmarkCommand.parse([])

        XCTAssertEqual(command.mode, .legacy)
        XCTAssertEqual(command.scenario, .cold)
        XCTAssertEqual(command.profileName, "ideal")
        XCTAssertEqual(command.lossPercent, 0)
        XCTAssertEqual(command.iterations, 25)
        XCTAssertEqual(command.warmupIterations, 3)
        XCTAssertEqual(command.paywallCount, 50)
        XCTAssertEqual(command.workflowCount, 100)
        XCTAssertEqual(command.seed, 42)
        XCTAssertTrue(command.annotations.isEmpty)
    }

    func testParseFullFlagSet() throws {
        let command = try BenchmarkCommand.parse([
            "--mode", "config-killswitch",
            "--scenario", "warm",
            "--profile", "lte",
            "--loss-percent", "20",
            "--iterations", "100",
            "--warmup-iterations", "5",
            "--paywalls", "10",
            "--workflows", "25",
            "--seed", "7",
            "--app-user-id", "user-1",
            "--api-key", "appl_x",
            "--annotation", "sdk_commit=abc123"
        ])

        XCTAssertEqual(command.mode, .configKillswitch)
        XCTAssertTrue(command.mode.usesRemoteConfig)
        XCTAssertEqual(command.scenario, .warm)
        XCTAssertEqual(command.profileName, "lte")
        XCTAssertEqual(command.lossPercent, 20)
        XCTAssertEqual(command.iterations, 100)
        XCTAssertEqual(command.warmupIterations, 5)
        XCTAssertEqual(command.paywallCount, 10)
        XCTAssertEqual(command.workflowCount, 25)
        XCTAssertEqual(command.seed, 7)
        XCTAssertEqual(command.appUserID, "user-1")
        XCTAssertEqual(command.apiKey, "appl_x")
        XCTAssertEqual(command.annotations["sdk_commit"], "abc123")
    }

    func testParseRejectsUnknownMode() {
        XCTAssertThrowsError(try BenchmarkCommand.parse(["--mode", "turbo"]))
    }

    func testParseRejectsUnknownFlag() {
        XCTAssertThrowsError(try BenchmarkCommand.parse(["--nope"]))
    }

    func testParseRejectsMissingValue() {
        XCTAssertThrowsError(try BenchmarkCommand.parse(["--iterations"]))
    }

    func testParseRejectsWarmupNotBelowIterations() {
        XCTAssertThrowsError(try BenchmarkCommand.parse(["--iterations", "5", "--warmup-iterations", "5"]))
    }

    func testParseRejectsOutOfRangeLoss() {
        XCTAssertThrowsError(try BenchmarkCommand.parse(["--loss-percent", "101"]))
    }

    func testParseRejectsReservedAnnotationKeys() {
        // Annotations overwriting identity or metric fields would let a row lie about what
        // was measured.
        for key in ["mode", "p50_ms", "post_warmup_error_count"] {
            XCTAssertThrowsError(try BenchmarkCommand.parse(["--annotation", "\(key)=x"]), key)
        }
    }

    // MARK: - Transport

    func testTransportDefaultsToSimulated() throws {
        XCTAssertEqual(try BenchmarkCommand.parse([]).transport, .simulated)
    }

    func testLiveTransportDefaultsToPinnedProjectAPIKey() throws {
        let command = try BenchmarkCommand.parse(["--transport", "live"])

        XCTAssertEqual(command.transport, .live)
        XCTAssertEqual(command.apiKey, BenchmarkProject.testStoreAPIKey)
    }

    func testLiveTransportLabelsThePinnedProjectByDefault() throws {
        XCTAssertEqual(try BenchmarkCommand.parse(["--transport", "live"]).projectID, BenchmarkProject.projectID)
    }

    func testLiveTransportWithCustomKeyRequiresProjectID() throws {
        XCTAssertThrowsError(try BenchmarkCommand.parse(["--transport", "live", "--api-key", "appl_other"]))

        let labeled = try BenchmarkCommand.parse(
            ["--transport", "live", "--api-key", "appl_other", "--project-id", "abc123"]
        )
        XCTAssertEqual(labeled.projectID, "abc123")
        XCTAssertEqual(labeled.apiKey, "appl_other")
    }

    func testSimulatedTransportRejectsProjectID() {
        XCTAssertThrowsError(try BenchmarkCommand.parse(["--project-id", "abc123"]))
    }

    func testLiveTransportZeroesFixtureSizeKnobs() throws {
        let command = try BenchmarkCommand.parse(["--transport", "live", "--paywalls", "500", "--workflows", "500"])

        // Live payloads come from the pinned project, so fixture sizes must not label the row.
        XCTAssertEqual(command.paywallCount, 0)
        XCTAssertEqual(command.workflowCount, 0)
    }

    func testLiveTransportRejectsSimulationOnlyKnobs() {
        XCTAssertThrowsError(try BenchmarkCommand.parse(["--transport", "live", "--loss-percent", "10"]))
        XCTAssertThrowsError(try BenchmarkCommand.parse(["--transport", "live", "--profile", "lte"]))
        XCTAssertThrowsError(try BenchmarkCommand.parse(["--transport", "live", "--mode", "config-killswitch"]))
    }

}
