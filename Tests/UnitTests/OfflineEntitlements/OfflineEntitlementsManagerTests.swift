//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfflineEntitlementsManagerTests.swift
//
//  Created by Nacho Soto on 3/22/23.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@MainActor
class BaseOfflineEntitlementsManagerTests: TestCase {

    let mockBackend = MockBackend()
    var mockSystemInfo: MockSystemInfo!

    var mockDeviceCache: MockDeviceCache!
    let mockOperationDispatcher = MockOperationDispatcher()
    var mockOfflineEntitlements: MockOfflineEntitlementsAPI!

    var manager: OfflineEntitlementsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockSystemInfo = MockSystemInfo(finishTransactions: true)
        self.mockOfflineEntitlements = try XCTUnwrap(
            self.mockBackend.offlineEntitlements as? MockOfflineEntitlementsAPI
        )
        self.mockDeviceCache = MockDeviceCache(sandboxEnvironmentDetector: self.mockSystemInfo)
        self.manager = self.createManager()
    }

    fileprivate func createManager() -> OfflineEntitlementsManager {
        return OfflineEntitlementsManager(deviceCache: self.mockDeviceCache,
                                          operationDispatcher: self.mockOperationDispatcher,
                                          api: self.mockOfflineEntitlements,
                                          systemInfo: self.mockSystemInfo)
    }

}

class OfflineEntitlementsManagerAvailableTests: BaseOfflineEntitlementsManagerTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        // These tests only run on iOS 15+
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testUpdateEntitlementsCacheForCustomEntitlementComputation() {
        self.mockSystemInfo = MockSystemInfo(finishTransactions: true, customEntitlementsComputation: true)
        self.manager = self.createManager()

        let result = waitUntilValue { completion in
            self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false) {
                completion($0)
            }
        }

        expect(result).to(beFailure())
        expect(result?.error).to(matchError(OfflineEntitlementsManager.Error.notAvailable))
    }

    func testUpdateEntitlementsCacheForObserverMode() {
        self.mockSystemInfo = MockSystemInfo(finishTransactions: false)
        self.manager = self.createManager()

        let result = waitUntilValue { completion in
            self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false) {
                completion($0)
            }
        }

        expect(result).to(beFailure())
        expect(result?.error).to(matchError(OfflineEntitlementsManager.Error.notAvailable))
    }

    func testUpdateProductsEntitlementsCacheDoesNotUpdateIfNotStale() {
        self.mockDeviceCache.stubbedIsProductEntitlementMappingCacheStale = false

        let result = waitUntilValue { completion in
            self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false) {
                completion($0)
            }
        }
        expect(result).to(beSuccess())

        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping) == false
    }

    func testUpdateProductEntitlementMappingCacheUpdatesIfStaleSuccess() {
        let mapping: ProductEntitlementMappingResponse = .init(products: [
            "a": .init(identifier: "a", entitlements: ["pro_1", "pro_2"])
        ])
        let isAppBackgrounded: Bool = .random()

        self.mockDeviceCache.stubbedIsProductEntitlementMappingCacheStale = true
        self.mockOfflineEntitlements.stubbedGetProductEntitlementMappingResult = .success(mapping)

        let result = waitUntilValue { completion in
            self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: isAppBackgrounded) {
                completion($0)
            }
        }
        expect(result).to(beSuccess())

        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping) == true
        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMappingCount) == 1
        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMappingParameter) == isAppBackgrounded
    }

    func testUpdateProductEntitlementMappingCacheDoesNotUpdateIfStaleFailure() {
        let expectedError: BackendError = .missingAppUserID()

        self.mockDeviceCache.stubbedIsProductEntitlementMappingCacheStale = true
        self.mockOfflineEntitlements.stubbedGetProductEntitlementMappingResult = .failure(expectedError)

        let result = waitUntilValue { completion in
            self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false) {
                completion($0)
            }
        }
        expect(result).to(beFailure())
        expect(result?.error).to(matchError(OfflineEntitlementsManager.Error.backend(expectedError)))

        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping) == true
        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMappingCount) == 1
    }

    func testShouldComputeOfflineCustomerInfo() {
        expect(self.manager.shouldComputeOfflineCustomerInfo(appUserID: "test")) == true
    }

    func testShouldNotComputeOfflineCustomerInfoIfThereIsACachedCustomerInfo() {
        self.mockDeviceCache.cachedCustomerInfo["test"] = Data()

        expect(self.manager.shouldComputeOfflineCustomerInfo(appUserID: "test")) == false
    }

}

// swiftlint:disable:next type_name
class OfflineEntitlementsManagerUnavailableTests: BaseOfflineEntitlementsManagerTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            throw XCTSkip("This test is for older devices.")
        }
    }

    func testUpdateEntitlementsCacheReturnsNotAvailable() {
        let result = waitUntilValue { completion in
            self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false) {
                completion($0)
            }
        }

        expect(result).to(beFailure())
        expect(result?.error).to(matchError(OfflineEntitlementsManager.Error.notAvailable))
    }

}
