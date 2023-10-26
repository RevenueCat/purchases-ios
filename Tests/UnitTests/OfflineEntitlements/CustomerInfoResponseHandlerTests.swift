//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoResponseHandlerTests.swift
//
//  Created by Nacho Soto on 3/23/23.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
class BaseCustomerInfoResponseHandlerTests: TestCase {

    fileprivate let userID = "nacho"
    fileprivate var fetcher: MockPurchasedProductsFetcher!
    fileprivate var factory: CustomerInfoFactory!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // These tests are written using async for simplicity
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        self.fetcher = MockPurchasedProductsFetcher()
        self.factory = CustomerInfoFactory()
    }

    var offlineEntitlementsEnabled: Bool { return false }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
class NormalCustomerInfoResponseHandlerTests: BaseCustomerInfoResponseHandlerTests {

    func testHandleNormalResponse() async {
        let result = await self.handle(
            .success(
                .init(httpStatusCode: .success,
                      responseHeaders: [:],
                      body: .init(customerInfo: Self.sampleCustomerInfo,
                                  errorResponse: .default),
                      verificationResult: .verified)
            ),
            nil
        )
        expect(result).to(beSuccess())
        expect(result.value) == Self.sampleCustomerInfo.copy(with: .verified)

        expect(self.factory.createRequested) == false
    }

    func testHandleWithFailedVerification() async {
        let result = await self.handle(
            .success(
                .init(httpStatusCode: .success,
                      responseHeaders: [:],
                      body: .init(customerInfo: Self.sampleCustomerInfo,
                                  errorResponse: .default),
                      verificationResult: .failed)
            ),
            nil
        )
        expect(result).to(beSuccess())
        expect(result.value) == Self.sampleCustomerInfo.copy(with: .failed)

        expect(self.factory.createRequested) == false
    }

    func testNotFoundError() async {
        let error: NetworkError = .errorResponse(.default, .notFoundError)
        let result = await self.handle(
            .failure(error),
            nil
        )
        expect(result).to(beFailure())
        expect(result.error).to(matchError(BackendError.networkError(error)))

        expect(self.factory.createRequested) == false
    }

    func testCustomerInfoWithAttributeErrors() async {
        let errorResponse = ErrorResponse(
            code: .invalidSubscriberAttributes,
            originalCode: BackendErrorCode.invalidSubscriberAttributes.rawValue,
            message: "Invalid attributes",
            attributeErrors: [
                "$email": "Email is not valid"
            ]
        )

        let result = await self.handle(
            .success(
                .init(httpStatusCode: .success,
                      responseHeaders: [:],
                      body: .init(customerInfo: Self.sampleCustomerInfo,
                                  errorResponse: errorResponse),
                      verificationResult: .notRequested)
            ),
            nil
        )
        expect(result).to(beSuccess())
        expect(result.value) == Self.sampleCustomerInfo.copy(with: .notRequested)
        expect(self.factory.createRequested) == false

        self.logger.verifyMessageWasLogged(
            "\(ErrorCode.invalidSubscriberAttributesError.description) \(errorResponse.attributeErrors)",
            level: .error
        )
    }

    func testServerErrorBeforeIOS15() async throws {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            throw XCTSkip("This test is for older versions")
        }

        self.fetcher.stubbedResult = .success([
            Self.purchasedProduct
        ])
        self.factory.stubbedResult = Self.offlineCustomerInfo

        let error: NetworkError = .serverDown()

        let result = await self.handle(.failure(error), Self.mapping)
        expect(result).to(beFailure())
        expect(result.error).to(matchError(BackendError.networkError(error)))

        expect(self.factory.createRequested) == false
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class OfflineCustomerInfoResponseHandlerTests: BaseCustomerInfoResponseHandlerTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    override var offlineEntitlementsEnabled: Bool { return true }

    func testServerErrorWithNoEntitlementMappingAndNoProducts() async {
        self.fetcher.stubbedResult = .success([])
        self.factory.stubbedResult = Self.offlineCustomerInfo

        let error: NetworkError = .serverDown()

        let result = await self.handle(.failure(error), nil)
        expect(result).to(beFailure())
        expect(result.error).to(matchError(BackendError.networkError(error)))

        expect(self.factory.createRequested) == false

        self.logger.verifyMessageWasLogged(
            Strings.offlineEntitlements.computing_offline_customer_info_with_no_entitlement_mapping,
            level: .warn
        )
    }

    func testServerErrorFailsWhenCreatingOfflineCustomerInfoWithNoMapping() async {
        self.fetcher.stubbedResult = .success([])
        self.factory.stubbedResult = Self.offlineCustomerInfo

        let error: NetworkError = .serverDown()

        let result = await self.handle(.failure(error), nil)
        expect(result).to(beFailure())
        expect(result.error).to(matchError(BackendError.networkError(error)))

        expect(self.factory.createRequested) == false

        self.logger.verifyMessageWasLogged(
            Strings.offlineEntitlements.computing_offline_customer_info_with_no_entitlement_mapping,
            level: .warn
        )
    }

