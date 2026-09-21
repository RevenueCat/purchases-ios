//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DeferredTaskTests.swift
//
//  Created by Antonio Pallares on 8/18/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class DeferredTaskTests: TestCase {

    func testOperationDoesNotRunUntilStarted() async throws {
        let didRun: Atomic<Bool> = false

        let task = DeferredTask {
            didRun.value = true
        }

        await expect(didRun.value).toNever(beTrue(), until: .milliseconds(300))

        task.start()
        try await task.value

        expect(didRun.value) == true
    }

    func testValueReturnsTheOperationResult() async throws {
        let task = DeferredTask { "expected" }
        task.start()

        let value = try await task.value

        expect(value) == "expected"
    }

    func testResultCapturesAThrownError() async {
        let task = DeferredTask<Void> { throw ErrorCode.networkError }
        task.start()

        let result = await task.result

        expect { try result.get() }.to(throwError(ErrorCode.networkError))
    }

    func testWaitersResumeOnceStarted() async throws {
        let task = DeferredTask { 42 }

        let waiters = (0..<5).map { _ in Task { try await task.value } }
        task.start()

        for waiter in waiters {
            let value = try await waiter.value
            expect(value) == 42
        }
    }

    func testStartingMoreThanOnceRunsTheOperationOnce() async throws {
        let runCount: Atomic<Int> = .init(0)

        let task = DeferredTask {
            runCount.modify { $0 += 1 }
        }

        task.start()
        task.start()
        try await task.value

        expect(runCount.value) == 1
    }

    func testCancellingBeforeStartingStillRunsTheOperation() async throws {
        let didRun: Atomic<Bool> = false

        let task = DeferredTask {
            didRun.value = true
        }

        task.cancel()
        task.start()
        try await task.value

        expect(didRun.value) == true
    }
}
