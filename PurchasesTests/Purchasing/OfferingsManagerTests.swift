//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingsManagerTests.swift
//
//  Created by Juanpe Catalán on 9/8/21.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

class OfferingsManagerTests: XCTestCase {

    var mockDeviceCache: MockDeviceCache!
    let mockOperationDispatcher = MockOperationDispatcher()
    // swiftlint:disable:next force_try
    let mockSystemInfo = try! MockSystemInfo(platformInfo: Purchases.PlatformInfo(flavor: "iOS", version: "3.2.1"),
                                             finishTransactions: true)
    let mockBackend = MockBackend()
    let mockOfferingsFactory = MockOfferingsFactory()
    var mockProductsManager: MockProductsManager!
    var offeringsManager: OfferingsManager!

    override func setUp() {
        super.setUp()

        mockDeviceCache = MockDeviceCache(systemInfo: mockSystemInfo)
        mockProductsManager = MockProductsManager(systemInfo: mockSystemInfo)
        offeringsManager = OfferingsManager(deviceCache: mockDeviceCache,
                                            operationDispatcher: mockOperationDispatcher,
                                            systemInfo: mockSystemInfo,
                                            backend: mockBackend,
                                            offeringsFactory: mockOfferingsFactory,
                                            productsManager: mockProductsManager)
    }

}

extension OfferingsManagerTests {

    func testOfferingsForAppUserIDReturnsNilIfMissingStoreProduct() throws {
        // given
        mockOfferingsFactory.emptyOfferings = true
        mockBackend.stubbedGetOfferingsCompletionResult = (MockData.anyBackendOfferingsData, nil)

        // when
        var obtainedOfferings: Offerings?
        var completionCalled = false
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) { offerings, _ in
            obtainedOfferings = offerings
            completionCalled = true
        }