    func testServerErrorCreatesOfflineCustomerInfo() async {
        self.fetcher.stubbedResult = .success([
            Self.purchasedProduct
        ])
        self.factory.stubbedResult = Self.offlineCustomerInfo

        let error: NetworkError = .serverDown()

        let result = await self.handle(.failure(error), Self.mapping)
        expect(result).to(beSuccess())
        expect(result.value) == Self.offlineCustomerInfo

        expect(self.factory.createRequested) == true
        expect(self.factory.createRequestCount) == 1
        expect(self.factory.createRequestParameters?.products) == [Self.purchasedProduct]
        expect(self.factory.createRequestParameters?.mapping) == Self.mapping
        expect(self.factory.createRequestParameters?.userID) == self.userID

        self.logger.verifyMessageWasLogged(Strings.offlineEntitlements.computing_offline_customer_info, level: .info)
        self.logger.verifyMessageWasLogged(
            Strings.offlineEntitlements.computed_offline_customer_info([Self.purchasedProduct],
                                                                       Self.offlineCustomerInfo.entitlements),
            level: .info
        )
    }

    func testCreatesOfflineCustomerInfoWithEmptyMapping() async {
        self.fetcher.stubbedResult = .success([])
        self.factory.stubbedResult = Self.offlineCustomerInfo

        let error: NetworkError = .serverDown()

        let result = await self.handle(.failure(error), .empty)
        expect(result).to(beSuccess())
        expect(result.value) == Self.offlineCustomerInfo

        expect(self.factory.createRequested) == true
    }

    func testServerErrorWithFailingPurchasedProductsFetcher() async {
        let fetcherError = StoreKitError.systemError(StoreKitError.unknown)
        let error: NetworkError = .serverDown()

        self.fetcher.stubbedResult = .failure(fetcherError)

        let result = await self.handle(.failure(error), Self.mapping)
        expect(result).to(beFailure())
        expect(result.error).to(matchError(BackendError.networkError(error)))

        expect(self.factory.createRequested) == false

        self.logger.verifyMessageWasLogged(
            Strings.offlineEntitlements.computing_offline_customer_info_failed(fetcherError),
            level: .error
        )
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
private extension BaseCustomerInfoResponseHandlerTests {

    private struct MappingFetcher: ProductEntitlementMappingFetcher {
        let productEntitlementMapping: ProductEntitlementMapping?
    }

    private func create(_ mapping: ProductEntitlementMapping?) -> CustomerInfoResponseHandler {
        return .init(
            offlineCreator: .init(
                purchasedProductsFetcher: self.fetcher,
                productEntitlementMappingFetcher: MappingFetcher(productEntitlementMapping: mapping),
                creator: self.factory.create
            ),
            userID: self.userID
        )
    }

    func handle(
        _ response: VerifiedHTTPResponse<CustomerInfoResponseHandler.Response>.Result,
        _ mapping: ProductEntitlementMapping?
    ) async -> Result<CustomerInfo, BackendError> {
        let handler = self.create(mapping)

        return await Async.call { completion in
            handler.handle(customerInfoResponse: response, completion: completion)
        }
    }

    static let purchasedProduct: PurchasedSK2Product = .init(
        productIdentifier: "product",
        subscription: .init(),
        entitlement: .init(productIdentifier: "entitlement", rawData: [:])
    )
    static let mapping: ProductEntitlementMapping = .init(entitlementsByProduct: [
        "product": ["entitlement"]
    ])

    static let sampleCustomerInfo: CustomerInfo = .init(testData: [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "subscriptions": [:] as [String: Any],
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "nacho",
            "other_purchases": [:]  as [String: Any]
        ]  as [String: Any]
    ])!
    static let offlineCustomerInfo: CustomerInfo = .init(testData: [
        "request_date": "2023-08-16T10:30:42Z",
        "subscriber": [
            "subscriptions": [
                "monthly_freetrial": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2019-07-26T23:50:40Z",
                    "is_sandbox": true,
                    "original_purchase_date": "2019-07-26T23:30:41Z",
                    "period_type": "normal",
                    "purchase_date": "2019-07-26T23:45:40Z",
                    "store": "app_store",
                    "unsubscribe_detected_at": nil
                ]  as [String: Any?]
            ],
            "non_subscriptions": [:]  as [String: Any],
            "entitlements": [
                "pro": [
                    "product_identifier": "monthly_freetrial",
                    "expires_date": "2018-12-19T02:40:36Z",
                    "purchase_date": "2018-07-26T23:30:41Z"
                ]
            ],
            "first_seen": "2023-07-17T00:05:54Z",
            "original_app_user_id": "nacho2",
            "other_purchases": [:]  as [String: Any]
        ]  as [String: Any]
    ])!

}

private final class CustomerInfoFactory {

    var stubbedResult: CustomerInfo?

    var createRequested: Bool = false
    var createRequestCount: Int = 0
    var createRequestParameters: (
        products: [PurchasedSK2Product],
        mapping: ProductEntitlementMapping,
        userID: String
    )?

    @Sendable
    func create(products: [PurchasedSK2Product], mapping: ProductEntitlementMapping, userID: String) -> CustomerInfo {
        guard let result = self.stubbedResult else {
            fatalError("Creation requested without stub")
        }

        self.createRequested = true
        self.createRequestCount += 1
        self.createRequestParameters = (products, mapping, userID)

        return result
    }

}

private extension ErrorResponse {

    static let `default`: Self = .init(code: .unknownBackendError,
                                       originalCode: BackendErrorCode.unknownError.rawValue)

}
