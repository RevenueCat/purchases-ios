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
@testable @_spi(Internal) import RevenueCat
import StoreKit
import XCTest

class OfferingsManagerTests: TestCase {

    var mockDeviceCache: MockDeviceCache!
    let mockOperationDispatcher = MockOperationDispatcher()
    let preferredLocalesProvider: PreferredLocalesProvider = .mock(locales: ["de_DE"])
    var mockSystemInfo: MockSystemInfo!
    let mockBackend = MockBackend()
    var mockOfferings: MockOfferingsAPI!
    let mockOfferingsFactory = MockOfferingsFactory()
    var mockProductsManager: MockProductsManager!
    var mockDiagnosticsTracker: DiagnosticsTrackerType!
    var offeringsManager: OfferingsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.mockOfferings = try XCTUnwrap(self.mockBackend.offerings as? MockOfferingsAPI)
        self.mockSystemInfo = MockSystemInfo(platformInfo: .init(flavor: "iOS", version: "3.2.1"),
                                             finishTransactions: true,
                                             preferredLocalesProvider: self.preferredLocalesProvider)
        self.mockDeviceCache = MockDeviceCache(systemInfo: self.mockSystemInfo)
        self.mockProductsManager = MockProductsManager(diagnosticsTracker: nil,
                                                       systemInfo: self.mockSystemInfo,
                                                       requestTimeout: Configuration.storeKitRequestTimeoutDefault)
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            self.mockDiagnosticsTracker = MockDiagnosticsTracker()
        } else {
            self.mockDiagnosticsTracker = nil
        }
        self.offeringsManager = OfferingsManager(deviceCache: self.mockDeviceCache,
                                                 operationDispatcher: self.mockOperationDispatcher,
                                                 systemInfo: self.mockSystemInfo,
                                                 backend: self.mockBackend,
                                                 offeringsFactory: self.mockOfferingsFactory,
                                                 productsManager: self.mockProductsManager,
                                                 diagnosticsTracker: self.mockDiagnosticsTracker)
    }

}

extension OfferingsManagerTests {

