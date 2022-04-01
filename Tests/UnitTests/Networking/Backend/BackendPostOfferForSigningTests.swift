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
                    ],
                    "signature_error": nil
                ]
            ]
        ]

        let path: HTTPRequest.Path = .postOfferForSigning
        let response = MockHTTPClient.Response(statusCode: .success, response: validSigningResponse)

        self.httpClient.mock(requestPath: path, response: response)

        let productIdentifier = "a_great_product"
        let group = "sub_group"
        var completionCalled = false
        let offerIdentifier = "offerid"
        let discountData = "an awesome discount".data(using: String.Encoding.utf8)!

        backend.post(offerIdForSigning: offerIdentifier,
                     productIdentifier: productIdentifier,
                     subscriptionGroup: group,
                     receiptData: discountData,
                     appUserID: Self.userID) { _ in
            completionCalled = true
        }

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(completionCalled).toEventually(beTrue())
    }

    func testOfferForSigningNetworkError() {
        self.httpClient.mock(
            requestPath: .postOfferForSigning,
            response: .init(error: NSError(domain: NSURLErrorDomain, code: -1009))
        )

        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = "an awesome discount".data(using: String.Encoding.utf8)!
        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        backend.post(offerIdForSigning: offerIdentifier,
                     productIdentifier: productIdentifier,
                     subscriptionGroup: group,
                     receiptData: discountData,
                     appUserID: Self.userID) { result in
            receivedError = result.error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(ErrorCode.networkError.rawValue))
        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.domain).toEventually(equal(NSURLErrorDomain))
        expect(receivedUnderlyingError?.code).toEventually(equal(-1009))
    }

    func testOfferForSigningEmptyOffersResponse() {
        let validSigningResponse: [String: Any] = [
            "offers": []
        ]

        self.httpClient.mock(
            requestPath: .postOfferForSigning,
            response: .init(statusCode: .success, response: validSigningResponse)
        )

        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = "an awesome discount".data(using: String.Encoding.utf8)!

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        backend.post(offerIdForSigning: offerIdentifier,
                     productIdentifier: productIdentifier,
                     subscriptionGroup: group,
                     receiptData: discountData,
                     appUserID: Self.userID) { result in
            receivedError = result.error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(
            equal(ErrorCode.unexpectedBackendResponseError.rawValue))
        expect(receivedUnderlyingError?.code).toEventually(
            equal(UnexpectedBackendResponseSubErrorCode.postOfferIdMissingOffersInResponse.rawValue))
    }

    func testOfferForSigningSignatureErrorResponse() {
        let validSigningResponse: [String: Any] = [
            "offers": [
                [
                    "offer_id": "PROMO_ID",
                    "product_id": "com.myapp.product_a",
                    "key_id": "STEAKANDEGGS",
                    "signature_data": nil,
                    "signature_error": [
                        "message": "Ineligible for some reason",
                        "code": 7234
                    ]
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
        let discountData = "an awesome discount".data(using: String.Encoding.utf8)!

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        backend.post(offerIdForSigning: offerIdentifier,
                     productIdentifier: productIdentifier,
                     subscriptionGroup: group,
                     receiptData: discountData,
                     appUserID: Self.userID) { result in
            receivedError = result.error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(
            equal(ErrorCode.invalidAppleSubscriptionKeyError.rawValue))
        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.code).toEventually(equal(7234))
        expect(receivedUnderlyingError?.domain).toEventually(equal("RevenueCat.BackendErrorCode"))
        expect(receivedUnderlyingError?.localizedDescription).toEventually(equal("Ineligible for some reason"))
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
        let discountData = "an awesome discount".data(using: String.Encoding.utf8)!

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        backend.post(offerIdForSigning: offerIdentifier,
                     productIdentifier: productIdentifier,
                     subscriptionGroup: group,
                     receiptData: discountData,
                     appUserID: Self.userID) { result in
            receivedError = result.error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(
            equal(ErrorCode.unexpectedBackendResponseError.rawValue))
        expect(receivedUnderlyingError?.code).toEventually(
            equal(UnexpectedBackendResponseSubErrorCode.postOfferIdSignature.rawValue))
    }

    func testOfferForSigning501Response() throws {
        self.httpClient.mock(
            requestPath: .postOfferForSigning,
            response: .init(statusCode: 501, response: Self.serverErrorResponse)
        )

        let productIdentifier = "a_great_product"
        let group = "sub_group"
        let offerIdentifier = "offerid"
        let discountData = "an awesome discount".data(using: String.Encoding.utf8)!

        var receivedError: NSError?
        backend.post(offerIdForSigning: offerIdentifier,
                     productIdentifier: productIdentifier,
                     subscriptionGroup: group,
                     receiptData: discountData,
                     appUserID: Self.userID) { result in
            receivedError = result.error as NSError?
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.code) == ErrorCode.invalidCredentialsError.rawValue

        let receivedUnderlyingError = try XCTUnwrap(receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError)

        expect(receivedUnderlyingError.localizedDescription) == Self.serverErrorResponse["message"]
    }

}
