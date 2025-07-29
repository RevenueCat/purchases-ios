//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendGetWebProductsTests.swift
//
//  Created by Antonio Pallares on 23/7/25.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendGetWebProductsTests: BaseBackendTests {

    private let productIds: Set<String> = ["test_monthly", "test_annual"]

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testGetWebProductsCallsHTTPMethod() {
        self.httpClient.mock(
            requestPath: .getWebBillingProducts(userId: Self.userID, productIds: self.productIds),
            response: .init(statusCode: .success, response: Self.noProductsResponse as [String: Any])
        )

        let result = waitUntilValue { completed in
            self.offerings.getWebProducts(appUserID: Self.userID, productIds: self.productIds, completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    func testGetWebProductsCallsHTTPMethodWithNoDelay() {
        self.httpClient.mock(
            requestPath: .getWebBillingProducts(userId: Self.userID, productIds: self.productIds),
            response: .init(statusCode: .success, response: Self.noProductsResponse as [String: Any])
        )

        let result = waitUntilValue { completed in
            self.offerings.getWebProducts(appUserID: Self.userID, productIds: self.productIds, completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    func testGetWebProductsCachesForSameUserIDAndProductIds() {
        self.httpClient.mock(
            requestPath: .getWebBillingProducts(userId: Self.userID, productIds: self.productIds),
            response: .init(statusCode: .success,
                            response: Self.noProductsResponse as [String: Any],
                            delay: .milliseconds(10))
        )
        self.offerings.getWebProducts(appUserID: Self.userID, productIds: self.productIds) { _ in }
        self.offerings.getWebProducts(appUserID: Self.userID, productIds: self.productIds) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testRepeatedRequestsLogDebugMessage() {
        self.httpClient.mock(
            requestPath: .getWebBillingProducts(userId: Self.userID, productIds: self.productIds),
            response: .init(statusCode: .success,
                            response: Self.noProductsResponse as [String: Any],
                            delay: .milliseconds(10))
        )
        self.offerings.getWebProducts(appUserID: Self.userID, productIds: self.productIds) { _ in }
        self.offerings.getWebProducts(appUserID: Self.userID, productIds: self.productIds) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))

        self.logger.verifyMessageWasLogged(
            "Network operation '\(GetWebBillingProductsOperation.self)' found with the same cache key",
            level: .debug
        )
    }

    func testGetWebProductsDoesntCacheForMultipleUserID() {
        let response = MockHTTPClient.Response(statusCode: .success,
                                               response: Self.noProductsResponse as [String: Any])
        let userID2 = "user_id_2"

        self.httpClient.mock(requestPath: .getWebBillingProducts(userId: Self.userID, productIds: self.productIds),
                             response: response)
        self.httpClient.mock(requestPath: .getWebBillingProducts(userId: userID2, productIds: self.productIds),
                             response: response)

        self.offerings.getWebProducts(appUserID: Self.userID, productIds: self.productIds, completion: { _ in })
        self.offerings.getWebProducts(appUserID: userID2, productIds: self.productIds, completion: { _ in })

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testGetWebProductsDoesntCacheForDifferentProductIds() {
        let response = MockHTTPClient.Response(statusCode: .success,
                                               response: Self.noProductsResponse as [String: Any])
        let differentProductIds: Set<String> = ["test_lifetime"]

        self.httpClient.mock(requestPath: .getWebBillingProducts(userId: Self.userID, productIds: self.productIds),
                             response: response)
        self.httpClient.mock(requestPath: .getWebBillingProducts(userId: Self.userID, productIds: differentProductIds),
                             response: response)

        self.offerings.getWebProducts(appUserID: Self.userID, productIds: self.productIds, completion: { _ in })
        self.offerings.getWebProducts(appUserID: Self.userID, productIds: differentProductIds, completion: { _ in })

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testGetWebProductsTwoProducts() throws {
        self.httpClient.mock(
            requestPath: .getWebBillingProducts(userId: Self.userID, productIds: self.productIds),
            response: .init(statusCode: .success, response: Self.twoProductsResponse)
        )

        let result: Atomic<Result<WebBillingProductsResponse, BackendError>?> = nil
        self.offerings.getWebProducts(appUserID: Self.userID, productIds: self.productIds) {
            result.value = $0
        }

        expect(result.value).toEventuallyNot(beNil())

        let response = try XCTUnwrap(result.value?.value)
        let productDetails = try XCTUnwrap(response.productDetails)
        let monthlyProduct = try XCTUnwrap(productDetails.first { $0.identifier == "test_monthly" })
        let annualProduct = try XCTUnwrap(productDetails.first { $0.identifier == "test_annual" })
        let monthlyPurchaseOption = try XCTUnwrap(monthlyProduct.purchaseOptions["base_option"])
        let annualPurchaseOption = try XCTUnwrap(annualProduct.purchaseOptions["base_option"])

        expect(productDetails).to(haveCount(2))

        expect(monthlyProduct.identifier) == "test_monthly"
        expect(monthlyProduct.productType) == .subscription
        expect(monthlyProduct.title) == "Test Monthly"
        expect(monthlyProduct.description) == "Test Monthly description"
        expect(monthlyProduct.defaultPurchaseOptionId) == "base_option"
        expect(monthlyPurchaseOption.trial).to(beNil())
        expect(monthlyPurchaseOption.basePrice).to(beNil())
        expect(monthlyPurchaseOption.base?.periodDuration) == "P1M"
        expect(monthlyPurchaseOption.base?.cycleCount) == 1
        expect(monthlyPurchaseOption.base?.price?.amountMicros) == 8990000
        expect(monthlyPurchaseOption.base?.price?.currency) == "EUR"

        expect(annualProduct.identifier) == "test_annual"
        expect(annualProduct.productType) == .subscription
        expect(annualProduct.title) == "Test Annual"
        expect(annualProduct.description) == "Test Annual description"
        expect(annualProduct.defaultPurchaseOptionId) == "base_option"
        expect(annualPurchaseOption.trial?.periodDuration) == "P7D"
        expect(annualPurchaseOption.trial?.price).to(beNil())
        expect(annualPurchaseOption.basePrice).to(beNil())
        expect(annualPurchaseOption.base?.periodDuration) == "P1Y"
        expect(annualPurchaseOption.base?.cycleCount) == 1
        expect(annualPurchaseOption.base?.price?.amountMicros) == 58990000
        expect(annualPurchaseOption.base?.price?.currency) == "EUR"
    }

    func testGetWebProductsFailSendsError() {
        self.httpClient.mock(
            requestPath: .getWebBillingProducts(userId: Self.userID, productIds: self.productIds),
            response: .init(error: .unexpectedResponse(nil))
        )

        let result = waitUntilValue { completed in
            self.offerings.getWebProducts(appUserID: Self.userID, productIds: self.productIds, completion: completed)
        }

        expect(result).to(beFailure())
    }

    func testGetWebProductsNetworkErrorSendsError() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .getWebBillingProducts(userId: Self.userID, productIds: self.productIds),
            response: .init(error: mockedError)
        )

        let result = waitUntilValue { completed in
            self.offerings.getWebProducts(appUserID: Self.userID, productIds: self.productIds, completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testGetWebProductsSkipsBackendCallIfAppUserIDIsEmpty() {
        waitUntil { completed in
            self.offerings.getWebProducts(appUserID: "", productIds: self.productIds) { _ in
                completed()
            }
        }

        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetWebProductsCallsCompletionWithErrorIfAppUserIDIsEmpty() {
        let receivedError = waitUntilValue { completed in
            self.offerings.getWebProducts(appUserID: "", productIds: self.productIds) { result in
                completed(result.error)
            }
        }

        expect(receivedError) == .missingAppUserID()
    }

}

private extension BackendGetWebProductsTests {

    static let noProductsResponse: [String: Any?] = [
        "product_details": [] as [[String: Any]]
    ]

    static let twoProductsResponse: [String: Any] = [
        "product_details": [
            [
                "identifier": "test_monthly",
                "product_type": "subscription",
                "title": "Test Monthly",
                "description": "Test Monthly description",
                "default_purchase_option_id": "base_option",
                "purchase_options": [
                    "base_option": [
                        "id": "base_option",
                        "price_id": "test_monthly_price_id",
                        "base": [
                            "cycle_count": 1,
                            "period_duration": "P1M",
                            "price": [
                                "amount_micros": 8990000,
                                "currency": "EUR"
                            ]
                        ],
                        "trial": nil
                    ]
                ]
            ],
            [
                "identifier": "test_annual",
                "product_type": "subscription",
                "title": "Test Annual",
                "description": "Test Annual description",
                "default_purchase_option_id": "base_option",
                "purchase_options": [
                    "base_option": [
                        "id": "base_option",
                        "price_id": "test_annual_price_id",
                        "base": [
                            "cycle_count": 1,
                            "period_duration": "P1Y",
                            "price": [
                                "amount_micros": 58990000,
                                "currency": "EUR"
                            ]
                        ],
                        "trial": [
                            "cycle_count": 1,
                            "period_duration": "P7D"
                        ]
                    ]
                ]
            ]
        ]
    ]

}
