//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppLaunchBenchmarkUITests.swift
//
//  Created by Facundo Menzella on 9/7/26.

import XCTest

/// Relaunches the benchmark app once per iteration (each launch is a real process cold
/// start), reads the `LaunchSample` the app exposes, and aggregates one JSONL row per
/// scenario, printed as `BENCHMARK_ROW: {...}` for `run-app-launch.sh` to collect.
///
/// Configured via the runner's environment (pass with a `TEST_RUNNER_` prefix through
/// xcodebuild): `BENCH_API_KEY` (required), `BENCH_MODE_LABEL` (required; identifies the
/// SDK build variant, e.g. `app-launch-legacy`), `BENCH_ITERATIONS`, `BENCH_WARMUP`,
/// `BENCH_PROJECT_ID`. Both tests skip when the required variables are absent, so running
/// the scheme without the script does not produce mislabeled rows.
final class AppLaunchBenchmarkUITests: XCTestCase {

    private struct Configuration {
        let apiKey: String
        let modeLabel: String
        let iterations: Int
        let warmup: Int
        let projectID: String
        let runNonce: String
        /// When set (via `BENCH_EXPECT_CONFIG_PATH` = "1"/"0"), every measured launch must
        /// report the matching `configPathActive`: runtime proof, from inside the launched
        /// binary, that the SDK build variant matches the row's label even on cached builds.
        let expectsConfigPath: Bool?
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.continueAfterFailure = false
    }

    func testColdLaunches() throws {
        let configuration = try self.configuration()

        // A fresh user and wiped state every launch: each iteration is a true cold start.
        var retries = 0
        let samples = (0..<configuration.iterations).map { iteration in
            self.launchCollectingWithRetry(
                configuration: configuration,
                appUserID: "bench-app-cold-\(configuration.runNonce)-\(iteration)",
                wipeState: true,
                retries: &retries
            )
        }

        self.report(samples: samples, scenario: "cold", configuration: configuration, retries: retries)
    }

    func testWarmLaunches() throws {
        let configuration = try self.configuration()
        let appUserID = "bench-app-warm-\(configuration.runNonce)"

        // One uncounted priming launch populates the disk caches; measured launches then
        // relaunch with retained state and the same user. The priming launch must succeed:
        // if it left the caches empty, every "warm" sample would actually be a cold start.
        let priming = self.launchAndCollect(configuration: configuration, appUserID: appUserID, wipeState: true)
        if let primingError = AppLaunchMetrics.errorMessage(for: priming) {
            XCTFail("Warm priming launch failed (\(primingError)); samples would measure cold starts")
            return
        }

        var retries = 0
        let samples = (0..<configuration.iterations).map { _ in
            self.launchCollectingWithRetry(
                configuration: configuration,
                appUserID: appUserID,
                wipeState: false,
                retries: &retries
            )
        }

        self.report(samples: samples, scenario: "warm", configuration: configuration, retries: retries)
    }

    // MARK: -

    private func configuration() throws -> Configuration {
        let environment = ProcessInfo.processInfo.environment
        guard let apiKey = environment["BENCH_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("BENCH_API_KEY not set; run via run-app-launch.sh")
        }
        guard let modeLabel = environment["BENCH_MODE_LABEL"], !modeLabel.isEmpty else {
            throw XCTSkip("BENCH_MODE_LABEL not set; the row cannot name its SDK build variant")
        }

        let iterations = environment["BENCH_ITERATIONS"].flatMap(Int.init) ?? 10
        let warmup = environment["BENCH_WARMUP"].flatMap(Int.init) ?? 2
        guard iterations > 0, warmup >= 0, warmup < iterations else {
            throw XCTSkip("BENCH_WARMUP (\(warmup)) must be below BENCH_ITERATIONS (\(iterations))")
        }

        return Configuration(
            apiKey: apiKey,
            modeLabel: modeLabel,
            iterations: iterations,
            warmup: warmup,
            projectID: environment["BENCH_PROJECT_ID"] ?? "5f07e7e3",
            runNonce: UUID().uuidString.lowercased().prefix(8).description,
            expectsConfigPath: environment["BENCH_EXPECT_CONFIG_PATH"].map { $0 == "1" }
        )
    }

