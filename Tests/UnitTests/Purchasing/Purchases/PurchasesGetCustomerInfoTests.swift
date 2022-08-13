//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesGetCustomerInfoTests.swift
//
//  Created by Nacho Soto on 5/25/22.

import Nimble
import XCTest

@testable import RevenueCat

class PurchasesGetCustomerInfoTests: BasePurchasesTests {

    private static let fetchedInfoData: [String: Any] = [
        "request_date": "2020-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2020-07-17T00:05:54Z",
            "original_app_user_id": BasePurchasesTests.appUserID,
            "subscriptions": [:],
            "other_purchases": [:],
            "original_application_version": "1.0"
        ]
    ]

    func testCachedCustomerInfoHasSchemaVersion() throws {
        let info = try CustomerInfo(data: Self.emptyCustomerInfoData)

        let object = try info.asData()
        self.deviceCache.cachedCustomerInfo[self.identityManager.currentAppUserID] = object

        self.setupPurchases()

        var receivedInfo: CustomerInfo?

        purchases.getCustomerInfo { (info, _) in
            receivedInfo = info
        }

        expect(receivedInfo).toEventuallyNot(beNil())
        expect(receivedInfo?.schemaVersion).toNot(beNil())
    }

    func testCachedCustomerInfoHandlesNullSchema() throws {
        let info = try CustomerInfo(data: Self.emptyCustomerInfoData)
        let infoWithNoSchemaVersion = try info.asData(withNewSchemaVersion: NSNull())
        let fetchedInfo = try CustomerInfo(data: Self.fetchedInfoData)

        self.deviceCache.cachedCustomerInfo[self.identityManager.currentAppUserID] = infoWithNoSchemaVersion
        self.backend.overrideCustomerInfoResult = .success(fetchedInfo)

        self.setupPurchases()

        var receivedInfo: CustomerInfo?

        self.purchases.getCustomerInfo { (info, _) in
            receivedInfo = info
        }

        expect(receivedInfo).toEventually(equal(fetchedInfo))
    }

    func testSendsCachedCustomerInfoToGetter() throws {
        let info = try CustomerInfo(data: Self.emptyCustomerInfoData)

        self.deviceCache.cachedCustomerInfo[self.identityManager.currentAppUserID] = try info.asData()

        self.setupPurchases()

        var receivedInfo: CustomerInfo?

        self.purchases.getCustomerInfo { (info, _) in
            receivedInfo = info
        }

        expect(receivedInfo).toEventuallyNot(beNil())
    }

    func testCustomerInfoCompletionBlockCalledExactlyOnceWhenInfoCached() throws {
        let info = try CustomerInfo(data: Self.emptyCustomerInfoData)

        self.deviceCache.cachedCustomerInfo[self.identityManager.currentAppUserID] = try info.asData()
        self.deviceCache.stubbedIsCustomerInfoCacheStale = true

        self.setupPurchases()

        var callCount = 0

        self.purchases.getCustomerInfo { (_, _) in
            callCount += 1
        }

        expect(callCount).toEventually(equal(1))
    }

    func testDoesntSendsCachedCustomerInfoToGetterIfSchemaVersionDiffers() throws {
        let info = try CustomerInfo(data: Self.emptyCustomerInfoData)
        let infoWithBadSchema = try info.asData(withNewSchemaVersion: "bad_version")
        let fetchedInfo = try CustomerInfo(data: Self.fetchedInfoData)

        self.deviceCache.cachedCustomerInfo[self.identityManager.currentAppUserID] = infoWithBadSchema
        self.backend.overrideCustomerInfoResult = .success(fetchedInfo)

        self.setupPurchases()

        var receivedInfo: CustomerInfo?

        self.purchases.getCustomerInfo { (info, _) in
            receivedInfo = info
        }

        expect(receivedInfo).toEventually(equal(fetchedInfo))
    }

    func testDoesntSendsCachedCustomerInfoToGetterIfNoSchemaVersionInCached() throws {
        let info = try CustomerInfo(data: Self.emptyCustomerInfoData)
        let infoWithNoSchemaVersion = try info.asData(withNewSchemaVersion: nil)
        let fetchedInfo = try CustomerInfo(data: Self.fetchedInfoData)

        self.deviceCache.cachedCustomerInfo[self.identityManager.currentAppUserID] = infoWithNoSchemaVersion
        self.backend.overrideCustomerInfoResult = .success(fetchedInfo)

        self.setupPurchases()

        var receivedInfo: CustomerInfo?

        self.purchases.getCustomerInfo { (info, _) in
            receivedInfo = info
        }

        expect(receivedInfo).toEventually(equal(fetchedInfo))
    }

    func testDoesntSendCacheIfNoCacheAndCallsBackendAgain() {
        self.setupPurchases()

        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))

        self.deviceCache.cachedCustomerInfo = [:]

        self.purchases.getCustomerInfo { (_, _) in }

        expect(self.backend.getSubscriberCallCount) == 2
    }

    func testFetchCustomerInfoWhenCacheStale() {
        self.setupPurchases()

        self.deviceCache.stubbedIsCustomerInfoCacheStale = true

        self.purchases.getCustomerInfo { (_, _) in }

        expect(self.backend.getSubscriberCallCount).toEventually(equal(2))
    }

    func testGetCustomerInfoAfterInvalidatingDoesntReturnCachedVersion() throws {
        self.setupPurchases()

        let appUserID = self.identityManager.currentAppUserID
        let oldAppUserInfo = Data()
        self.deviceCache.cache(customerInfo: oldAppUserInfo, appUserID: appUserID)
        let overrideCustomerInfo = try CustomerInfo(data: Self.emptyCustomerInfoData)
        self.backend.overrideCustomerInfoResult = .success(overrideCustomerInfo)

        var receivedCustomerInfo: CustomerInfo?
        var completionCallCount = 0
        var receivedError: Error?
        self.purchases.getCustomerInfo { (customerInfo, error) in
            completionCallCount += 1
            receivedError = error
            receivedCustomerInfo = customerInfo
        }

        self.purchases.invalidateCustomerInfoCache()

        expect(completionCallCount).toEventually(equal(1))
        expect(receivedError).to(beNil())
        expect(receivedCustomerInfo) == overrideCustomerInfo
        expect(self.purchasesDelegate.customerInfoReceivedCount) == 1
    }

    func testGetCustomerInfoAfterInvalidatingCallsCompletionWithErrorIfBackendError() {
        let backendError: BackendError = .networkError(
            .unexpectedResponse(nil)
        )
        self.backend.overrideCustomerInfoResult = .failure(backendError)

        self.setupPurchases()

        expect(self.purchasesDelegate.customerInfoReceivedCount) == 0

        let appUserID = identityManager.currentAppUserID
        let oldAppUserInfo = Data()
        self.deviceCache.cache(customerInfo: oldAppUserInfo, appUserID: appUserID)

        var receivedCustomerInfo: CustomerInfo?
        var completionCallCount = 0
        var receivedError: Error?

        self.purchases.getCustomerInfo { (customerInfo, error) in
            completionCallCount += 1
            receivedError = error
            receivedCustomerInfo = customerInfo
        }

        self.purchases.invalidateCustomerInfoCache()

        expect(completionCallCount).toEventually(equal(1))
        expect(receivedError).toNot(beNil())
        expect(receivedCustomerInfo).to(beNil())
        expect(self.purchasesDelegate.customerInfoReceivedCount) == 0
    }

    func testInvalidateCustomerInfoCacheRemovesCachedCustomerInfo() {
        setupPurchases()
        guard let nonOptionalPurchases = purchases else { fatalError("failed when setting up purchases for testing") }
        let appUserID = identityManager.currentAppUserID
        self.deviceCache.cache(customerInfo: Data(), appUserID: appUserID)
        expect(self.deviceCache.cachedCustomerInfoData(appUserID: appUserID)).toNot(beNil())
        expect(self.deviceCache.invokedClearCustomerInfoCacheCount) == 0

        nonOptionalPurchases.invalidateCustomerInfoCache()
        expect(self.deviceCache.cachedCustomerInfoData(appUserID: appUserID)).to(beNil())
        expect(self.deviceCache.invokedClearCustomerInfoCacheCount) == 1
    }

}
