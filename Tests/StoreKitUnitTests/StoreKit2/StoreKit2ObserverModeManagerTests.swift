//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2ObserverModeManagerTests.swift
//
//  Created by Will Taylor on 5/1/24.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class StoreKit2ObserverModeManagerTests: StoreKitConfigTestCase {

    private let appUserID = "mockAppUserID"

    private var observerModeManager: StoreKit2ObserverModeManager!

    private var notificationCenter: MockNotificationCenter!

    private var storeKit2ObserverModePurchaseDetector: MockStoreKit2ObserverModePurchaseDetector!

    override func setUp() async throws {
        try await super.setUp()
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        notificationCenter = .init()
        storeKit2ObserverModePurchaseDetector = .init()

        self.observerModeManager = .init(
            storeKit2ObserverModePurchaseListener: storeKit2ObserverModePurchaseDetector,
            notificationCenter: notificationCenter
        )
    }

    func testBeginObservingPurchasesCallsNotificationCenter() {
        observerModeManager.beginObservingPurchases()

        expect(self.notificationCenter.observers.count) == 1
        guard let observer = notificationCenter.observers.first else {
            fail("There must be at least one observer.")
            return
        }

        expect(observer.notificationName) == SystemInfo.applicationDidBecomeActiveNotification
        expect(observer.selector) == #selector(StoreKit2ObserverModeManager.applicationDidBecomeActive)
        expect(observer.object) == nil
    }

    func testApplicationDidBecomeActiveCallsDetectUnobservedTransactions() throws {
        observerModeManager.applicationDidBecomeActive()

        expect(self.storeKit2ObserverModePurchaseDetector.detectUnobservedTransactionsCalled).toEventually(
            beTrue(),
            description: "The detectUnobservedTransactions method should have been called"
        )
        expect(self.storeKit2ObserverModePurchaseDetector.detectUnobservedTransactionsCalledCount).toEventually(
            equal(1),
            description: "detectUnobservedTransactions should be called exactly once"
        )
    }
}
