//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesDelegateTests.swift
//
//  Created by Nacho Soto on 5/31/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesDelegateTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()
    }

    func testDoesntSetWrapperDelegateToNilIfDelegateNil() {
        self.purchases.delegate = nil

        expect(self.storeKitWrapper.delegate).toNot(beNil())

        self.purchases.delegate = self.purchasesDelegate

        expect(self.storeKitWrapper.delegate).toNot(beNil())
    }

    func testSubscribesToUIApplicationDidBecomeActive() throws {
        expect(self.notificationCenter.observers).to(haveCount(2))

        let (_, _, name, _) = try XCTUnwrap(self.notificationCenter.observers.first)
        expect(name) == SystemInfo.applicationDidBecomeActiveNotification
    }

    func testTriggersCallToBackend() {
        self.notificationCenter.fireNotifications()
        expect(self.backend.userID).toEventuallyNot(beNil())
    }

    func testAutomaticallyFetchesCustomerInfoOnDidBecomeActiveIfCacheStale() {
        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))

        self.deviceCache.stubbedIsCustomerInfoCacheStale = true
        self.notificationCenter.fireNotifications()

        expect(self.backend.getSubscriberCallCount).toEventually(equal(2))
    }

    func testDoesntAutomaticallyFetchCustomerInfoOnDidBecomeActiveIfCacheValid() {
        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))
        self.deviceCache.stubbedIsCustomerInfoCacheStale = false

        self.notificationCenter.fireNotifications()

        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))
    }

    func testAutomaticallyCallsDelegateOnDidBecomeActiveAndUpdate() {
        self.notificationCenter.fireNotifications()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testDoesntRemoveObservationWhenDelegateNil() {
        self.purchases.delegate = nil

        expect(self.notificationCenter.observers).to(haveCount(2))
    }

}
