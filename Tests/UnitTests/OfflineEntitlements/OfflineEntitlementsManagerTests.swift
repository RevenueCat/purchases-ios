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

class BaseOfflineEntitlementsManagerTests: TestCase {

    let mockBackend = MockBackend()
    var mockSystemInfo: MockSystemInfo!

    var mockDeviceCache: MockDeviceCache!
    var mockOfflineEntitlements: MockOfflineEntitlementsAPI!
    var mockProductEntitlementMappingTopicProvider: MockEntitlementMappingTopicProvider!

    var manager: OfflineEntitlementsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockSystemInfo = MockSystemInfo(finishTransactions: true)
        self.mockOfflineEntitlements = try XCTUnwrap(
            self.mockBackend.offlineEntitlements as? MockOfflineEntitlementsAPI
        )
        self.mockDeviceCache = MockDeviceCache(systemInfo: self.mockSystemInfo)
        self.mockProductEntitlementMappingTopicProvider = MockEntitlementMappingTopicProvider()
        self.manager = self.createManager()
    }

    fileprivate func createManager() -> OfflineEntitlementsManager {
        let manager = OfflineEntitlementsManager(deviceCache: self.mockDeviceCache,
                                                 api: self.mockOfflineEntitlements,
                                                 systemInfo: self.mockSystemInfo)
        manager.setProductEntitlementMappingTopicProvider(self.mockProductEntitlementMappingTopicProvider)
        return manager
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

        self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false)

        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping) == false
        expect(self.mockProductEntitlementMappingTopicProvider.invokedGetProductEntitlementMappingCount) == 0
    }

    func testUpdateEntitlementsCacheForObserverMode() {
        self.mockSystemInfo = MockSystemInfo(finishTransactions: false)
        self.manager = self.createManager()

        self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false)

        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping) == false
        expect(self.mockProductEntitlementMappingTopicProvider.invokedGetProductEntitlementMappingCount) == 0
    }

    func testUpdateProductsEntitlementsCacheDoesNotUpdateIfNotStale() {
        self.mockDeviceCache.stubbedIsProductEntitlementMappingCacheStale = false

        self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false)

        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping) == false
        expect(self.mockProductEntitlementMappingTopicProvider.invokedGetProductEntitlementMappingCount) == 0
    }

    func testUpdateProductEntitlementMappingCacheUsesRemoteConfig() async throws {
        let mapping: ProductEntitlementMappingResponse = .init(products: [
            "a": .init(identifier: "a", entitlements: ["pro_1", "pro_2"])
        ])
        self.mockDeviceCache.stubbedIsProductEntitlementMappingCacheStale = true
        self.mockProductEntitlementMappingTopicProvider.stubbedProductEntitlementMapping = mapping

        self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false)

        await expect(self.mockDeviceCache.cachedProductEntitlementMapping).toEventually(equal(mapping.toMapping()))
        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping) == false
        expect(self.mockProductEntitlementMappingTopicProvider.invokedGetProductEntitlementMappingCount) == 1
    }

    func testConcurrentUpdatesShareOneRemoteConfigTask() async {
        let mapping: ProductEntitlementMappingResponse = .init(products: [
            "a": .init(identifier: "a", entitlements: ["pro"])
        ])
        self.mockDeviceCache.stubbedIsProductEntitlementMappingCacheStale = true
        self.mockProductEntitlementMappingTopicProvider.getProductEntitlementMappingHandler = {
            try? await Task.sleep(nanoseconds: 50_000_000)
            return ProductEntitlementMappingResult(response: mapping) { operation in
                operation(mapping)
                return true
            }
        }
        self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false)
        self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false)

        await expect(self.mockDeviceCache.cachedProductEntitlementMapping).toEventually(equal(mapping.toMapping()))
        expect(self.mockProductEntitlementMappingTopicProvider.invokedGetProductEntitlementMappingCount) == 1
    }

    func testUnavailableRemoteConfigMappingFallsBackToLegacyEndpoint() async {
        let mapping: ProductEntitlementMappingResponse = .init(products: [
            "legacy": .init(identifier: "legacy", entitlements: ["pro"])
        ])
        self.mockDeviceCache.stubbedIsProductEntitlementMappingCacheStale = true
        self.mockOfflineEntitlements.stubbedGetProductEntitlementMappingResult = .success(mapping)

        self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false)

        await expect(self.mockDeviceCache.cachedProductEntitlementMapping).toEventually(equal(mapping.toMapping()))
        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping) == true
    }

    func testDisabledRemoteConfigFallsBackToLegacyEndpoint() async {
        let remoteConfigManager = NoOpRemoteConfigManager()
        self.manager.setProductEntitlementMappingTopicProvider(
            ProductEntitlementMappingTopicProvider(manager: remoteConfigManager)
        )
        let mapping: ProductEntitlementMappingResponse = .init(products: [
            "legacy": .init(identifier: "legacy", entitlements: ["pro"])
        ])
        self.mockDeviceCache.stubbedIsProductEntitlementMappingCacheStale = true
        self.mockOfflineEntitlements.stubbedGetProductEntitlementMappingResult = .success(mapping)

        self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false)

        await expect(self.mockDeviceCache.cachedProductEntitlementMapping).toEventually(equal(mapping.toMapping()))
        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping) == true
    }

    func testDisabledRemoteConfigEnqueuesLegacyRequestSynchronously() {
        self.manager.setProductEntitlementMappingTopicProvider(
            ProductEntitlementMappingTopicProvider(manager: NoOpRemoteConfigManager())
        )
        self.mockDeviceCache.stubbedIsProductEntitlementMappingCacheStale = true

        self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false)

        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping) == true
    }

    func testInvalidatedRemoteConfigMappingFallsBackToLegacyEndpoint() async {
        let remoteMapping: ProductEntitlementMappingResponse = .init(products: [
            "remote": .init(identifier: "remote", entitlements: ["pro"])
        ])
        let legacyMapping: ProductEntitlementMappingResponse = .init(products: [
            "legacy": .init(identifier: "legacy", entitlements: ["pro"])
        ])
        self.mockDeviceCache.stubbedIsProductEntitlementMappingCacheStale = true
        self.mockProductEntitlementMappingTopicProvider.stubbedProductEntitlementMapping = remoteMapping
        self.mockProductEntitlementMappingTopicProvider.stubbedUseIfCurrent = false
        self.mockOfflineEntitlements.stubbedGetProductEntitlementMappingResult = .success(legacyMapping)

        self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false)

        await expect(self.mockDeviceCache.cachedProductEntitlementMapping)
            .toEventually(equal(legacyMapping.toMapping()))
        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping) == true
    }

    func testCloseCancelsRemoteConfigReadWithoutStartingLegacyFallback() async {
        self.mockDeviceCache.stubbedIsProductEntitlementMappingCacheStale = true
        self.mockProductEntitlementMappingTopicProvider.getProductEntitlementMappingHandler = {
            do {
                try await Task.sleep(nanoseconds: 60_000_000_000)
            } catch {}
            return nil
        }

        self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false)
        await Task.yield()
        self.manager.close()
        await Task.yield()

        expect(self.mockProductEntitlementMappingTopicProvider.invokedGetProductEntitlementMappingCount) == 1
        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping) == false
    }

    func testUpdateProductEntitlementMappingCacheUpdatesIfStaleSuccess() async {
        let mapping: ProductEntitlementMappingResponse = .init(products: [
            "a": .init(identifier: "a", entitlements: ["pro_1", "pro_2"])
        ])
        let isAppBackgrounded: Bool = .random()

        self.mockDeviceCache.stubbedIsProductEntitlementMappingCacheStale = true
        self.mockOfflineEntitlements.stubbedGetProductEntitlementMappingResult = .success(mapping)

        self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: isAppBackgrounded)

        await expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping).toEventually(beTrue())
        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMappingCount) == 1
        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMappingParameter) == isAppBackgrounded
        expect(self.mockDeviceCache.cachedProductEntitlementMapping) == mapping.toMapping()
    }

    func testUpdateProductEntitlementMappingCacheDoesNotUpdateIfStaleFailure() async {
        let expectedError: BackendError = .missingAppUserID()
        let cachedMapping = self.mockDeviceCache.cachedProductEntitlementMapping

        self.mockDeviceCache.stubbedIsProductEntitlementMappingCacheStale = true
        self.mockOfflineEntitlements.stubbedGetProductEntitlementMappingResult = .failure(expectedError)

        self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false)

        await expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping).toEventually(beTrue())
        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMappingCount) == 1
        expect(self.mockDeviceCache.cachedProductEntitlementMapping) == cachedMapping
    }

    func testShouldComputeOfflineCustomerInfo() {
        expect(self.manager.shouldComputeOfflineCustomerInfo(appUserID: "test")) == true
    }

    func testShouldNotComputeOfflineCustomerInfoIfThereIsACachedCustomerInfo() {
        self.mockDeviceCache.cachedCustomerInfo["test"] = Data()

        expect(self.manager.shouldComputeOfflineCustomerInfo(appUserID: "test")) == false
    }

    // MARK: - Test Store

    func testShouldComputeOfflineCustomerInfoReturnsFalseForTestStore() {
        self.mockSystemInfo = MockSystemInfo(finishTransactions: true, apiKeyValidationResult: .simulatedStore)
        let testStoreManager = createManager()

        expect(testStoreManager.shouldComputeOfflineCustomerInfo(appUserID: "test")) == false
    }

}

