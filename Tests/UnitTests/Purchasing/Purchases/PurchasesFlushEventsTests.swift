//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesFlushEventsTests.swift
//
//  Created by Antonio Pallares on 26/12/25.

import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PurchasesFlushEventsTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()
    }

    func testAppWillEnterForegroundTriggersFlushEventsWithDelay() async throws {
        /// Reset any previous invocations from previous tests
        self.mockOperationDispatcher.invokedDispatchOnWorkerThread = false
        self.mockOperationDispatcher.invokedDispatchOnWorkerThreadDelayParam = nil

        self.notificationCenter.fireApplicationWillEnterForegroundNotification()

        let mockEventsManager = try self.mockEventsManager

        await expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThread).toEventually(beTrue())
        expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == .long
        expect(mockEventsManager.invokedFlushAllEventsWithBackgroundTask.value).to(beTrue())
    }

    func testAppWillResignActiveTriggersFlushEventsWithoutDelay() async throws {
        self.notificationCenter.fireApplicationWillResignActiveNotification()

        let mockEventsManager = try self.mockEventsManager

        expect(mockEventsManager.invokedFlushAllEventsWithBackgroundTask.value).to(beTrue())
    }

    func testAppDidBecomeActiveDoesNotTriggerFlushEvents() async throws {
        try self.notificationCenter.fireApplicationDidBecomeActiveNotification()

        self.mockOperationDispatcher.invokedDispatchOnWorkerThread = false
        self.mockOperationDispatcher.invokedDispatchAsyncOnWorkerThread = false

        let mockEventsManager = try self.mockEventsManager
        await expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThread).toAlways(beFalse())
        await expect(self.mockOperationDispatcher.invokedDispatchAsyncOnWorkerThread).toAlways(beFalse())
        await expect(mockEventsManager.invokedFlushAllEventsWithBackgroundTask.value)
            .toAlways(beFalse())
    }

    func testAppDidEnterBackgroundDoesNotTriggerFlushEvents() async throws {
        self.notificationCenter.fireApplicationDidEnterBackgroundNotification()

        self.mockOperationDispatcher.invokedDispatchOnWorkerThread = false
        self.mockOperationDispatcher.invokedDispatchAsyncOnWorkerThread = false

        let mockEventsManager = try self.mockEventsManager
        await expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThread).toAlways(beFalse())
        await expect(self.mockOperationDispatcher.invokedDispatchAsyncOnWorkerThread).toAlways(beFalse())
        await expect(mockEventsManager.invokedFlushAllEventsWithBackgroundTask.value)
            .toAlways(beFalse())
    }

}
