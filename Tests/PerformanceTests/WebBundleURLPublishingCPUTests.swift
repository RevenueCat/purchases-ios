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

/// Measures CPU usage while transiently decoding several workflows and publishing their web-bundle URLs.
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
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        var failure: Error?
        self.measure(metrics: [XCTCPUMetric(), XCTClockMetric()], options: options) {
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
    }

}
