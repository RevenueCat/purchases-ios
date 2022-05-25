//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesConfiguringTests.swift
//
//  Created by Nacho Soto on 5/25/22.

import Nimble
import XCTest

@testable import RevenueCat

class PurchasesConfiguringTests: BasePurchasesTests {

    func testIsAbleToBeInitialized() {
        self.setupPurchases()
        expect(self.purchases).toNot(beNil())
    }

    func testUsingSharedInstanceWithoutInitializingThrowsAssertion() {
        let expectedMessage = "Purchases has not been configured. Please call Purchases.configure()"
        expectFatalError(expectedMessage: expectedMessage) { _ = Purchases.shared }
    }

    func testUsingSharedInstanceAfterInitializingDoesntThrowAssertion() {
        self.setupPurchases()
        expectNoFatalError { _ = Purchases.shared }
    }

    func testIsConfiguredReturnsCorrectvalue() {
        expect(Purchases.isConfigured) == false
        self.setupPurchases()
        expect(Purchases.isConfigured) == true
    }

    func testConfigurationPassedThroughTimeouts() {
        let networkTimeoutSeconds: TimeInterval = 9
        let configurationBuilder = Configuration.Builder(withAPIKey: "")
            .with(networkTimeout: networkTimeoutSeconds)
            .with(storeKit1Timeout: networkTimeoutSeconds)
        let purchases = Purchases.configure(with: configurationBuilder.build())

        expect(purchases.networkTimeout) == networkTimeoutSeconds
        expect(purchases.storeKitTimeout) == networkTimeoutSeconds
    }

    func testSharedInstanceIsSetWhenConfiguring() {
        let purchases = Purchases.configure(withAPIKey: "")
        expect(Purchases.shared) === purchases
    }

    func testSharedInstanceIsSetWhenConfiguringWithConfiguration() {
        let configurationBuilder = Configuration.Builder(withAPIKey: "")
        let purchases = Purchases.configure(with: configurationBuilder.build())
        expect(Purchases.shared) === purchases
    }

    func testSharedInstanceIsSetWhenConfiguringWithAppUserID() {
        let purchases = Purchases.configure(withAPIKey: "", appUserID: "")
        expect(Purchases.shared) === purchases
    }

    func testSharedInstanceIsSetWhenConfiguringWithObserverMode() {
        let purchases = Purchases.configure(withAPIKey: "", appUserID: "", observerMode: true)
        expect(Purchases.shared) === purchases
        expect(Purchases.shared.finishTransactions) == false
    }

    func testSharedInstanceIsSetWhenConfiguringWithAppUserIDAndUserDefaults() {
        let purchases = Purchases.configure(withAPIKey: "", appUserID: "", observerMode: false, userDefaults: nil)
        expect(Purchases.shared) === purchases
        expect(Purchases.shared.finishTransactions) == true
    }

    func testSharedInstanceIsSetWhenConfiguringWithAppUserIDAndUserDefaultsAndUseSK2() {
        let purchases = Purchases.configure(withAPIKey: "",
                                            appUserID: "",
                                            observerMode: false,
                                            userDefaults: nil,
                                            useStoreKit2IfAvailable: true)
        expect(Purchases.shared) === purchases
        expect(Purchases.shared.finishTransactions) == true
    }

    func testFirstInitializationCallDelegate() {
        self.setupPurchases()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testFirstInitializationFromForegroundDelegateForAnonIfNothingCached() {
        self.systemInfo.stubbedIsApplicationBackgrounded = false
        self.setupPurchases()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testFirstInitializationFromBackgroundDoesntCallDelegateForAnonIfNothingCached() {
        self.systemInfo.stubbedIsApplicationBackgrounded = true
        self.setupPurchases()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(0))
    }

    func testFirstInitializationFromBackgroundCallsDelegateForAnonIfInfoCached() throws {
        self.systemInfo.stubbedIsApplicationBackgrounded = true
        let info = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])

        let object = try info.asData()
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object

        self.setupPurchases()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testFirstInitializationFromBackgroundDoesntUpdateCustomerInfoCache() {
        self.systemInfo.stubbedIsApplicationBackgrounded = true
        self.setupPurchases()
        expect(self.backend.getSubscriberCallCount).toEventually(equal(0))
    }

    func testFirstInitializationFromForegroundUpdatesCustomerInfoCacheIfNotInUserDefaults() {
        self.systemInfo.stubbedIsApplicationBackgrounded = false
        self.setupPurchases()
        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))
    }

    func testFirstInitializationFromForegroundUpdatesCustomerInfoCacheIfUserDefaultsCacheStale() {
        let staleCacheDateForForeground = Calendar.current.date(byAdding: .minute, value: -20, to: Date())!
        self.deviceCache.setCustomerInfoCache(timestamp: staleCacheDateForForeground,
                                              appUserID: identityManager.currentAppUserID)
        self.systemInfo.stubbedIsApplicationBackgrounded = false

        self.setupPurchases()

        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))
    }

    func testFirstInitializationFromForegroundUpdatesCustomerInfoEvenIfCacheValid() {
        let staleCacheDateForForeground = Calendar.current.date(byAdding: .minute, value: -2, to: Date())!
        self.deviceCache.setCustomerInfoCache(timestamp: staleCacheDateForForeground,
                                              appUserID: identityManager.currentAppUserID)

        self.systemInfo.stubbedIsApplicationBackgrounded = false

        self.setupPurchases()

        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))
    }

}
