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

        expect(self.storeKit1Wrapper.delegate).toNot(beNil())

        self.purchases.delegate = self.purchasesDelegate

        expect(self.storeKit1Wrapper.delegate).toNot(beNil())
    }

    func testSubscribesToUIApplicationWillEnterForeground() throws {
        expect(self.notificationCenter.observers).to(haveCount(2))

        let (_, _, name, _) = try XCTUnwrap(self.notificationCenter.observers.first)
        expect(name) == SystemInfo.applicationWillEnterForegroundNotification
    }

    #if os(iOS) || VISION_OS

    // We shouldn't use this notification because it's called when
    // apps lose focus when presenting popups during a purchase.
    func testDoesNotSubscribeToUIApplicationDidBecomeActive() throws {
        expect(self.notificationCenter.observers)
            .toNot(containElementSatisfying { _, _, name, _ in
                name == UIApplication.didBecomeActiveNotification
            })
    }

    #endif

    func testTriggersCallToBackend() {
        self.notificationCenter.fireNotifications()
        expect(self.backend.userID).toEventuallyNot(beNil())
    }

    func testAutomaticallyFetchesCustomerInfoOnWillEnterForegroundIfCacheStale() {
        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(1))

        self.deviceCache.stubbedIsCustomerInfoCacheStale = true
        self.clock.advance(by: SystemInfo.cacheUpdateThrottleDuration + .seconds(1))

        self.notificationCenter.fireNotifications()

        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(2))
    }

    func testDoesntAutomaticallyFetchCustomerInfoOnWillEnterForegroundIfCacheValid() {
        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(1))
        self.deviceCache.stubbedIsCustomerInfoCacheStale = false

        self.notificationCenter.fireNotifications()

        expect(self.backend.getCustomerInfoCallCount) == 1
    }

    func testDoesNotFetchCustomerInfoTwiceOnAppLaunch() {
        self.deviceCache.stubbedIsCustomerInfoCacheStale = true

        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(1))

        self.notificationCenter.fireNotifications()
        expect(self.backend.getCustomerInfoCallCount) == 1
        expect(self.deviceCache.cachedCustomerInfoCount) == 1
    }

    func testForegroundingAppMultipleTimesDoesNotFetchCustomerInfoRepeteadly() {
        self.deviceCache.stubbedIsCustomerInfoCacheStale = true

        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(1))

        for _ in 0..<10 {
            self.notificationCenter.fireNotifications()
        }

        expect(self.backend.getCustomerInfoCallCount) == 1
        expect(self.deviceCache.cachedCustomerInfoCount) == 1
    }

    func testAutomaticallyCallsDelegateOnDidBecomeActiveAndUpdate() {
        self.notificationCenter.fireNotifications()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testDoesntRemoveObservationWhenDelegateNil() {
        self.purchases.delegate = nil

        expect(self.notificationCenter.observers).to(haveCount(2))
    }

    // See https://github.com/RevenueCat/purchases-ios/issues/2410
    func testDelegateWithGetCustomerInfoCallDoesNotDeadlock() throws {
        final class GetCustomerInfoPurchasesDelegate: NSObject, PurchasesDelegate {
            func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
                purchases.getCustomerInfo { _, _ in }
            }
        }

        let delegate = GetCustomerInfoPurchasesDelegate()
        self.purchases.delegate = delegate

        let offerings = self.offeringsFactory.createOfferings(from: [:], data: .mockResponse)
        let package = try XCTUnwrap(offerings?.all["base"]?.monthly)

        waitUntil { completion in
            self.purchases.purchase(package: package) { _, _, _, _ in
                completion()
            }

            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKit1Wrapper.payment!
            transaction.mockState = .purchasing

            self.storeKit1Wrapper.delegate?.storeKit1Wrapper(self.storeKit1Wrapper,
                                                             updatedTransaction: transaction)

            self.backend.postReceiptResult = .success(.emptyInfo)

            transaction.mockState = .purchased
            self.storeKit1Wrapper.delegate?.storeKit1Wrapper(self.storeKit1Wrapper,
                                                             updatedTransaction: transaction)
        }
    }

}
