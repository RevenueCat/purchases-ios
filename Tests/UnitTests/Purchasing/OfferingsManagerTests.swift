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

class OfferingsManagerTests: TestCase {

    var mockDeviceCache: MockDeviceCache!
    let mockOperationDispatcher = MockOperationDispatcher()
    // swiftlint:disable:next force_try
    let mockSystemInfo = try! MockSystemInfo(platformInfo: .init(flavor: "iOS", version: "3.2.1"),
                                             finishTransactions: true)
    let mockBackend = MockBackend()
    var mockOfferings: MockOfferingsAPI!
    let mockOfferingsFactory = MockOfferingsFactory()
    var mockProductsManager: MockProductsManager!
    var offeringsManager: OfferingsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.mockOfferings = try XCTUnwrap(self.mockBackend.offerings as? MockOfferingsAPI)
        self.mockDeviceCache = MockDeviceCache(sandboxEnvironmentDetector: self.mockSystemInfo)
        self.mockProductsManager = MockProductsManager(systemInfo: self.mockSystemInfo,
                                                       requestTimeout: Configuration.storeKitRequestTimeoutDefault)
        self.offeringsManager = OfferingsManager(deviceCache: self.mockDeviceCache,
                                                 operationDispatcher: self.mockOperationDispatcher,
                                                 systemInfo: self.mockSystemInfo,
                                                 backend: self.mockBackend,
                                                 offeringsFactory: self.mockOfferingsFactory,
                                                 productsManager: self.mockProductsManager)
    }

}

extension OfferingsManagerTests {

    func testOfferingsForAppUserIDReturnsNilIfMissingStoreProduct() throws {
        // given
        mockOfferingsFactory.emptyOfferings = true
        mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)

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
        mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)

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
        mockOfferings.stubbedGetOfferingsCompletionResult = .failure(MockData.unexpectedBackendResponseError)
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
        mockOfferings.stubbedGetOfferingsCompletionResult = .success(
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

        switch result?.error {
        case let .configurationError(message, underlyingError, _):
            expect(message) == Strings.offering.configuration_error_no_products_for_offering.description
            expect(underlyingError).to(beNil())
        default:
            fail("Unexpected result")
        }
    }

    func testOfferingsForAppUserIDReturnsConfigurationErrorIfProductsRequestsReturnsEmpty() throws {
        // given
        mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)
        mockProductsManager.stubbedProductsCompletionResult = .success(Set())

        // when
        var result: Result<Offerings, OfferingsManager.Error>?
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
            result = $0
        }

        // then
        expect(result).toEventuallyNot(beNil())
        expect(result).to(beFailure())

        switch result?.error {
        case let .configurationError(message, underlyingError, _):
            expect(message) == Strings.offering.configuration_error_skproducts_not_found.description
            expect(underlyingError).to(beNil())
        default:
            fail("Unexpected result")
        }
    }

    func testOfferingsForAppUserIDReturnsConfigurationErrorIfProductsRequestsReturnsError() throws {
        let error: Error = NSError(domain: SKErrorDomain, code: SKError.Code.storeProductNotAvailable.rawValue)

        // given
        mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)
        mockProductsManager.stubbedProductsCompletionResult = .failure(error)

        // when
        var result: Result<Offerings, OfferingsManager.Error>?
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
            result = $0
        }

        // then
        expect(result).toEventuallyNot(beNil())
        expect(result).to(beFailure())

        switch result?.error {
        case let .configurationError(message, underlyingError, _):
            expect(message) == Strings.offering.configuration_error_skproducts_not_found.description
            expect(underlyingError).to(matchError(error))
        default:
            fail("Unexpected result")
        }
    }

    func testOfferingsForAppUserIDReturnsUnexpectedBackendResponseIfOfferingsFactoryCantCreateOfferings() throws {
        // given
        mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)
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
        mockOfferings.stubbedGetOfferingsCompletionResult = .failure(MockData.unexpectedBackendResponseError)
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
        mockOfferings.stubbedGetOfferingsCompletionResult = .failure(MockData.unexpectedBackendResponseError)
        mockOfferingsFactory.emptyOfferings = true
        mockSystemInfo.stubbedIsApplicationBackgrounded = false

        let expectedCallCount = 1

        // when
        offeringsManager.offerings(appUserID: MockData.anyAppUserID, completion: nil)

        // then
        expect(self.mockOfferings.invokedGetOfferingsForAppUserIDCount).toEventually(equal(expectedCallCount))
        expect(self.mockDeviceCache.clearOfferingsCacheTimestampCount).toEventually(equal(expectedCallCount))
        expect(self.mockOfferings.invokedGetOfferingsForAppUserIDParameters?.randomDelay) == false
    }

    func testUpdateOfferingsCacheOK() {
        // given
        mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)
        mockSystemInfo.stubbedIsApplicationBackgrounded = true

        let expectedCallCount = 1

        // when
        offeringsManager.offerings(appUserID: MockData.anyAppUserID, completion: nil)

        // then
        expect(self.mockOfferings.invokedGetOfferingsForAppUserIDCount).toEventually(equal(expectedCallCount))
        expect(self.mockDeviceCache.cacheOfferingsCount).toEventually(equal(expectedCallCount))
        expect(self.mockOfferings.invokedGetOfferingsForAppUserIDParameters?.randomDelay) == true
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