final class EntitlementMappingTopicProviderTests: TestCase {

    private var remoteConfigManager: MockRemoteConfigManager!
    private var provider: ProductEntitlementMappingTopicProvider!

    override func setUp() {
        super.setUp()

        self.remoteConfigManager = MockRemoteConfigManager()
        self.provider = ProductEntitlementMappingTopicProvider(manager: self.remoteConfigManager)
    }

    func testReturnsDecodedDefaultBlob() async throws {
        let mapping: ProductEntitlementMappingResponse = .init(products: [
            "monthly": .init(identifier: "monthly", entitlements: ["pro"])
        ])
        self.remoteConfigManager.stubbedBlobData[.productEntitlementMapping] = [
            "default": try JSONEncoder.default.encode(mapping)
        ]

        let result = await self.provider.getProductEntitlementMapping()

        expect(result?.response) == mapping
        expect(self.remoteConfigManager.invokedBlobDataParameters.count) == 1
        expect(self.remoteConfigManager.invokedBlobDataParameters.first?.topic)
            == .productEntitlementMapping
        expect(self.remoteConfigManager.invokedBlobDataParameters.first?.itemKey) == "default"
    }

    func testReturnsNilWhenBlobIsUnavailable() async {
        let result = await self.provider.getProductEntitlementMapping()

        expect(result).to(beNil())
    }

