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
    let mockSystemInfo = MockSystemInfo(platformInfo: .init(flavor: "iOS", version: "3.2.1"),
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

        self.logger.verifyMessageWasLogged(
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

        switch result?.error {
        case .backendError(.unexpectedBackendResponse(.customerInfoNil, _, _)):
            break
        default:
            fail("Unexpected result")
        }
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

    func testOfferingsReturnsTimeoutErrorIfProductRequestTimesOut() throws {
        // given
        let timeoutError = ErrorUtils.productRequestTimedOutError()

        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(
            MockData.anyBackendOfferingsResponse
        )
        self.mockProductsManager.stubbedProductsCompletionResult = .failure(timeoutError)

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(result).to(beFailure())
        expect(result?.error).to(matchError(OfferingsManager.Error.timeout(timeoutError)))

        let underlyingError = try XCTUnwrap(result?.error?.errorUserInfo[NSUnderlyingErrorKey] as? NSError)
        expect(underlyingError).to(matchError(timeoutError))
    }

    func testOfferingsLogsErrorInformationIfBackendReturnsEmpty() throws {
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

        switch result?.error {
        case .noOfferingsFound:
            break
        default:
            fail("Unexpected result")
        }
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

        switch result?.error {
        case .backendError(MockData.unexpectedBackendResponseError):
            break
        default:
            fail("Unexpected result")
        }
    }

    func testUpdateOfferingsCacheOK() throws {
        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)
        self.mockSystemInfo.stubbedIsApplicationBackgrounded = true

        let expectedCallCount = 1

        // when
        let result: Result<Offerings, OfferingsManager.Error>? = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) { result in
                completed(result)
            }
        }

        // then
        expect(self.mockOfferings.invokedGetOfferingsForAppUserIDCount) == expectedCallCount
        expect(self.mockDeviceCache.cacheOfferingsCount) == expectedCallCount
        expect(self.mockOfferings.invokedGetOfferingsForAppUserIDParameters?.randomDelay) == true
        expect(result).to(beSuccess())

        let offerings = try XCTUnwrap(result?.value)
        expect(offerings.all).to(haveCount(1))
        expect(offerings.current?.identifier) == "base"
        expect(offerings.current?.availablePackages).to(haveCount(1))

        let package = try XCTUnwrap(offerings.current?.availablePackages.onlyElement)
        expect(package.packageType) == .monthly
        expect(package.storeProduct.productIdentifier) == "monthly_freetrial"
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

    func testOfferingsFromMemoryCache() {
        self.mockDeviceCache.stubbedOfferings = MockData.sampleOfferings

        let result: Result<Offerings, OfferingsManager.Error>? = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) { result in
                completed(result)
            }
        }

        expect(result).to(beSuccess())
        expect(result?.value) === MockData.sampleOfferings

        expect(self.mockOfferings.invokedGetOfferingsForAppUserID) == false
        expect(self.mockDeviceCache.cacheOfferingsCount) == 0
    }

    func testReturnsOfferingsFromDiskCacheIfNetworkRequestWithServerDown() throws {
        self.mockDeviceCache.stubbedOfferings = nil
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .failure(.networkError(.serverDown()))
        self.mockDeviceCache.stubbedCachedOfferingsData = try MockData.anyBackendOfferingsResponse.jsonEncodedData

        let result: Result<Offerings, OfferingsManager.Error>? = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) { result in
                completed(result)
            }
        }

        expect(result).to(beSuccess())
        expect(result?.value?.all).to(haveCount(1))
        expect(result?.value?.current?.identifier) == MockData.anyBackendOfferingsResponse.currentOfferingId

        expect(self.mockOfferings.invokedGetOfferingsForAppUserID) == true
        expect(self.mockDeviceCache.cacheOfferingsCount) == 0
        expect(self.mockDeviceCache.cacheOfferingsInMemoryCount) == 1
        expect(self.mockDeviceCache.clearOfferingsCacheTimestampCount) == 1
    }

    func testFailsToCreateOfferingsFromDiskCache() throws {
        let error: BackendError = .networkError(.serverDown())

        self.mockDeviceCache.stubbedOfferings = nil
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .failure(error)
        self.mockDeviceCache.stubbedCachedOfferingsData = try MockData.anyBackendOfferingsResponse.jsonEncodedData
        self.mockOfferingsFactory.nilOfferings = true

        let result: Result<Offerings, OfferingsManager.Error>? = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) { result in
                completed(result)
            }
        }

        expect(result).to(beFailure())
        expect(result?.error).to(matchError(OfferingsManager.Error.backendError(error)))

        expect(self.mockOfferings.invokedGetOfferingsForAppUserID) == true
        expect(self.mockDeviceCache.cacheOfferingsCount) == 0
        expect(self.mockDeviceCache.cacheOfferingsInMemoryCount) == 0
    }

    func testNetworkErrorContainsUnderlyingError() {
        let underlyingError = NSError(domain: NSURLErrorDomain,
                                      code: NSURLErrorCancelledReasonInsufficientSystemResources)

        let error: OfferingsManager.Error = .backendError(
            .networkError(
                .networkError(underlyingError)
            )
        )
        _ = error.asPurchasesError

        self.logger.verifyMessageWasLogged("NSURLErrorDomain error \(underlyingError.code)",
                                           level: .error)
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
        static let sampleOfferings: Offerings = .init(
            offerings: MockData.anyBackendOfferingsResponse.offerings
                .map { offering in
                    Offering(
                        identifier: offering.identifier,
                        serverDescription: offering.description,
                        metadata: offering.metadata,
                        availablePackages: offering.packages.map { package in
                                .init(
                                    identifier: package.identifier,
                                    packageType: Package.packageType(from: package.identifier),
                                    storeProduct: StoreProduct(sk1Product: MockSK1Product(
                                        mockProductIdentifier: package.platformProductIdentifier
                                    )),
                                    offeringIdentifier: offering.identifier
                                )
                        }
                    )
                }
                .dictionaryWithKeys(\.identifier),
            currentOfferingID: MockData.anyBackendOfferingsResponse.currentOfferingId,
            response: MockData.anyBackendOfferingsResponse
        )
    }

}