    func testOfferingsForAppUserIDReturnsNilIfMissingStoreProduct() throws {
        // given
        self.mockOfferingsFactory.emptyOfferings = true
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

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
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

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
            MockData.backendOfferingsContentsWithUnknownProducts
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
            Strings.offering.cannot_find_product_configuration_error(
                identifiers: ["yearly_freetrial"],
                apiKeyValidationResult: .validApplePlatform
            ),
            level: .warn
        )
    }

    func testOfferingsFailsIfSomeProductIsNotFound() throws {
        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(
            MockData.backendOfferingsContentsWithUnknownProducts
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
            expect(error).to(matchError(OfferingsManager.Error.missingProducts(
                identifiers: ["yearly_freetrial"],
                apiKeyValidationResult: .validApplePlatform
            )))
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
            Offerings.Contents(response: .init(currentOfferingId: "",
                                               offerings: [],
                                               placements: nil,
                                               targeting: nil,
                                               uiConfig: nil),
                               httpResponseOriginalSource: .mainServer)
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
            expect(message) == Strings.offering.configuration_error_no_products_for_offering(
                apiKeyValidationResult: .validApplePlatform
            ).description
            expect(underlyingError).to(beNil())
        default:
            fail("Unexpected result")
        }
    }

    func testOfferingsReturnsTimeoutErrorIfProductRequestTimesOut() throws {
        // given
        let timeoutError = ErrorUtils.productRequestTimedOutError()

        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(
            MockData.anyBackendOfferingsContents
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
            Offerings.Contents(response: .init(currentOfferingId: "",
                                               offerings: [],
                                               placements: nil,
                                               targeting: nil,
                                               uiConfig: nil),
                               httpResponseOriginalSource: .mainServer)
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

        let error = try XCTUnwrap(logger.messages.filter { $0.level == .error }.first)

        expect(error.message) == [
            LogIntent.appleError.prefix,
            "Error fetching offerings -",
            OfferingsManager.Error.configurationError("", underlyingError: nil).localizedDescription +
            "\n" + Strings.offering.configuration_error_no_products_for_offering(
                apiKeyValidationResult: .validApplePlatform
            ).description
        ]
            .joined(separator: " ")
    }

    func testOfferingsLogsErrorInformationIfBackendReturnsOfferingsWithNoPackagesForAppStoreApiKey() throws {
        // given
        self.mockSystemInfo.apiKeyValidationResult = .validApplePlatform
        self.mockOfferings.stubbedGetOfferingsCompletionResult =
            .success(MockData.backendOfferingsContentsWothEmptyPackages)
        self.mockOfferingsFactory.emptyOfferings = false

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(result).to(beFailure())

        let error = try XCTUnwrap(logger.messages.filter { $0.level == .error }.first)

        expect(error.message) == [
            LogIntent.appleError.prefix,
            "Error fetching offerings -",
            OfferingsManager.Error.configurationError("", underlyingError: nil).localizedDescription +
            "\n" + Strings.offering.configuration_error_no_products_for_offering(
                apiKeyValidationResult: .validApplePlatform
            ).description
        ]
            .joined(separator: " ")
        expect(error.message).to(contain("an App Store API key"))
    }

    func testOfferingsLogsErrorInformationIfBackendReturnsOfferingsWithNoPackagesForTestStoreApiKey() throws {
        // given
        self.mockSystemInfo.apiKeyValidationResult = .simulatedStore
        self.mockOfferings.stubbedGetOfferingsCompletionResult =
            .success(MockData.backendOfferingsContentsWothEmptyPackages)
        self.mockOfferingsFactory.emptyOfferings = false

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(result).to(beFailure())

        let error = try XCTUnwrap(logger.messages.filter { $0.level == .error }.first)

        expect(error.message) == [
            LogIntent.appleError.prefix,
            "Error fetching offerings -",
            OfferingsManager.Error.configurationError("", underlyingError: nil).localizedDescription +
            "\n" + Strings.offering.configuration_error_no_products_for_offering(
                apiKeyValidationResult: .simulatedStore
            ).description
        ]
            .joined(separator: " ")
        expect(error.message).to(contain("a Test Store API key"))
    }

    func testOfferingsLogsErrorInformationIfBackendReturnsOfferingsWithNoPackagesForLegacyApiKey() throws {
        // given
        self.mockSystemInfo.apiKeyValidationResult = .legacy
        self.mockOfferings.stubbedGetOfferingsCompletionResult =
            .success(MockData.backendOfferingsContentsWothEmptyPackages)
        self.mockOfferingsFactory.emptyOfferings = false

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(result).to(beFailure())

        let error = try XCTUnwrap(logger.messages.filter { $0.level == .error }.first)

        expect(error.message) == [
            LogIntent.appleError.prefix,
            "Error fetching offerings -",
            OfferingsManager.Error.configurationError("", underlyingError: nil).localizedDescription +
            "\n" + Strings.offering.configuration_error_no_products_for_offering(
                apiKeyValidationResult: .legacy
            ).description
        ]
            .joined(separator: " ")
        expect(error.message).to(contain("an App Store API key"))
    }

    func testOfferingsLogsErrorInformationIfBackendReturnsOfferingsWithNoPackagesForOtherPlatformApiKey() throws {
        // given
        self.mockSystemInfo.apiKeyValidationResult = .otherPlatforms
        self.mockOfferings.stubbedGetOfferingsCompletionResult =
            .success(MockData.backendOfferingsContentsWothEmptyPackages)
        self.mockOfferingsFactory.emptyOfferings = false

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(result).to(beFailure())

        let error = try XCTUnwrap(logger.messages.filter { $0.level == .error }.first)

        expect(error.message) == [
            LogIntent.appleError.prefix,
            "Error fetching offerings -",
            OfferingsManager.Error.configurationError("", underlyingError: nil).localizedDescription +
            "\n" + Strings.offering.configuration_error_no_products_for_offering(
                apiKeyValidationResult: .otherPlatforms
            ).description
        ]
            .joined(separator: " ")
        expect(error.message).toNot(contain("an App Store API key"))
        expect(error.message).toNot(contain("a Test Store API key"))
    }

    func testOfferingsForAppUserIDReturnsConfigurationErrorIfProductsRequestsReturnsEmpty() throws {
        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)
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
            expect(message) == Strings.offering
                .configuration_error_products_not_found(apiKeyValidationResult: .validApplePlatform).description
            expect(underlyingError).to(beNil())
        default:
            fail("Unexpected result")
        }
    }

    func testOfferingsForAppUserIDReturnsConfigurationErrorIfProductsRequestsReturnsError() throws {
        let error = ErrorUtils.unknownError()

        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)
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
            expect(message) == Strings.offering
                .configuration_error_products_not_found(apiKeyValidationResult: .validApplePlatform).description
            expect(underlyingError).to(matchError(error))
        default:
            fail("Unexpected result")
        }
    }

    func testOfferingsForAppUserIDReturnsUnexpectedBackendResponseIfOfferingsFactoryCantCreateOfferings() throws {
        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)
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
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)
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
        expect(self.mockDeviceCache.latestCachePreferredLocales) == ["de_DE"]
        expect(self.mockOfferings.invokedGetOfferingsForAppUserIDParameters?.isAppBackgrounded) == true
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
        expect(result?.value?.loadedFromDiskCache) == false // Offerings loaded from memory, not disk

        expect(self.mockOfferings.invokedGetOfferingsForAppUserID) == false
        expect(self.mockDeviceCache.cacheOfferingsCount) == 0
    }

    func testOfferingsForAppUserIdForcesNetworkRequestWhenFetchCurrentIsTrue() throws {
        // given
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)
        self.mockDeviceCache.stubbedOfferings = MockData.sampleOfferings

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID, fetchCurrent: true) {
                completed($0)
            }
        }

        // then
        expect(result).to(beSuccess())
        expect(result?.value) !== MockData.sampleOfferings
        expect(result?.value?["base"]).toNot(beNil())
        expect(result?.value?["base"]!.monthly).toNot(beNil())
        expect(result?.value?["base"]!.monthly?.storeProduct).toNot(beNil())
        expect(result?.value?.loadedFromDiskCache) == false

        expect(self.mockOfferings.invokedGetOfferingsForAppUserID) == true
        expect(self.mockDeviceCache.cacheOfferingsCount) == 1
    }

    func testReturnsOfferingsFromDiskCacheIfNetworkRequestWithServerDown() throws {
        self.mockDeviceCache.stubbedOfferings = nil
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .failure(.networkError(.serverDown()))
        self.mockDeviceCache.stubbedCachedOfferingsData = try MockData.anyBackendOfferingsContents.jsonEncodedData

        let result: Result<Offerings, OfferingsManager.Error>? = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) { result in
                completed(result)
            }
        }

        expect(result).to(beSuccess())
        expect(result?.value?.all).to(haveCount(1))
        expect(result?.value?.current?.identifier) == MockData.anyBackendOfferingsContents.response.currentOfferingId
        expect(result?.value?.loadedFromDiskCache) == true

        expect(self.mockOfferings.invokedGetOfferingsForAppUserID) == true
        expect(self.mockDeviceCache.cacheOfferingsCount) == 0
        expect(self.mockDeviceCache.cacheOfferingsInMemoryCount) == 1
        expect(self.mockDeviceCache.clearOfferingsCacheTimestampCount) == 1
    }

    func testReturnsOfferingsFromDiskCacheIfJSONDecodingError() throws {
        self.mockDeviceCache.stubbedOfferings = nil
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .failure(.networkError(.decodingError()))
        self.mockDeviceCache.stubbedCachedOfferingsData = try MockData.anyBackendOfferingsContents.jsonEncodedData

        let result: Result<Offerings, OfferingsManager.Error>? = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) { result in
                completed(result)
            }
        }

        expect(result).to(beSuccess())
        expect(result?.value?.all).to(haveCount(1))
        expect(result?.value?.current?.identifier) == MockData.anyBackendOfferingsContents.response.currentOfferingId

        expect(self.mockOfferings.invokedGetOfferingsForAppUserID) == true
        expect(self.mockDeviceCache.cacheOfferingsCount) == 0
        expect(self.mockDeviceCache.cacheOfferingsInMemoryCount) == 1
        expect(self.mockDeviceCache.clearOfferingsCacheTimestampCount) == 1
    }

    func testGetOfferingsReturnsNilIf4XXError() throws {
        let errorResponse = ErrorResponse(code: .invalidSubscriberAttributes,
                                          originalCode: BackendErrorCode.invalidSubscriberAttributes.rawValue,
                                          message: "Invalid Attributes",
                                          attributeErrors: [
                                            "$email": "invalid"
                                          ])

        let error: BackendError = .networkError(.errorResponse(errorResponse, .invalidRequest))

        self.mockDeviceCache.stubbedOfferings = nil
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .failure(error)
        self.mockDeviceCache.stubbedCachedOfferingsData = try MockData.anyBackendOfferingsContents.jsonEncodedData
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

    func testGetOfferingsReturnsNilWhenFailingToCreateOfferingsFromDiskCacheResponse() throws {
        let error: BackendError = .networkError(.serverDown())

        self.mockDeviceCache.stubbedOfferings = nil
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .failure(error)
        self.mockDeviceCache.stubbedCachedOfferingsData = try MockData.anyBackendOfferingsContents.jsonEncodedData
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

    func testProductsManagerIsNotUsedInUIPreviewModeWhenGetOfferingsSuccess() throws {
        // given
        let mockSystemInfoWithPreviewMode = MockSystemInfo(
            platformInfo: .init(flavor: "iOS", version: "3.2.1"),
            finishTransactions: true,
            dangerousSettings: DangerousSettings(uiPreviewMode: true)
        )

        self.offeringsManager = OfferingsManager(
            deviceCache: self.mockDeviceCache,
            operationDispatcher: self.mockOperationDispatcher,
            systemInfo: mockSystemInfoWithPreviewMode,
            backend: self.mockBackend,
            offeringsFactory: self.mockOfferingsFactory,
            productsManager: self.mockProductsManager,
            diagnosticsTracker: self.mockDiagnosticsTracker
        )

        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        // when
        let result: Result<Offerings, OfferingsManager.Error>? = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) { result in
                completed(result)
            }
        }

        // then
        expect(result).to(beSuccess())
        expect(self.mockProductsManager.invokedProducts) == false
        expect(result?.value?.current?.availablePackages).toNot(beEmpty())
    }

    func testProductsManagerIsNotUsedInUIPreviewModeWhenGetOfferingsFailure() throws {
        // given
        let mockSystemInfoWithPreviewMode = MockSystemInfo(
            platformInfo: .init(flavor: "iOS", version: "3.2.1"),
            finishTransactions: true,
            dangerousSettings: DangerousSettings(uiPreviewMode: true)
        )

        self.offeringsManager = OfferingsManager(
            deviceCache: self.mockDeviceCache,
            operationDispatcher: self.mockOperationDispatcher,
            systemInfo: mockSystemInfoWithPreviewMode,
            backend: self.mockBackend,
            offeringsFactory: self.mockOfferingsFactory,
            productsManager: self.mockProductsManager,
            diagnosticsTracker: self.mockDiagnosticsTracker
        )

        self.mockOfferings.stubbedGetOfferingsCompletionResult = .failure(MockData.unexpectedBackendResponseError)

        // when
        let result: Result<Offerings, OfferingsManager.Error>? = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) { result in
                completed(result)
            }
        }

        // then
        expect(result).to(beFailure())
        expect(self.mockProductsManager.invokedProducts) == false
    }

    func testOfferingsForAppUserIdForcesNetworkRequestWhenUIPreviewModeIsTrueAndFetchCurrentIsFalse() throws {
        // given
        let mockSystemInfoWithPreviewMode = MockSystemInfo(
            platformInfo: .init(flavor: "iOS", version: "3.2.1"),
            finishTransactions: true,
            dangerousSettings: DangerousSettings(uiPreviewMode: true)
        )

        self.offeringsManager = OfferingsManager(
            deviceCache: self.mockDeviceCache,
            operationDispatcher: self.mockOperationDispatcher,
            systemInfo: mockSystemInfoWithPreviewMode,
            backend: self.mockBackend,
            offeringsFactory: self.mockOfferingsFactory,
            productsManager: self.mockProductsManager,
            diagnosticsTracker: self.mockDiagnosticsTracker
        )

        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)
        self.mockDeviceCache.stubbedOfferings = MockData.sampleOfferings

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID, fetchCurrent: false) {
                completed($0)
            }
        }

        // then
        expect(result).to(beSuccess())
        expect(result?.value) !== MockData.sampleOfferings
        expect(result?.value?["base"]).toNot(beNil())
        expect(result?.value?["base"]!.monthly).toNot(beNil())
        expect(result?.value?["base"]!.monthly?.storeProduct).toNot(beNil())
        expect(result?.value?.loadedFromDiskCache) == false

        expect(self.mockOfferings.invokedGetOfferingsForAppUserID) == true
        expect(self.mockDeviceCache.cacheOfferingsCount) == 1
    }

}

