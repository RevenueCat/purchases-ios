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

@MainActor
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
        self.mockOfferingsFactory.emptyOfferings = true
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(result).to(beSuccess())
        expect(result?.value?.all).to(beEmpty())
        expect(result?.value?["base"]).to(beNil())
    }

    func testOfferingsForAppUserIDReturnsOfferingsIfSuccessBackendRequest() throws {
        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(result).to(beSuccess())
        expect(result?.value?["base"]).toNot(beNil())
        expect(result?.value?["base"]!.monthly).toNot(beNil())
        expect(result?.value?["base"]!.monthly?.storeProduct).toNot(beNil())
    }

    func testOfferingsIgnoresProductsNotFoundAndLogsWarning() throws {
        let logger = TestLogHandler()

        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(
            MockData.backendOfferingsResponseWithUnknownProducts
        )
        self.mockProductsManager.stubbedProductsCompletionResult = .success([
            StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "monthly_freetrial"))
        ])

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        let offerings = try XCTUnwrap(result?.value)
        expect(offerings.all).to(haveCount(1))
        expect(offerings["base"]).toNot(beNil())
        expect(offerings["base"]!.monthly).toNot(beNil())
        expect(offerings["base"]!.monthly?.storeProduct).toNot(beNil())

        logger.verifyMessageWasLogged(
            Strings.offering.cannot_find_product_configuration_error(identifiers: ["yearly_freetrial"]),
            level: .warn
        )
    }

    func testOfferingsFailsIfSomeProductIsNotFound() throws {
        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(
            MockData.backendOfferingsResponseWithUnknownProducts
        )
        self.mockProductsManager.stubbedProductsCompletionResult = .success([
            StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "monthly_freetrial"))
        ])

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID, fetchPolicy: .failIfProductsAreMissing) {
                completed($0)
            }
        }

        // then
        expect(result).to(beFailure { error in
            expect(error).to(matchError(OfferingsManager.Error.missingProducts(identifiers: ["yearly_freetrial"])))
        })
    }

    func testOfferingsForAppUserIDReturnsNilIfFailBackendRequest() {
        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .failure(MockData.unexpectedBackendResponseError)
        self.mockOfferingsFactory.emptyOfferings = true

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(result).to(beFailure())
        expect(result?.error) == .backendError(.unexpectedBackendResponse(.customerInfoNil))
    }

    func testOfferingsForAppUserIDReturnsConfigurationErrorIfBackendReturnsEmpty() throws {
        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(
            .init(currentOfferingId: "", offerings: [])
        )
        self.mockOfferingsFactory.emptyOfferings = true

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(result).to(beFailure())

        switch result?.error {
        case let .configurationError(message, underlyingError, _):
            expect(message) == Strings.offering.configuration_error_no_products_for_offering.description
            expect(underlyingError).to(beNil())
        default:
            fail("Unexpected result")
        }
    }

    func testOfferingsLogsErrorInformationIfBackendReturnsEmpty() throws {
        let logger = TestLogHandler()

        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(
            .init(currentOfferingId: "", offerings: [])
        )
        self.mockOfferingsFactory.emptyOfferings = true

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(result).to(beFailure())

        let error = try XCTUnwrap(logger.messages.filter { $0.level == .error }.onlyElement)

        expect(error.message) == [
            LogIntent.appleError.prefix,
            "Error fetching offerings -",
            OfferingsManager.Error.configurationError("", underlyingError: nil).localizedDescription +
            "\n" + Strings.offering.configuration_error_no_products_for_offering.description
        ]
            .joined(separator: " ")
    }

    func testOfferingsForAppUserIDReturnsConfigurationErrorIfProductsRequestsReturnsEmpty() throws {
        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)
        self.mockProductsManager.stubbedProductsCompletionResult = .success(Set())

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(result).to(beFailure())

        switch result?.error {
        case let .configurationError(message, underlyingError, _):
            expect(message) == Strings.offering.configuration_error_products_not_found.description
            expect(underlyingError).to(beNil())
        default:
            fail("Unexpected result")
        }
    }

    func testOfferingsForAppUserIDReturnsConfigurationErrorIfProductsRequestsReturnsError() throws {
        let error = ErrorUtils.unknownError()

        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)
        self.mockProductsManager.stubbedProductsCompletionResult = .failure(error)

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(result).to(beFailure())

        switch result?.error {
        case let .configurationError(message, underlyingError, _):
            expect(message) == Strings.offering.configuration_error_products_not_found.description
            expect(underlyingError).to(matchError(error))
        default:
            fail("Unexpected result")
        }
    }

    func testOfferingsForAppUserIDReturnsUnexpectedBackendResponseIfOfferingsFactoryCantCreateOfferings() throws {
        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)
        self.mockOfferingsFactory.nilOfferings = true

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(result).to(beFailure())
        expect(result?.error) == .noOfferingsFound()
    }

    func testOfferingsForAppUserIDReturnsUnexpectedBackendErrorIfBadBackendRequest() throws {
        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .failure(MockData.unexpectedBackendResponseError)
        self.mockOfferingsFactory.nilOfferings = true

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(result).to(beFailure())
        expect(result?.error) == .backendError(MockData.unexpectedBackendResponseError)
    }

    func testFailBackendDeviceCacheClearsOfferingsCache() {
        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .failure(MockData.unexpectedBackendResponseError)
        self.mockOfferingsFactory.emptyOfferings = true
        self.mockSystemInfo.stubbedIsApplicationBackgrounded = false

        let expectedCallCount = 1

        // when
        waitUntil { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) { _ in
                completed()
            }
        }

        // then
        expect(self.mockOfferings.invokedGetOfferingsForAppUserIDCount) == expectedCallCount
        expect(self.mockDeviceCache.clearOfferingsCacheTimestampCount) == expectedCallCount
        expect(self.mockOfferings.invokedGetOfferingsForAppUserIDParameters?.randomDelay) == false
    }

    func testUpdateOfferingsCacheOK() {
        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)
        self.mockSystemInfo.stubbedIsApplicationBackgrounded = true

        let expectedCallCount = 1

        // when
        waitUntil { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) { _ in
                completed()
            }
        }

        // then
        expect(self.mockOfferings.invokedGetOfferingsForAppUserIDCount) == expectedCallCount
        expect(self.mockDeviceCache.cacheOfferingsCount) == expectedCallCount
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
        static let backendOfferingsResponseWithUnknownProducts: OfferingsResponse = .init(
            currentOfferingId: "base",
            offerings: [
                .init(identifier: "base",
                      description: "This is the base offering",
                      packages: [
                        .init(identifier: "$rc_monthly", platformProductIdentifier: "monthly_freetrial"),
                        .init(identifier: "$rc_yearly", platformProductIdentifier: "yearly_freetrial")
                      ])
            ]
        )
        static let unexpectedBackendResponseError: BackendError = .unexpectedBackendResponse(
            .customerInfoNil
        )
    }

}