    func testReturnsNilWhenBlobCannotBeDecoded() async {
        self.remoteConfigManager.stubbedBlobData[.productEntitlementMapping] = [
            "default": "{ invalid json".asData
        ]

        let result = await self.provider.getProductEntitlementMapping()

        expect(result).to(beNil())
    }

    func testReturnsNilWhenRemoteConfigManagerIsReleased() async {
        self.remoteConfigManager = nil

        let result = await self.provider.getProductEntitlementMapping()

        expect(result).to(beNil())
    }

    func testResultIsRejectedWhenRemoteConfigChangesBeforeUse() async throws {
        let mapping: ProductEntitlementMappingResponse = .init(products: [
            "monthly": .init(identifier: "monthly", entitlements: ["pro"])
        ])
        self.remoteConfigManager.stubbedBlobData[.productEntitlementMapping] = [
            "default": try JSONEncoder.default.encode(mapping)
        ]
        let result = await self.provider.getProductEntitlementMapping()

        self.remoteConfigManager.clearCache()

        expect(result?.useIfCurrent { _ in }).to(beFalse())
    }

    func testReturnsNilWhenRemoteConfigChangesDuringBlobRead() async throws {
        let mapping: ProductEntitlementMappingResponse = .init(products: [
            "monthly": .init(identifier: "monthly", entitlements: ["pro"])
        ])
        self.remoteConfigManager.stubbedBlobData[.productEntitlementMapping] = [
            "default": try JSONEncoder.default.encode(mapping)
        ]
        self.remoteConfigManager.shouldStoreBlobDataCompletion = true

        async let result = self.provider.getProductEntitlementMapping()
        await expect(self.remoteConfigManager.invokedBlobDataParameters).toEventuallyNot(beEmpty())
        self.remoteConfigManager.clearCache()
        self.remoteConfigManager.completeStoredBlobReads()

        let resolvedResult = await result
        expect(resolvedResult).to(beNil())
    }

}

final class MockEntitlementMappingTopicProvider: EntitlementMappingTopicProviderType {

    var isAvailable = true
    var stubbedProductEntitlementMapping: ProductEntitlementMappingResponse?
    var stubbedUseIfCurrent = true
    var getProductEntitlementMappingHandler: (() async -> ProductEntitlementMappingResult?)?
    private(set) var invokedGetProductEntitlementMappingCount = 0

    func getProductEntitlementMapping() async -> ProductEntitlementMappingResult? {
        self.invokedGetProductEntitlementMappingCount += 1
        if let handler = self.getProductEntitlementMappingHandler {
            return await handler()
        }
        guard let mapping = self.stubbedProductEntitlementMapping else { return nil }
        return ProductEntitlementMappingResult(response: mapping) { operation in
            guard self.stubbedUseIfCurrent else { return false }
            operation(mapping)
            return true
        }
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

    func testUpdateEntitlementsCacheDoesNothingWhenUnavailable() {
        self.manager.updateProductsEntitlementsCacheIfStale(isAppBackgrounded: false)

        expect(self.mockOfflineEntitlements.invokedGetProductEntitlementMapping) == false
        expect(self.mockProductEntitlementMappingTopicProvider.invokedGetProductEntitlementMappingCount) == 0
    }

}