// MARK: - Diagnostics tracking

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension OfferingsManagerTests {

    func testOfferingsTracksOfferingsStartAndResultEvent() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        // given
        // swiftlint:disable:next force_cast
        let mockDiagnosticsTracker = self.mockDiagnosticsTracker as! MockDiagnosticsTracker

        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        // when
        _ = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(mockDiagnosticsTracker.trackedOfferingsStartedCount.value) == 1
        expect(mockDiagnosticsTracker.trackedOfferingsResultParams.value.count) == 1
        let params = try XCTUnwrap(mockDiagnosticsTracker.trackedOfferingsResultParams.value.first)
        expect(params.requestedProductIds) == ["monthly_freetrial"]
        expect(params.notFoundProductIds) == []
        expect(params.errorMessage) == nil
        expect(params.errorCode) == nil
        expect(params.verificationResult) == nil
        expect(params.cacheStatus) == .notFound
        expect(params.responseTime) >= 0
    }

    func testOfferingsTracksOfferingsResultEventWhenObtainingOfferingsFromCache() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        // given
        // swiftlint:disable:next force_cast
        let mockDiagnosticsTracker = self.mockDiagnosticsTracker as! MockDiagnosticsTracker

        self.mockDeviceCache.stubbedOfferings = MockData.sampleOfferings
        self.mockDeviceCache.stubbedOfferingCacheStatus = .valid

        // when
        _ = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) {
                completed($0)
            }
        }

        // then
        expect(mockDiagnosticsTracker.trackedOfferingsResultParams.value.count) == 1
        let params = try XCTUnwrap(mockDiagnosticsTracker.trackedOfferingsResultParams.value.first)
        expect(params.requestedProductIds) == nil
        expect(params.notFoundProductIds) == nil
        expect(params.errorMessage) == nil
        expect(params.errorCode) == nil
        expect(params.verificationResult) == nil
        expect(params.cacheStatus) == .valid
        expect(params.responseTime) >= 0
    }

    func testOfferingsTracksOfferingsResultEventCorrectlyWhenFetchCurrent() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        // given
        // swiftlint:disable:next force_cast
        let mockDiagnosticsTracker = self.mockDiagnosticsTracker as! MockDiagnosticsTracker

        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        // when
        _ = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID, fetchCurrent: true) {
                completed($0)
            }
        }

        // then
        expect(mockDiagnosticsTracker.trackedOfferingsStartedCount.value) == 1
        expect(mockDiagnosticsTracker.trackedOfferingsResultParams.value.count) == 1
        let params = try XCTUnwrap(mockDiagnosticsTracker.trackedOfferingsResultParams.value.first)
        expect(params.requestedProductIds) == ["monthly_freetrial"]
        expect(params.notFoundProductIds) == []
        expect(params.errorMessage) == nil
        expect(params.errorCode) == nil
        expect(params.verificationResult) == nil
        expect(params.cacheStatus) == .notChecked
        expect(params.responseTime) >= 0
    }

    func testOfferingsDoesNotTrackEventsIfDiagnosticsTrackingDisabled() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        // given
        // swiftlint:disable:next force_cast
        let mockDiagnosticsTracker = self.mockDiagnosticsTracker as! MockDiagnosticsTracker

        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        // when
        _ = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID, trackDiagnostics: false) {
                completed($0)
            }
        }

        // then
        expect(mockDiagnosticsTracker.trackedOfferingsStartedCount.value) == 0
        expect(mockDiagnosticsTracker.trackedOfferingsResultParams.value.count) == 0
    }
}

