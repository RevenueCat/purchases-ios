//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowPrewarmingMemoryTests.swift
//

import Foundation
@testable import RevenueCat
import XCTest

// swiftlint:disable:next xctestcase_superclass
final class WorkflowPrewarmingMemoryTests: XCTestCase {

    private var workload: WorkflowPrewarmingWorkload!
    private var previousLogLevel: LogLevel = .info

    override func setUp() async throws {
        try await super.setUp()
        self.previousLogLevel = Purchases.logLevel
        Purchases.logLevel = .error
        self.workload = try await WorkflowPrewarmingWorkload.load()
    }

    override func tearDown() {
        self.workload?.close()
        self.workload = nil
        Purchases.logLevel = self.previousLogLevel
        super.tearDown()
    }

    func testPublishWebBundleURLsPeakMemory() throws {
        let metric = RecordingMemoryMetric()
        let failuresBeforeMeasurement = self.testRun?.failureCount
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        var failure: Error?
        self.measure(metrics: [metric, XCTClockMetric()], options: options) {
            do {
                let context = try self.waitForCompletion { try await self.workload.prepareIteration() }
                self.startMeasuring()
                do {
                    defer { self.stopMeasuring() }
                    try self.waitForCompletion { await context.run() }
                }
                context.validate()
            } catch {
                failure = error
            }
        }
        if let failure { throw failure }
        guard self.testRun?.failureCount == failuresBeforeMeasurement else { return }
        // XCTest excludes the first iteration from its results.
        let peaks = metric.samples.peaksMiB.dropFirst()
        XCTAssertEqual(peaks.count, options.iterationCount)
        guard peaks.count == options.iterationCount else { return }
        try PerformanceBaseline.checkOrRecordMemory(
            peakMemoryMiB: peaks.reduce(0, +) / Double(peaks.count),
            tolerancePercent: 10,
            testName: "\(type(of: self))/\(#function)",
            workloadSHA256: self.workload.sha256,
            environment: try self.baselineEnvironment(),
            record: ProcessInfo.processInfo.environment["RECORD_PERFORMANCE_BASELINES"] == "1"
        )
    }

    private func baselineEnvironment() throws -> [String: String] {
        let environment = ProcessInfo.processInfo.environment
        #if arch(arm64)
        let architecture = "arm64"
        #else
        let architecture = "x86_64"
        #endif
        return [
            "architecture": architecture,
            "model": try XCTUnwrap(environment["SIMULATOR_MODEL_IDENTIFIER"]),
            "os": ProcessInfo.processInfo.operatingSystemVersionString,
            "xcodeBuild": try XCTUnwrap(Bundle(for: Self.self)
                .object(forInfoDictionaryKey: "PerformanceXcodeBuild") as? String)
        ]
    }

}
