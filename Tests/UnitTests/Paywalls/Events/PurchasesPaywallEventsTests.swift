//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesPaywallEventsTests.swift
//
//  Created by Nacho Soto on 9/8/23.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PurchasesPaywallEventsTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setupPurchases()
    }

    func testApplicationWillEnterForegroundSendsEvents() async throws {
        self.notificationCenter.fireNotifications()

        let manager = try self.mockPaywallEventsManager

        try await asyncWait { await manager.invokedFlushEvents == true }

        expect(self.mockOperationDispatcher.invokedDispatchAsyncOnWorkerThreadDelayParam) == .long
    }

}
