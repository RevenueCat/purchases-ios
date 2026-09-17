//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OperationDispatcherTests.swift
//
//  Created by Nacho Soto on 9/7/23.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

class OperationDispatcherTests: TestCase {

    func testDelayForBackgroundedApp() {
        expect(JitterableDelay.default(forBackgroundedApp: true)) == .default
    }

    func testDelayForForegroundedApp() {
        expect(JitterableDelay.default(forBackgroundedApp: false)) == JitterableDelay.none
    }

    func testNoDelay() {
        expect(JitterableDelay.none.hasDelay) == false
        expect(JitterableDelay.none.range) == 0..<0
    }

    func testDefaultDelay() {
        expect(JitterableDelay.default.hasDelay) == true
        expect(JitterableDelay.default.range) == 0..<5
    }

    func testLongDelay() {
        expect(JitterableDelay.long.hasDelay) == true
        expect(JitterableDelay.long.range) == 5..<10
    }

    func testNoPendingAsyncOperationsByDefault() {
        expect(OperationDispatcher().pendingAsyncOperationCount) == 0
    }

    func testAsyncOperationIsPendingFromDispatchUntilItFinishes() async throws {
        let dispatcher = OperationDispatcher()
        let canFinish: Atomic<Bool> = false
        let finished: Atomic<Bool> = false

        dispatcher.dispatchOnWorkerThread {
            await Self.wait(until: canFinish)
            finished.value = true
        }

        // The operation is counted synchronously, before the task has had a chance to run.
        expect(dispatcher.pendingAsyncOperationCount) == 1

        canFinish.value = true
        try await dispatcher.waitForPendingAsyncOperations(timeout: .seconds(2))

        expect(finished.value) == true
        expect(dispatcher.pendingAsyncOperationCount) == 0
    }

    func testWaitingForPendingAsyncOperationsFailsWhileWorkRemains() async throws {
        let dispatcher = OperationDispatcher()
        let canFinish: Atomic<Bool> = false
        defer { canFinish.value = true }

        dispatcher.dispatchOnWorkerThread {
            await Self.wait(until: canFinish)
        }

        var threw = false
        let assertions = await gatherExpectations(silently: true) {
            do {
                try await dispatcher.waitForPendingAsyncOperations(timeout: .milliseconds(10))
            } catch {
                threw = true
            }
        }

        expect(threw) == true
        let failure = try XCTUnwrap(assertions.onlyElement)
        expect(failure.success) == false
        expect(failure.message.stringValue).to(contain("1 operations remain"))
    }

    func testPendingAsyncOperationsAreCountedPerDispatcher() async throws {
        let dispatcher = OperationDispatcher()
        let otherDispatcher = OperationDispatcher()
        let canFinish: Atomic<Bool> = false

        dispatcher.dispatchOnWorkerThread {
            await Self.wait(until: canFinish)
        }

        expect(dispatcher.pendingAsyncOperationCount) == 1
        expect(otherDispatcher.pendingAsyncOperationCount) == 0

        canFinish.value = true
        try await dispatcher.waitForPendingAsyncOperations(timeout: .seconds(2))
    }

}

private extension OperationDispatcherTests {

    static func wait(until condition: Atomic<Bool>) async {
        while !condition.value {
            try? await Task.sleep(nanoseconds: UInt64(defaultPollInterval.nanoseconds))
        }
    }

}
