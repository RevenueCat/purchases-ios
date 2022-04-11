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
    let mockSystemInfo = try! MockSystemInfo(platformInfo: .init(flavor: "iOS", version: "3.2.1"),
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
        mockBackend.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)

        // when
        var result: Result<Offerings, OfferingsManager.Error>?
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
            result = $0
        }

        // then
        expect(result).toEventuallyNot(beNil())
        expect(result).to(beSuccess())

        let unwrappedOfferings = try XCTUnwrap(result?.value)
        expect(unwrappedOfferings["base"]).to(beNil())
    }

    func testOfferingsForAppUserIDReturnsOfferingsIfSuccessBackendRequest() throws {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)

        // when
        var result: Result<Offerings, OfferingsManager.Error>?
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
            result = $0
        }

        // then
        expect(result).toEventuallyNot(beNil())

        let unwrappedOfferings = try XCTUnwrap(result?.value)
        expect(unwrappedOfferings["base"]).toNot(beNil())
        expect(unwrappedOfferings["base"]!.monthly).toNot(beNil())
        expect(unwrappedOfferings["base"]!.monthly?.storeProduct).toNot(beNil())
    }

    func testOfferingsForAppUserIDReturnsNilIfFailBackendRequest() {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = .failure(MockData.unexpectedBackendResponseError)
        mockOfferingsFactory.emptyOfferings = true

        // when
        var result: Result<Offerings, OfferingsManager.Error>?
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
            result = $0
        }

        // then
        expect(result).toEventuallyNot(beNil())
        expect(result).to(beFailure())
        expect(result?.error) == .backendError(.unexpectedBackendResponse(.customerInfoNil))
    }

    func testOfferingsForAppUserIDReturnsConfigurationErrorIfBackendReturnsEmpty() throws {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = .success(
            .init(currentOfferingId: "", offerings: [])
        )
        mockOfferingsFactory.emptyOfferings = true

        // when
        var result: Result<Offerings, OfferingsManager.Error>?
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
            result = $0
        }

        // then
        expect(result).toEventuallyNot(beNil())
        expect(result).to(beFailure())
        expect(result?.error) == .configurationError(
            Strings.offering.configuration_error_no_products_for_offering.description
        )
    }

    func testOfferingsForAppUserIDReturnsConfigurationErrorIfProductsRequestsReturnsEmpty() throws {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)
        mockProductsManager.stubbedProductsCompletionResult = Set()

        // when
        var result: Result<Offerings, OfferingsManager.Error>?
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
            result = $0
        }

        // then
        expect(result).toEventuallyNot(beNil())
        expect(result).to(beFailure())
        expect(result?.error) == .configurationError(
            Strings.offering.configuration_error_skproducts_not_found.description
        )
    }

    func testOfferingsForAppUserIDReturnsUnexpectedBackendResponseIfOfferingsFactoryCantCreateOfferings() throws {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)
        mockOfferingsFactory.nilOfferings = true

        // when
        var result: Result<Offerings, OfferingsManager.Error>?
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
            result = $0
        }

        // then
        expect(result).toEventuallyNot(beNil())
        expect(result).to(beFailure())
        expect(result?.error) == .noOfferingsFound()
    }

    func testOfferingsForAppUserIDReturnsUnexpectedBackendErrorIfBadBackendRequest() throws {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = .failure(MockData.unexpectedBackendResponseError)
        mockOfferingsFactory.nilOfferings = true

        // when
        var result: Result<Offerings, OfferingsManager.Error>?
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
            result = $0
        }

        // then
        expect(result).toEventuallyNot(beNil())
        expect(result).to(beFailure())
        expect(result?.error) == .backendError(MockData.unexpectedBackendResponseError)
    }

    func testFailBackendDeviceCacheClearsOfferingsCache() {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = .failure(MockData.unexpectedBackendResponseError)
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
        mockBackend.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)
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

        static let anyBackendOfferingsResponse: OfferingsResponse = .init(
            currentOfferingId: "base",
            offerings: [
                .init(identifier: "base",
                      description: "This is the base offering",
                      packages: [
                        .init(identifier: "$rc_monthly", platformProductIdentifier: "monthly_freetrial")
                      ])
            ]
        )
        static let unexpectedBackendResponseError: BackendError = .unexpectedBackendResponse(
            .customerInfoNil
        )
    }

}
