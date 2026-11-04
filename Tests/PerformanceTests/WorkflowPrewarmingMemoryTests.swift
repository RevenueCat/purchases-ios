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

import XCTest

final class WorkflowPrewarmingMemoryTests: PerformanceTestCase {

    private var workload: WorkflowPrewarmingWorkload!

    override func setUp() async throws {
        try await super.setUp()
        self.workload = try await WorkflowPrewarmingWorkload.load()
    }

    override func tearDown() {
        self.workload?.close()
        self.workload = nil
        super.tearDown()
    }

    func testPublishWebBundleURLsPeakMemory() throws {
        try self.measureMemory(
            workloadSHA256: self.workload.sha256,
            tolerancePercent: 10,
            prepare: { try await self.workload.prepareIteration() },
            operation: { await $0.run() },
            validate: { $0.validate() }
        )
    }

}
