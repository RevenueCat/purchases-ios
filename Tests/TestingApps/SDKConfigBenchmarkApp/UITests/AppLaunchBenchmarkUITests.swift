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
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.continueAfterFailure = false
    }

    func testColdLaunches() throws {
        let configuration = try self.configuration()

        // A fresh user and wiped state every launch: each iteration is a true cold start.
        let samples = (0..<configuration.iterations).map { iteration in
            self.launchAndCollect(
                configuration: configuration,
                appUserID: "bench-app-cold-\(configuration.runNonce)-\(iteration)",
                wipeState: true
            )
        }

        self.report(samples: samples, scenario: "cold", configuration: configuration)
    }

    func testWarmLaunches() throws {
        let configuration = try self.configuration()
        let appUserID = "bench-app-warm-\(configuration.runNonce)"

        // One uncounted priming launch populates the disk caches; measured launches then
        // relaunch with retained state and the same user.
        _ = self.launchAndCollect(configuration: configuration, appUserID: appUserID, wipeState: true)
        let samples = (0..<configuration.iterations).map { _ in
            self.launchAndCollect(configuration: configuration, appUserID: appUserID, wipeState: false)
        }

        self.report(samples: samples, scenario: "warm", configuration: configuration)
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
            runNonce: UUID().uuidString.lowercased().prefix(8).description
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

    private func report(samples: [LaunchSample?], scenario: String, configuration: Configuration) {
        let row = AppLaunchMetrics.row(
            mode: configuration.modeLabel,
            scenario: scenario,
            profile: Self.profile,
            projectID: configuration.projectID,
            warmupDiscarded: configuration.warmup,
            samples: samples
        )

        // The script greps this prefix out of the xcodebuild log to build the JSONL file.
        print("BENCHMARK_ROW: \(row)")
        let attachment = XCTAttachment(string: row)
        attachment.name = "benchmark-row-\(scenario)"
        attachment.lifetime = .keepAlways
        self.add(attachment)

        let postWarmupErrors = samples.enumerated()
            .filter { $0.offset >= configuration.warmup }
            .compactMap { AppLaunchMetrics.errorMessage(for: $0.element) }
        XCTAssertTrue(
            postWarmupErrors.isEmpty,
            "\(postWarmupErrors.count) measured launch(es) failed; first: \(postWarmupErrors.first ?? "")"
        )
    }

    private static var profile: String {
        #if targetEnvironment(simulator)
        return "simulator"
        #else
        return "device"
        #endif
    }

}