private extension OfferingsManagerTests {

    enum MockData {
        static let anyAppUserID = ""

        static let anyBackendOfferingsContents = Offerings.Contents(
            response: .init(
                currentOfferingId: "base",
                offerings: [
                    .init(identifier: "base",
                          description: "This is the base offering",
                          packages: [
                            .init(identifier: "$rc_monthly",
                                  platformProductIdentifier: "monthly_freetrial",
                                  platformProductPlanIdentifier: nil,
                                  webCheckoutUrl: nil)
                          ],
                          webCheckoutUrl: nil)
                ],
                placements: nil,
                targeting: nil,
                uiConfig: nil
            ),
            httpResponseOriginalSource: .mainServer
        )
        static let backendOfferingsContentsWithUnknownProducts = Offerings.Contents(
            response: .init(
                currentOfferingId: "base",
                offerings: [
                    .init(identifier: "base",
                          description: "This is the base offering",
                          packages: [
                            .init(identifier: "$rc_monthly",
                                  platformProductIdentifier: "monthly_freetrial",
                                  platformProductPlanIdentifier: nil,
                                  webCheckoutUrl: nil),
                            .init(identifier: "$rc_yearly",
                                  platformProductIdentifier: "yearly_freetrial",
                                  platformProductPlanIdentifier: nil,
                                  webCheckoutUrl: nil)
                          ],
                          webCheckoutUrl: nil)
                ],
                placements: nil,
                targeting: nil,
                uiConfig: nil
            ),
            httpResponseOriginalSource: .mainServer
        )
        static let backendOfferingsContentsWothEmptyPackages = Offerings.Contents(
            response: .init(
                currentOfferingId: "base",
                offerings: [
                    .init(identifier: "base",
                          description: "This is the base offering",
                          packages: [],
                          webCheckoutUrl: nil)
                ],
                placements: nil,
                targeting: nil,
                uiConfig: nil
            ),
            httpResponseOriginalSource: .mainServer
        )
        static let unexpectedBackendResponseError: BackendError = .unexpectedBackendResponse(
            .customerInfoNil
        )
        static let sampleOfferings: Offerings = MockData.makeSampleOfferings()