    /// One launch, retried once when it produced nothing at all (element never appeared:
    /// a simulator hiccup or a >90s stall). At hundreds of iterations a ~1% harness flake
    /// is expected; a retry is a fresh, unbiased sample, and the retry COUNT lands in the
    /// row so censored launches stay visible. A sample that reports an error is NOT
    /// retried: that is a real measured failure.
    private func launchCollectingWithRetry(
        configuration: Configuration,
        appUserID: String,
        wipeState: Bool,
        retries: inout Int
    ) -> LaunchSample? {
        if let sample = self.launchAndCollect(
            configuration: configuration, appUserID: appUserID, wipeState: wipeState
        ) {
            return sample
        }
        retries += 1
        return self.launchAndCollect(
            configuration: configuration, appUserID: appUserID, wipeState: wipeState
        )
    }

    private func launchAndCollect(
        configuration: Configuration,
        appUserID: String,
        wipeState: Bool
    ) -> LaunchSample? {
        let app = XCUIApplication()
        app.launchEnvironment = [
            "BENCH_API_KEY": configuration.apiKey,
            "BENCH_APP_USER_ID": appUserID
        ]
        app.launchArguments = wipeState ? ["--wipe-state"] : []
        app.launch()
        defer { app.terminate() }

        let result = app.staticTexts["benchmark-result"]
        guard result.waitForExistence(timeout: 90) else {
            return nil
        }
        return LaunchSample.decode(from: result.label)
    }

    private func report(
        samples: [LaunchSample?],
        scenario: String,
        configuration: Configuration,
        retries: Int
    ) {
        // A retried launch is a fresh sample, but the retry budget stays small: pervasive
        // retries mean the environment is unstable and the whole round is suspect.
        let retryBudget = max(1, configuration.iterations / 50)
        XCTAssertLessThanOrEqual(
            retries, retryBudget,
            "\(retries) launches produced nothing and were retried (budget \(retryBudget)); environment unstable"
        )

        let row = AppLaunchMetrics.row(
            mode: configuration.modeLabel,
            scenario: scenario,
            profile: Self.profile,
            projectID: configuration.projectID,
            warmupDiscarded: configuration.warmup,
            samples: samples,
            launchRetries: retries
        )

        // The script greps this prefix out of the xcodebuild log to build the JSONL file.
        print("BENCHMARK_ROW: \(row)")
        let attachment = XCTAttachment(string: row)
        attachment.name = "benchmark-row-\(scenario)"
        attachment.lifetime = .keepAlways
        self.add(attachment)

        // One definition of "measured sample" (post-warmup, by index) for every assertion,
        // matching the window the row's statistics were aggregated from.
        let measured = samples.enumerated().filter { $0.offset >= configuration.warmup }

        let postWarmupErrors = measured.compactMap { AppLaunchMetrics.errorMessage(for: $0.element) }
        XCTAssertTrue(
            postWarmupErrors.isEmpty,
            "\(postWarmupErrors.count) measured launch(es) failed; first: \(postWarmupErrors.first ?? "")"
        )

        // Runtime variant proof: the launched binary must have actually run (or not run)
        // the config path; a mislabeled row would poison every later comparison.
        if let expectsConfigPath = configuration.expectsConfigPath {
            let mismatches = measured
                .filter { ($0.element?.configPathActive ?? false) != expectsConfigPath }
            XCTAssertTrue(
                mismatches.isEmpty,
                "\(mismatches.count) launch(es) contradict the \(configuration.modeLabel) label " +
                "(expected configPathActive == \(expectsConfigPath)); wrong SDK variant in the binary?"
            )

            // An active config path is not enough: a failed refresh silently falls back to
            // legacy delivery, so the row would measure the wrong system with clean timings.
            // Cold launches must persist a fresh config; warm launches must revalidate via
            // the manifest 204 (a fresh persist on warm means the caches were not warm),
            // matching the CLI tier's warm validation.
            if expectsConfigPath {
                let acceptedOutcomes = scenario == "cold" ? ["persisted"] : ["not_modified"]
                let badOutcomes = measured
                    .map { ($0.offset, $0.element?.configOutcome ?? "none") }
                    .filter { !acceptedOutcomes.contains($0.1) }
                XCTAssertTrue(
                    badOutcomes.isEmpty,
                    "\(badOutcomes.count) config-variant launch(es) lack a successful config outcome " +
                    "(accepted: \(acceptedOutcomes)); first: iteration \(badOutcomes.first?.0 ?? -1) " +
                    "= \(badOutcomes.first?.1 ?? "")"
                )
            }
        }
    }

    private static var profile: String {
        #if targetEnvironment(simulator)
        return "simulator"
        #else
        return "device"
        #endif
    }

}