        // then
        expect(completionCalled).toEventually(beTrue())
        let unwrappedOfferings = try XCTUnwrap(obtainedOfferings)
        expect(unwrappedOfferings["base"]).to(beNil())
    }

    func testOfferingsForAppUserIDReturnsOfferingsIfSuccessBackendRequest() throws {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = (MockData.anyBackendOfferingsData, nil)

        // when
        var obtainedOfferings: Offerings?
        var completionCalled = false
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) { offerings, _ in
            obtainedOfferings = offerings
            completionCalled = true
        }

        // then
        expect(completionCalled).toEventually(beTrue())
        let unwrappedOfferings = try XCTUnwrap(obtainedOfferings)
        expect(unwrappedOfferings["base"]).toNot(beNil())
        expect(unwrappedOfferings["base"]!.monthly).toNot(beNil())
        expect(unwrappedOfferings["base"]!.monthly?.storeProduct).toNot(beNil())
    }

    func testOfferingsForAppUserIDReturnsNilIfFailBackendRequest() {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = (nil, MockData.unexpectedBackendResponseError)
        mockOfferingsFactory.emptyOfferings = true

        // when
        var obtainedOfferings: Offerings?
        var completionCalled = false
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) { offerings, _ in
            obtainedOfferings = offerings
            completionCalled = true
        }

        // then
        expect(completionCalled).toEventually(beTrue())
        expect(obtainedOfferings).to(beNil())
    }

    func testOfferingsForAppUserIDReturnsConfigurationErrorIfBackendReturnsEmpty() throws {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = ([:], nil)
        mockOfferingsFactory.emptyOfferings = true

        // when
        var obtainedOfferings: Offerings?
        var completionCalled = false
        var obtainedError: Error?
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) { offerings, error in
            obtainedOfferings = offerings
            completionCalled = true
            obtainedError = error
        }

        // then
        expect(completionCalled).toEventually(beTrue())
        expect(obtainedOfferings).to(beNil())
        let error = try XCTUnwrap(obtainedError)
        expect((error as NSError).code) == ErrorCode.configurationError.rawValue
    }

    func testOfferingsForAppUserIDReturnsConfigurationErrorIfProductsRequestsReturnsEmpty() throws {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = (MockData.anyBackendOfferingsData, nil)
        mockProductsManager.stubbedProductsCompletionResult = Set()

        // when
        var obtainedOfferings: Offerings?
        var completionCalled = false
        var obtainedError: Error?
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) { offerings, error in
            obtainedOfferings = offerings
            completionCalled = true
            obtainedError = error
        }

        // then
        expect(completionCalled).toEventually(beTrue())
        expect(obtainedOfferings).to(beNil())
        let error = try XCTUnwrap(obtainedError)
        expect((error as NSError).code) == ErrorCode.configurationError.rawValue
    }

    func testOfferingsForAppUserIDReturnsUnexpectedBackendResponseIfOfferingsFactoryCantCreateOfferings() throws {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = (MockData.anyBackendOfferingsData, nil)
        mockOfferingsFactory.nilOfferings = true

        // when
        var obtainedOfferings: Offerings?
        var completionCalled = false
        var obtainedError: Error?
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) { offerings, error in
            obtainedOfferings = offerings
            completionCalled = true
            obtainedError = error
        }

        // then
        expect(completionCalled).toEventually(beTrue())
        expect(obtainedOfferings).to(beNil())
        let error = try XCTUnwrap(obtainedError)
        expect((error as NSError).code) == ErrorCode.unexpectedBackendResponseError.rawValue
    }

    func testOfferingsForAppUserIDReturnsNilUnexpectedBackendResponseIfBackendReturnsNilDataAndNilOfferings() throws {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = (nil, nil)
        mockOfferingsFactory.emptyOfferings = true

        // when
        var obtainedOfferings: Offerings?
        var completionCalled = false
        var obtainedError: Error?
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) { offerings, error in
            obtainedOfferings = offerings
            completionCalled = true
            obtainedError = error
        }

        // then
        expect(completionCalled).toEventually(beTrue())
        expect(obtainedOfferings).to(beNil())
        let unwrappedError = try XCTUnwrap(obtainedError)
        expect((unwrappedError as NSError).code) == ErrorCode.unexpectedBackendResponseError.rawValue
    }

    func testOfferingsForAppUserIDReturnsUnexpectedBackendErrorIfBadBackendRequest() throws {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = (nil, MockData.unexpectedBackendResponseError)
        mockOfferingsFactory.nilOfferings = true

        // when
        var receivedError: NSError?
        var completionCalled = false
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) { _, error in
            receivedError = error as NSError?
            completionCalled = true
        }

        // then
        expect(completionCalled).toEventually(beTrue())
        let unwrappedError = try XCTUnwrap(receivedError)
        expect(unwrappedError.domain).to(equal(RCPurchasesErrorCodeDomain))
        expect(unwrappedError.code).to(be(ErrorCode.unexpectedBackendResponseError.rawValue))
    }

    func testFailBackendDeviceCacheClearsOfferingsCache() {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = (nil, MockData.unexpectedBackendResponseError)
        mockOfferingsFactory.emptyOfferings = true
        let expectedCallCount = 1

        // when
        offeringsManager.offerings(appUserID: MockData.anyAppUserID, completion: nil)

        // then
        expect(self.mockDeviceCache.setOfferingsCacheTimestampToNowCount).toEventually(equal(expectedCallCount))
        expect(self.mockBackend.invokedGetOfferingsForAppUserIDCount).toEventually(equal(expectedCallCount))
        expect(self.mockDeviceCache.clearOfferingsCacheTimestampCount).toEventually(equal(expectedCallCount))
    }

    func testUpdateOfferingsCacheOK() {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = (MockData.anyBackendOfferingsData, nil)
        let expectedCallCount = 1

        // when
        offeringsManager.offerings(appUserID: MockData.anyAppUserID, completion: nil)

        // then
        expect(self.mockDeviceCache.setOfferingsCacheTimestampToNowCount).toEventually(equal(expectedCallCount))
        expect(self.mockBackend.invokedGetOfferingsForAppUserIDCount).toEventually(equal(expectedCallCount))
        expect(self.mockDeviceCache.cacheOfferingsCount).toEventually(equal(expectedCallCount))
    }

    func testGetMissingProductIDs() {
        let productIDs: Set<String> = ["a", "b", "c"]
        let productsFromStore: Set<String> = ["a", "b"]

        expect(self.offeringsManager.getMissingProductIDs(productIDsFromStore: [],
                                                          productIDsFromBackend: productIDs)) == productIDs
        expect(self.offeringsManager.getMissingProductIDs(productIDsFromStore: productsFromStore,
                                                          productIDsFromBackend: [])) == []
        expect(self.offeringsManager.getMissingProductIDs(productIDsFromStore: productsFromStore,
                                                          productIDsFromBackend: productIDs)) == ["c"]
    }

}

private extension OfferingsManagerTests {

    enum MockData {
        static let anyAppUserID = ""
        static let anyBackendOfferingsData: [String: Any] = [
            "offerings": [
                [
                    "identifier": "base",
                    "description": "This is the base offering",
                    "packages": [
                        ["identifier": "$rc_monthly",
                         "platform_product_identifier": "monthly_freetrial"]
                    ]
                ]
            ],
            "current_offering_id": "base"
        ]
        static let unexpectedBackendResponseError = NSError(domain: RCPurchasesErrorCodeDomain,
                                                            code: ErrorCode.unexpectedBackendResponseError.rawValue,
                                                            userInfo: nil)
    }

}