        /// A fresh `Offerings` instance per call, for tests that need two distinguishable snapshots.
        static func makeSampleOfferings() -> Offerings {
            return .init(
            offerings: MockData.anyBackendOfferingsContents.response.offerings
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
                                    offeringIdentifier: offering.identifier,
                                    webCheckoutUrl: nil
                                )
                        },
                        webCheckoutUrl: nil
                    )
                }
                .dictionaryWithKeys(\.identifier),
            currentOfferingID: MockData.anyBackendOfferingsContents.response.currentOfferingId,
            placements: nil,
            targeting: nil,
            contents: MockData.anyBackendOfferingsContents,
            loadedFromDiskCache: false
            )
        }
    }

}

// MARK: - Remote config integration

extension OfferingsManagerTests {

    func testGetOfferingsDeliversImmediatelyWhenRemoteConfigManagerIsNil() {
        // The default `offeringsManager` is built without a remote config manager (workflows
        // disabled), so offerings delivery must be unchanged.
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: MockData.anyAppUserID) { completed($0) }
        }

        expect(result).to(beSuccess())
    }

    func testGetOfferingsDoesNotDeliverUntilConfigReady() {
        let mockRemoteConfigManager = MockRemoteConfigManager()
        mockRemoteConfigManager.shouldStoreTopicCompletion = true
        let manager = self.makeOfferingsManager(remoteConfigManager: mockRemoteConfigManager)
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        let delivered: Atomic<Bool> = false
        manager.offerings(appUserID: MockData.anyAppUserID) { _ in delivered.value = true }

        // The topic was awaited, but its completion is held, so offerings must wait.
        expect(mockRemoteConfigManager.invokedTopicCount).toEventually(beGreaterThan(0))
        expect(delivered.value) == false

        mockRemoteConfigManager.completeStoredTopic()
        expect(delivered.value).toEventually(beTrue())
    }

    func testGetOfferingsDoesNotDeliverUntilUiConfigResolved() {
        let mockRemoteConfigManager = MockRemoteConfigManager()
        // The workflows topic resolves immediately; ui_config's blob reads are held.
        mockRemoteConfigManager.shouldStoreBlobDataCompletion = true
        let manager = self.makeOfferingsManager(remoteConfigManager: mockRemoteConfigManager)
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        let delivered: Atomic<Bool> = false
        manager.offerings(appUserID: MockData.anyAppUserID) { _ in delivered.value = true }

        // The ui_config read was started but is held, so offerings must wait.
        expect(mockRemoteConfigManager.invokedBlobDataParameters).toEventuallyNot(beEmpty())
        expect(delivered.value) == false

        mockRemoteConfigManager.completeStoredBlobReads()
        expect(delivered.value).toEventually(beTrue())
    }

    func testGetOfferingsDeliversWhenUiConfigResolutionFails() {
        // No ui_config blobs stubbed: resolution fails (nil). Readiness is best-effort, so
        // delivery must proceed anyway with the real offerings.
        let manager = self.makeOfferingsManager(remoteConfigManager: MockRemoteConfigManager())
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        let result = waitUntilValue { completed in
            manager.offerings(appUserID: MockData.anyAppUserID) { completed($0) }
        }

        expect(result).to(beSuccess())
        expect(result?.value?["base"]).toNot(beNil())
        expect(result?.value?["base"]?.monthly?.storeProduct).toNot(beNil())
    }

    func testGetOfferingsDeliversEvenIfTheGateTaskIsCancelled() {
        // The gate's two readiness awaits are non-throwing and always awaited before the
        // callback fires, so no cancellation can strand it. Model that here by resolving both
        // to their empty/failed states (no workflows topic, no ui_config) and asserting the
        // completion still runs.
        let manager = self.makeOfferingsManager(remoteConfigManager: MockRemoteConfigManager())
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        let result = waitUntilValue { completed in
            manager.offerings(appUserID: MockData.anyAppUserID) { completed($0) }
        }

        expect(result).to(beSuccess())
    }

    func testBackgroundCacheRefreshCachesWithoutAwaitingTheConfigGate() {
        // A background refresh passes a nil completion: it has nothing to deliver, so it must
        // cache the fetched offerings without entering the readiness gate. The held topic
        // would block the gate forever; asserting the cache still lands (and the gate's topic
        // read never happens) locks the skip.
        let mockRemoteConfigManager = MockRemoteConfigManager()
        mockRemoteConfigManager.shouldStoreTopicCompletion = true
        let manager = self.makeOfferingsManager(remoteConfigManager: mockRemoteConfigManager)
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        manager.updateOfferingsCache(appUserID: MockData.anyAppUserID,
                                     isAppBackgrounded: false,
                                     completion: nil)

        expect(self.mockDeviceCache.cacheOfferingsCount).toEventually(equal(1))
        expect(mockRemoteConfigManager.invokedTopicCount) == 0
    }

    func testGetOfferingsAwaitsBothWorkflowsTopicAndUiConfigBlobs() {
        let mockRemoteConfigManager = MockRemoteConfigManager()
        // Hold the topic reads first (both the workflows-readiness and ui_config branches
        // read a topic), then the ui_config blob reads: delivery must clear both to proceed.
        mockRemoteConfigManager.shouldStoreTopicCompletion = true
        mockRemoteConfigManager.shouldStoreBlobDataCompletion = true
        let manager = self.makeOfferingsManager(remoteConfigManager: mockRemoteConfigManager)
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        let delivered: Atomic<Bool> = false
        manager.offerings(appUserID: MockData.anyAppUserID) { _ in delivered.value = true }

        // Both readiness branches block on their topic read concurrently (workflows readiness
        // and ui_config resolution), so at least two topic reads are in flight before either
        // completes; getOfferings must not serialize them.
        expect(mockRemoteConfigManager.invokedTopicCount).toEventually(beGreaterThanOrEqualTo(2))
        expect(delivered.value) == false

        // Topics resolve; ui_config resolution now reaches (and blocks on) its blob reads.
        mockRemoteConfigManager.completeStoredTopic()
        expect(mockRemoteConfigManager.invokedBlobDataParameters).toEventuallyNot(beEmpty())
        expect(delivered.value) == false

        // Only once the ui_config blobs resolve too does delivery fire.
        mockRemoteConfigManager.completeStoredBlobReads()
        expect(delivered.value).toEventually(beTrue())
    }

    func testGetOfferingsDeliversEvenWhenRemoteConfigHasNoWorkflowsTopic() {
        // A manager with no committed `workflows` topic (e.g. never synced) must still call back, so
        // offerings delivery can never hang.
        let manager = self.makeOfferingsManager(remoteConfigManager: MockRemoteConfigManager())
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        let result = waitUntilValue { completed in
            manager.offerings(appUserID: MockData.anyAppUserID) { completed($0) }
        }

        expect(result).to(beSuccess())
    }

    func testGetOfferingsFromMemoryCacheWaitsForConfigReady() {
        let mockRemoteConfigManager = MockRemoteConfigManager()
        mockRemoteConfigManager.shouldStoreTopicCompletion = true
        let manager = self.makeOfferingsManager(remoteConfigManager: mockRemoteConfigManager)
        // Serve offerings straight from the in-memory cache (the fast path) and keep it fresh so no
        // background refresh runs.
        self.mockDeviceCache.stubbedOfferings = MockData.sampleOfferings
        self.mockDeviceCache.stubbedOfferingCacheStatus = .valid

        let delivered: Atomic<Bool> = false
        manager.offerings(appUserID: MockData.anyAppUserID) { _ in delivered.value = true }

        // Even on the cached path, the topic is awaited before offerings are delivered.
        expect(mockRemoteConfigManager.invokedTopicCount).toEventually(beGreaterThan(0))
        expect(delivered.value) == false

        mockRemoteConfigManager.completeStoredTopic()
        expect(delivered.value).toEventually(beTrue())
    }

    func testGetOfferingsFromStaleMemoryCacheGatesDeliveryAndStillRefreshes() {
        let mockRemoteConfigManager = MockRemoteConfigManager()
        mockRemoteConfigManager.shouldStoreTopicCompletion = true
        let manager = self.makeOfferingsManager(remoteConfigManager: mockRemoteConfigManager)
        // Cached but stale, so the background refresh runs.
        self.mockDeviceCache.stubbedOfferings = MockData.sampleOfferings
        self.mockDeviceCache.stubbedOfferingCacheStatus = .stale
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        let delivered: Atomic<Bool> = false
        manager.offerings(appUserID: MockData.anyAppUserID) { _ in delivered.value = true }

        // The background refresh starts regardless of the gate...
        expect(self.mockOfferings.invokedGetOfferingsForAppUserID).toEventually(beTrue())
        // ...but delivery, even from a stale cache, waits for config readiness.
        expect(mockRemoteConfigManager.invokedTopicCount).toEventually(beGreaterThan(0))
        expect(delivered.value) == false

        mockRemoteConfigManager.completeStoredTopic()
        expect(delivered.value).toEventually(beTrue())
    }

    func testGatedFreshCacheDeliveryNeverReadsTheSharedCacheSlot() {
        let mockRemoteConfigManager = MockRemoteConfigManager()
        mockRemoteConfigManager.shouldStoreTopicCompletion = true
        let manager = self.makeOfferingsManager(remoteConfigManager: mockRemoteConfigManager)
        let captured = MockData.makeSampleOfferings()
        self.mockDeviceCache.stubbedOfferings = captured
        self.mockDeviceCache.stubbedOfferingCacheStatus = .valid

        let delivered: Atomic<Offerings?> = .init(nil)
        manager.offerings(appUserID: MockData.anyAppUserID) { result in delivered.value = result.value }

        // While delivery waits on the gate, an unrelated write (identity change, another
        // request) repopulates the shared cache slot. It must not leak into this request.
        expect(mockRemoteConfigManager.invokedTopicCount).toEventually(beGreaterThan(0))
        self.mockDeviceCache.stubbedOfferings = MockData.makeSampleOfferings()

        mockRemoteConfigManager.completeStoredTopic()
        expect(delivered.value).toEventually(beIdenticalTo(captured))
    }

    func testGatedStaleCacheDeliversTheCapturedSnapshotNotALaterCacheWrite() {
        let mockRemoteConfigManager = MockRemoteConfigManager()
        mockRemoteConfigManager.shouldStoreTopicCompletion = true
        let manager = self.makeOfferingsManager(remoteConfigManager: mockRemoteConfigManager)
        let captured = MockData.makeSampleOfferings()
        self.mockDeviceCache.stubbedOfferings = captured
        self.mockDeviceCache.stubbedOfferingCacheStatus = .stale
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        let delivered: Atomic<Offerings?> = .init(nil)
        manager.offerings(appUserID: MockData.anyAppUserID) { result in delivered.value = result.value }

        // While delivery waits on the gate, the background refresh writes a new slot value.
        expect(mockRemoteConfigManager.invokedTopicCount).toEventually(beGreaterThan(0))
        self.mockDeviceCache.stubbedOfferings = MockData.makeSampleOfferings()

        mockRemoteConfigManager.completeStoredTopic()
        // Stale delivery returns the snapshot captured for this request, never a later
        // cache write (the refresh's, or another request's).
        expect(delivered.value).toEventually(beIdenticalTo(captured))
    }

    func testGetOfferingsNetworkFetchAwaitsConfigReadyBeforeDelivering() {
        let mockRemoteConfigManager = MockRemoteConfigManager()
        let manager = self.makeOfferingsManager(remoteConfigManager: mockRemoteConfigManager)
        self.mockDeviceCache.stubbedOfferings = nil // force a network fetch
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        let result = waitUntilValue { completed in
            manager.offerings(appUserID: MockData.anyAppUserID) { completed($0) }
        }

        expect(result).to(beSuccess())
        expect(mockRemoteConfigManager.invokedTopicCount) > 0
    }

    func testGetOfferingsWaitsForPrefetchFlaggedWorkflowBlobsBeforeDelivering() {
        let mockRemoteConfigManager = MockRemoteConfigManager()
        mockRemoteConfigManager.stubbedTopics[.workflows] = [
            // Only this one is prefetch-flagged and blob-backed, so it's the only ref waited on.
            "wf-1": .init(blobRef: "wf-1-ref", prefetch: true, content: [:]),
            "wf-2": .init(blobRef: "wf-2-ref", prefetch: false, content: [:]),
            "wf-3": .init(blobRef: nil, prefetch: true, content: [:])
        ]
        let manager = self.makeOfferingsManager(remoteConfigManager: mockRemoteConfigManager)
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsContents)

        let result = waitUntilValue { completed in
            manager.offerings(appUserID: MockData.anyAppUserID) { completed($0) }
        }

        expect(result).to(beSuccess())
        expect(mockRemoteConfigManager.invokedEnsureBlobsDownloadedRefs) == [["wf-1-ref"]]
    }

    func testGetOfferingsServedFromDiskOnFailureStillAwaitsConfigReady() throws {
        let mockRemoteConfigManager = MockRemoteConfigManager()
        let manager = self.makeOfferingsManager(remoteConfigManager: mockRemoteConfigManager)
        // Offerings backend fails and falls back to the disk cache.
        self.mockDeviceCache.stubbedOfferings = nil
        self.mockOfferings.stubbedGetOfferingsCompletionResult = .failure(.networkError(.serverDown()))
        self.mockDeviceCache.stubbedCachedOfferingsData = try MockData.anyBackendOfferingsContents.jsonEncodedData

        let result: Result<Offerings, OfferingsManager.Error>? = waitUntilValue { completed in
            manager.offerings(appUserID: MockData.anyAppUserID) { completed($0) }
        }

        // Offerings are still delivered from disk, and remote config is awaited so the offeringId →
        // workflowId map has a chance to resolve rather than being left unresolved.
        expect(result).to(beSuccess())
        expect(result?.value?.loadedFromDiskCache) == true
        expect(mockRemoteConfigManager.invokedTopicCount) > 0
    }

    private func makeOfferingsManager(remoteConfigManager: RemoteConfigManagerType?) -> OfferingsManager {
        return OfferingsManager(deviceCache: self.mockDeviceCache,
                                operationDispatcher: self.mockOperationDispatcher,
                                systemInfo: self.mockSystemInfo,
                                backend: self.mockBackend,
                                offeringsFactory: self.mockOfferingsFactory,
                                productsManager: self.mockProductsManager,
                                diagnosticsTracker: self.mockDiagnosticsTracker,
                                remoteConfigManager: remoteConfigManager)
    }

}
