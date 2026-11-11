//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBundleURLPublishingCPUTests.swift
//
//  Created by Rick van der Linden on 11/10/26.

import Foundation
@testable import RevenueCat
import XCTest

/// Measures CPU usage while transiently decoding several workflows, publishing web-bundle URLs, and optionally
/// prewarming their paywall assets through deterministic file and font sinks.
// swiftlint:disable:next xctestcase_superclass
final class WebBundleURLPublishingCPUTests: XCTestCase {

    private var workload: WorkflowPrewarmingWorkload!
    private var previousLogLevel: LogLevel = .info

    override func setUp() async throws {
        try await super.setUp()
        self.previousLogLevel = Purchases.logLevel
        Purchases.logLevel = .error
        let fixture = try PerformanceFixture.multipleWorkflowWebBundleURLFixture()
        self.workload = try await WorkflowPrewarmingWorkload.load(
            sourceFixture: fixture.sourceFixture,
            workflowCount: fixture.workflowCount
        )
    }

    override func tearDown() {
        self.workload?.close()
        self.workload = nil
        Purchases.logLevel = self.previousLogLevel
        super.tearDown()
    }

    func testCPUTimeAcrossMultipleWorkflows() throws {
        try self.measureCPU(includingAssetPrewarming: false, testName: #function)
    }

    func testCPUTimeAcrossMultipleWorkflowsIncludingAssetPrewarming() throws {
        try self.measureCPU(includingAssetPrewarming: true, testName: #function)
    }

    private func measureCPU(includingAssetPrewarming: Bool, testName: String) throws {
        let metric = RecordingCPUMetric(limitingToCurrentThread: false)
        let failuresBeforeMeasurement = self.testRun?.failureCount
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        var failure: Error?
        self.measure(metrics: [metric, XCTClockMetric()], options: options) {
            do {
                let context = try self.waitForCompletion {
                    try await self.workload.prepareIteration(includingAssetPrewarming: includingAssetPrewarming)
                }
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
        let cpuInstructions = metric.samples.cpuInstructionsThousands.dropFirst()
        XCTAssertEqual(cpuInstructions.count, options.iterationCount)
        guard cpuInstructions.count == options.iterationCount else { return }
        try PerformanceBaseline.checkOrRecordCPU(
            cpuInstructionsThousands: cpuInstructions.reduce(0, +) / Double(cpuInstructions.count),
            tolerancePercent: 10,
            testName: "\(type(of: self))/\(testName)",
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
