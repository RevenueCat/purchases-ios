//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendPostOfferForSigningTests.swift
//
//  Created by Nacho Soto on 3/7/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendPostOfferForSigningTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testOfferForSigningCorrectly() throws {
        let validSigningResponse: [String: Any] = [
            "offers": [
                [
                    "offer_id": "PROMO_ID",
                    "product_id": "com.myapp.product_a",
                    "key_id": "STEAKANDEGGS",
                    "signature_data": [
                        "signature": "Base64 encoded signature",
                        "nonce": "A UUID",
                        "timestamp": Int64(123413232131)
                    ]  as [String: Any],
                    "signature_error": nil
                ]  as [String: Any?]
            ]
        ]

        let path: HTTPRequest.Path = .postOfferForSigning
        let response = MockHTTPClient.Response(statusCode: .success, response: validSigningResponse)

        self.httpClient.mock(requestPath: path, response: response)

        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = EncodedAppleReceipt(receipt: "an awesome discount".asData)

        waitUntil { completed in
            self.offerings.post(offerIdForSigning: offerIdentifier,
                                productIdentifier: productIdentifier,
                                subscriptionGroup: group,
                                receiptData: discountData,
                                appUserID: Self.userID) { _ in
                completed()
            }
        }

        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testOfferForSigningNetworkError() {
        let mockedError = NetworkError.unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .postOfferForSigning,
            response: .init(error: mockedError)
        )

        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = EncodedAppleReceipt(receipt: "an awesome discount".data(using: String.Encoding.utf8)!)

        let result = waitUntilValue { completed in
            self.offerings.post(offerIdForSigning: offerIdentifier,
                                productIdentifier: productIdentifier,
                                subscriptionGroup: group,
                                receiptData: discountData,
                                appUserID: Self.userID,
                                completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testOfferForSigningEmptyOffersResponse() {
        let validSigningResponse: [String: Any] = [
            "offers": [] as [Any]
        ]

        self.httpClient.mock(
            requestPath: .postOfferForSigning,
            response: .init(statusCode: .success, response: validSigningResponse)
        )

        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = EncodedAppleReceipt(receipt: "an awesome discount".data(using: String.Encoding.utf8)!)

        let result = waitUntilValue { completed in
            self.offerings.post(offerIdForSigning: offerIdentifier,
                                productIdentifier: productIdentifier,
                                subscriptionGroup: group,
                                receiptData: discountData,
                                appUserID: Self.userID,
                                completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .unexpectedBackendResponse(.postOfferIdMissingOffersInResponse)
    }

    func testOfferForSigningSignatureErrorResponse() {
        let errorResponse = ErrorResponse(code: .invalidAppleSubscriptionKey,
                                          originalCode: 7234,
                                          message: "Ineligible for some reason")

        let validSigningResponse: [String: Any] = [
            "offers": [
                [
                    "offer_id": "PROMO_ID",
                    "product_id": "com.myapp.product_a",
                    "key_id": "STEAKANDEGGS",
                    "signature_data": nil,
                    "signature_error": [
                        "message": errorResponse.message!,
                        "code": errorResponse.code.rawValue
                    ] as [String: Any]
                ] as [String: Any?]
            ]
        ]

        self.httpClient.mock(
            requestPath: .postOfferForSigning,
            response: .init(statusCode: .success, response: validSigningResponse)
        )

        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = EncodedAppleReceipt(receipt: "an awesome discount".data(using: String.Encoding.utf8)!)

        let result = waitUntilValue { completed in
            self.offerings.post(offerIdForSigning: offerIdentifier,
                                productIdentifier: productIdentifier,
                                subscriptionGroup: group,
                                receiptData: discountData,
                                appUserID: Self.userID,
                                completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(.errorResponse(errorResponse, .success))
    }

    func testOfferForSigningNoDataAndNoSignatureErrorResponse() {
        let validSigningResponse: [String: Any] = [
            "offers": [
                [
                    "offer_id": "PROMO_ID",
                    "product_id": "com.myapp.product_a",
                    "key_id": "STEAKANDEGGS",
                    "signature_data": nil,
                    "signature_error": nil
                ]
            ]
        ]

        self.httpClient.mock(
            requestPath: .postOfferForSigning,
            response: .init(statusCode: .success, response: validSigningResponse)
        )

        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = EncodedAppleReceipt(receipt: "an awesome discount".data(using: String.Encoding.utf8)!)

        let result = waitUntilValue { completed in
            self.offerings.post(offerIdForSigning: offerIdentifier,
                                productIdentifier: productIdentifier,
                                subscriptionGroup: group,
                                receiptData: discountData,
                                appUserID: Self.userID,
                                completion: completed)
        }

        expect(result).to(beFailure())

        guard case .unexpectedBackendResponse(.postOfferIdSignature, _, _) = result?.error else {
            fail("Invalid error: \(String(describing: result))")
            return
        }
    }

}
