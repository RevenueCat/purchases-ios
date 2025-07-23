//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendGetWebOfferingProductsTests.swift
//
//  Created by Toni Rico on 5/21/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendGetWebOfferingProductsTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testGetWebOfferingProductsCallsHTTPMethod() {
        self.httpClient.mock(
            requestPath: .getWebOfferingProducts(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.noOfferingsResponse as [String: Any])
        )

        let result = waitUntilValue { completed in
            self.offerings.getWebOfferingProducts(appUserID: Self.userID, completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    func testGetWebOfferingProductsCallsHTTPMethodWithNoDelay() {
        self.httpClient.mock(
            requestPath: .getWebOfferingProducts(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.noOfferingsResponse as [String: Any])
        )

        let result = waitUntilValue { completed in
            self.offerings.getWebOfferingProducts(appUserID: Self.userID, completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    func testGetWebOfferingProductsCachesForSameUserID() {
        self.httpClient.mock(
            requestPath: .getWebOfferingProducts(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: Self.noOfferingsResponse as [String: Any],
                            delay: .milliseconds(10))
        )
        self.offerings.getWebOfferingProducts(appUserID: Self.userID) { _ in }
        self.offerings.getWebOfferingProducts(appUserID: Self.userID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testRepeatedRequestsLogDebugMessage() {
        self.httpClient.mock(
            requestPath: .getWebOfferingProducts(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: Self.noOfferingsResponse as [String: Any],
                            delay: .milliseconds(10))
        )
        self.offerings.getWebOfferingProducts(appUserID: Self.userID) { _ in }
        self.offerings.getWebOfferingProducts(appUserID: Self.userID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))

        self.logger.verifyMessageWasLogged(
            "Network operation '\(GetWebOfferingProductsOperation.self)' found with the same cache key",
            level: .debug
        )
    }

    func testGetWebOfferingProductsDoesntCacheForMultipleUserID() {
        let response = MockHTTPClient.Response(statusCode: .success,
                                               response: Self.noOfferingsResponse as [String: Any])
        let userID2 = "user_id_2"

        self.httpClient.mock(requestPath: .getWebOfferingProducts(appUserID: Self.userID), response: response)
        self.httpClient.mock(requestPath: .getWebOfferingProducts(appUserID: userID2), response: response)

        self.offerings.getWebOfferingProducts(appUserID: Self.userID, completion: { _ in })
        self.offerings.getWebOfferingProducts(appUserID: userID2, completion: { _ in })

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testGetWebOfferingProductsOneOffering() throws {
        self.httpClient.mock(
            requestPath: .getWebOfferingProducts(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.oneOfferingResponse)
        )

        let result: Atomic<Result<WebOfferingProductsResponse, BackendError>?> = nil
        self.offerings.getWebOfferingProducts(appUserID: Self.userID) {
            result.value = $0
        }

        expect(result.value).toEventuallyNot(beNil())

        let response = try XCTUnwrap(result.value?.value)
        let offerings = try XCTUnwrap(response.offerings)
        let offeringA = try XCTUnwrap(offerings["offering_a"])
        let packages = try XCTUnwrap(offeringA.packages)
        let monthlyPackage = try XCTUnwrap(packages["$rc_monthly"])
        let annualPackage = try XCTUnwrap(packages["$rc_annual"])
        let lifetimePackage = try XCTUnwrap(packages["$rc_lifetime"])
        let monthlyPurchaseOption = try XCTUnwrap(monthlyPackage.productDetails.purchaseOptions["base_option"])
        let annualPurchaseOption = try XCTUnwrap(annualPackage.productDetails.purchaseOptions["base_option"])
        let lifetimePurchaseOption = try XCTUnwrap(lifetimePackage.productDetails.purchaseOptions["base_option"])

        expect(offerings).to(haveCount(1))
        expect(offeringA.identifier) == "offering_a"
        expect(offeringA.description) == "This is the base offering"

        expect(monthlyPackage.identifier) == "$rc_monthly"
        expect(monthlyPackage.webCheckoutUrl) == "https://test.rev.cat/web-billing-monthly"
        expect(monthlyPackage.productDetails.identifier) == "test_monthly"
        expect(monthlyPackage.productDetails.productType) == "subscription"
        expect(monthlyPackage.productDetails.title) == "Test Monthly"
        expect(monthlyPackage.productDetails.description) == "Test Monthly description"
        expect(monthlyPackage.productDetails.defaultPurchaseOptionId) == "base_option"
        expect(monthlyPurchaseOption.trial).to(beNil())
        expect(monthlyPurchaseOption.basePrice).to(beNil())
        expect(monthlyPurchaseOption.base?.periodDuration) == "P1M"
        expect(monthlyPurchaseOption.base?.cycleCount) == 1
        expect(monthlyPurchaseOption.base?.price?.amountMicros) == 8990000
        expect(monthlyPurchaseOption.base?.price?.currency) == "EUR"

        expect(annualPackage.identifier) == "$rc_annual"
        expect(annualPackage.webCheckoutUrl) == "https://test.rev.cat/web-billing-annual"
        expect(annualPackage.productDetails.identifier) == "test_annual"
        expect(annualPackage.productDetails.productType) == "subscription"
        expect(annualPackage.productDetails.title) == "Test Annual"
        expect(annualPackage.productDetails.description) == "Test Annual description"
        expect(annualPackage.productDetails.defaultPurchaseOptionId) == "base_option"
        expect(annualPurchaseOption.trial?.periodDuration) == "P7D"
        expect(annualPurchaseOption.trial?.price).to(beNil())
        expect(annualPurchaseOption.basePrice).to(beNil())
        expect(annualPurchaseOption.base?.periodDuration) == "P1Y"
        expect(annualPurchaseOption.base?.cycleCount) == 1
        expect(annualPurchaseOption.base?.price?.amountMicros) == 58990000
        expect(annualPurchaseOption.base?.price?.currency) == "EUR"

        expect(lifetimePackage.identifier) == "$rc_lifetime"
        expect(lifetimePackage.webCheckoutUrl) == "https://test.rev.cat/web-billing-lifetime"
        expect(lifetimePackage.productDetails.identifier) == "test_lifetime"
        expect(lifetimePackage.productDetails.productType) == "non_consumable"
        expect(lifetimePackage.productDetails.title) == "Test Lifetime"
        expect(lifetimePackage.productDetails.description) == "Test Lifetime description"
        expect(lifetimePackage.productDetails.defaultPurchaseOptionId) == "base_option"
        expect(lifetimePurchaseOption.trial).to(beNil())
        expect(lifetimePurchaseOption.base).to(beNil())
        expect(lifetimePurchaseOption.basePrice?.amountMicros) == 199990000
        expect(lifetimePurchaseOption.basePrice?.currency) == "EUR"
    }

    func testGetWebOfferingProductsFailSendsError() {
        self.httpClient.mock(
            requestPath: .getWebOfferingProducts(appUserID: Self.userID),
            response: .init(error: .unexpectedResponse(nil))
        )

        let result = waitUntilValue { completed in
            self.offerings.getWebOfferingProducts(appUserID: Self.userID, completion: completed)
        }

        expect(result).to(beFailure())
    }

    func testGetWebOfferingProductsNetworkErrorSendsError() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .getWebOfferingProducts(appUserID: Self.userID),
            response: .init(error: mockedError)
        )

        let result = waitUntilValue { completed in
            self.offerings.getWebOfferingProducts(appUserID: Self.userID, completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testGetWebOfferingProductsSkipsBackendCallIfAppUserIDIsEmpty() {
        waitUntil { completed in
            self.offerings.getWebOfferingProducts(appUserID: "") { _ in
                completed()
            }
        }

        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetWebOfferingProductsCallsCompletionWithErrorIfAppUserIDIsEmpty() {
        let receivedError = waitUntilValue { completed in
            self.offerings.getWebOfferingProducts(appUserID: "") { result in
                completed(result.error)
            }
        }

        expect(receivedError) == .missingAppUserID()
    }

}

private extension BackendGetWebOfferingProductsTests {

    static let noOfferingsResponse: [String: Any?] = [
        "offerings": [:] as [String: Any]
    ]

    static let oneOfferingResponse: [String: Any] = [
        "offerings": [
            "offering_a": [
                "identifier": "offering_a",
                "description": "This is the base offering",
                "packages": [
                    "$rc_monthly": [
                        "identifier": "$rc_monthly",
                        "web_checkout_url": "https://test.rev.cat/web-billing-monthly",
                        "product_details": [
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
                        ]
                    ],
                    "$rc_annual": [
                        "identifier": "$rc_annual",
                        "web_checkout_url": "https://test.rev.cat/web-billing-annual",
                        "product_details": [
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
                    ],
                    "$rc_lifetime": [
                        "identifier": "$rc_lifetime",
                        "web_checkout_url": "https://test.rev.cat/web-billing-lifetime",
                        "product_details": [
                            "identifier": "test_lifetime",
                            "product_type": "non_consumable",
                            "title": "Test Lifetime",
                            "description": "Test Lifetime description",
                            "default_purchase_option_id": "base_option",
                            "purchase_options": [
                                "base_option": [
                                    "id": "base_option",
                                    "price_id": "test_lifetime_price_id",
                                    "base_price": [
                                        "amount_micros": 199990000,
                                        "currency": "EUR"
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ] as [String: Any]
        ]
    ]

}
