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
@testable import RevenueCat
import XCTest

class BackendPostOffersForSigningTests: BaseBackendTests {

    typealias Offer = PostOfferForSigningOperation.PostOfferForSigningData
    typealias SigningResult = Result<PostOfferForSigningOperation.SigningData, BackendError>

    override func createClient() -> MockHTTPClient {
        return super.createClient(#file)
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.httpClient.disableSnapshotTesting()
    }

    func testBatchesOffersAndMatchesReorderedResponsesByProductAndOffer() throws {
        let requests: [Offer] = [
            .init(offerIdentifier: "same-offer", productIdentifier: "monthly", subscriptionGroup: "group1"),
            .init(offerIdentifier: "same-offer", productIdentifier: "annual", subscriptionGroup: "group2"),
            .init(offerIdentifier: "other-offer", productIdentifier: "monthly", subscriptionGroup: "group1")
        ]
        self.mockResponse([self.offer("monthly", "other-offer", "third"),
                           self.offer("annual", "same-offer", "second"),
                           self.offer("monthly", "same-offer", "first")])

        let results = try self.sign(requests)

        XCTAssertEqual(results.map { $0.value?.signature }, ["first", "second", "third"])
        XCTAssertEqual(self.httpClient.calls.count, 1)
        let body = try XCTUnwrap(self.httpClient.calls.first?.request.requestBody?.asJSONDictionary())
        XCTAssertEqual(body["app_user_id"] as? String, Self.userID)
        XCTAssertEqual(body["fetch_token"] as? String, "receipt-jws")
        XCTAssertEqual(body["generate_offers"] as? [[String: String]], [
            ["offer_id": "same-offer", "product_id": "monthly", "subscription_group": "group1"],
            ["offer_id": "same-offer", "product_id": "annual", "subscription_group": "group2"],
            ["offer_id": "other-offer", "product_id": "monthly", "subscription_group": "group1"]
        ])
    }

    func testDuplicateRequestsShareSignatureButKeepOneResultPerInput() throws {
        self.mockResponse([self.offer("monthly", "promo", "signature")])
        let request = Offer(offerIdentifier: "promo", productIdentifier: "monthly", subscriptionGroup: "group")

        let results = try self.sign([request, request])

        XCTAssertEqual(results.map { $0.value?.signature }, ["signature", "signature"])
        XCTAssertEqual(results[0].value?.nonce, results[1].value?.nonce)
        let body = try XCTUnwrap(self.httpClient.calls.first?.request.requestBody?.asJSONDictionary())
        XCTAssertEqual((body["generate_offers"] as? [Any])?.count, 1)
    }

    func testPerOfferErrorDoesNotDiscardOtherSignature() throws {
        var rejected = self.offer("annual", "promo", "unused")
        rejected.removeValue(forKey: "signature_data")
        rejected["signature_error"] = ["code": BackendErrorCode.userIneligibleForPromoOffer.rawValue,
                                       "message": "Ineligible"]
        self.mockResponse([rejected, self.offer("monthly", "promo", "valid")])

        let results = try self.sign(self.twoOffers)

        XCTAssertEqual(results[0].value?.signature, "valid")
        XCTAssertEqual(results[1].error?.asPurchasesError.asPublicError.code, ErrorCode.ineligibleError.rawValue)
    }

    func testMissingResponseDoesNotUseAnotherProductsSignature() throws {
        self.mockResponse([self.offer("unexpected-product", "promo", "wrong"),
                           self.offer("monthly", "promo", "valid")])
        let results = try self.sign(self.twoOffers)
        XCTAssertEqual(results[0].value?.signature, "valid")
        XCTAssertEqual(results[1].error, .unexpectedBackendResponse(.postOfferIdMissingOffersInResponse))
    }

    func testDuplicateResponseIsRejectedWithoutDiscardingOtherOffer() throws {
        self.mockResponse([self.offer("monthly", "promo", "first"),
                           self.offer("monthly", "promo", "second"),
                           self.offer("annual", "promo", "valid")])
        let results = try self.sign(self.twoOffers)
        XCTAssertNotNil(results[0].error)
        XCTAssertEqual(results[1].value?.signature, "valid")
    }

    func testMissingSignatureDoesNotDiscardOtherOffer() throws {
        var missing = self.offer("monthly", "promo", "unused")
        missing.removeValue(forKey: "signature_data")
        self.mockResponse([missing, self.offer("annual", "promo", "valid")])
        let results = try self.sign(self.twoOffers)
        XCTAssertNotNil(results[0].error)
        XCTAssertEqual(results[1].value?.signature, "valid")
    }

    func testMalformedSigningPayloadDoesNotDiscardOtherOffer() throws {
        var invalidNonce = self.offer("monthly", "promo", "unused")
        invalidNonce["signature_data"] = ["signature": "unused", "nonce": "invalid", "timestamp": 12345]
        var missingKey = self.offer("monthly", "promo", "unused")
        missingKey.removeValue(forKey: "key_id")
        var missingTimestamp = self.offer("monthly", "promo", "unused")
        missingTimestamp["signature_data"] = ["signature": "unused", "nonce": UUID().uuidString]

        for malformed in [invalidNonce, missingKey, missingTimestamp] {
            self.mockResponse([malformed, self.offer("annual", "promo", "valid")])
            let results = try self.sign(self.twoOffers)
            XCTAssertNotNil(results[0].error)
            XCTAssertEqual(results[1].value?.signature, "valid")
        }
    }

    func testMalformedDuplicateDoesNotMakeResponseUnambiguous() throws {
        var malformed = self.offer("monthly", "promo", "unused")
        malformed.removeValue(forKey: "key_id")
        self.mockResponse([malformed, self.offer("monthly", "promo", "ambiguous"),
                           self.offer("annual", "promo", "valid")])
        let results = try self.sign(self.twoOffers)
        XCTAssertEqual(results[0].error, .unexpectedBackendResponse(.postOfferIdMissingOffersInResponse))
        XCTAssertEqual(results[1].value?.signature, "valid")
    }

    func testMalformedUnidentifiedEntryDoesNotDiscardOtherOffer() throws {
        self.httpClient.mock(requestPath: .postOfferForSigning,
                             response: .init(statusCode: .success, response: [
                                "offers": [42, self.offer("annual", "promo", "valid")]
                             ]))
        let results = try self.sign(self.twoOffers)
        XCTAssertNotNil(results[0].error)
        XCTAssertEqual(results[1].value?.signature, "valid")
    }

    func testNetworkFailureIsReportedForEveryOfferWithoutIndividualRetries() throws {
        let error = NetworkError.unexpectedResponse(nil)
        self.httpClient.mock(requestPath: .postOfferForSigning, response: .init(error: error))
        let results = try self.sign(self.twoOffers)
        XCTAssertEqual(results.map(\.error), [.networkError(error), .networkError(error)])
        XCTAssertEqual(self.httpClient.calls.count, 1)
    }

    func testMalformedResponseIsReportedForEveryOffer() throws {
        self.httpClient.mock(requestPath: .postOfferForSigning,
                             response: .init(statusCode: .success, body: Data("not JSON".utf8)))
        let results = try self.sign(self.twoOffers)
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.error != nil })
    }

    func testEmptyResponseIsReportedForEveryOffer() throws {
        self.mockResponse([])
        let results = try self.sign(self.twoOffers)
        XCTAssertEqual(results.map(\.error), Array(repeating: .unexpectedBackendResponse(
            .postOfferIdMissingOffersInResponse
        ), count: 2))
    }

    func testEmptyBatchDoesNotMakeRequest() throws {
        XCTAssertTrue(try self.sign([]).isEmpty)
        XCTAssertTrue(self.httpClient.calls.isEmpty)
    }

}

private extension BackendPostOffersForSigningTests {

    var twoOffers: [Offer] {
        return ["monthly", "annual"].map {
            .init(offerIdentifier: "promo", productIdentifier: $0, subscriptionGroup: "group")
        }
    }

    func sign(_ offers: [Offer]) throws -> [SigningResult] {
        return try XCTUnwrap(waitUntilValue { completed in
            self.offerings.post(offersForSigning: offers, receipt: .jws("receipt-jws"),
                                appUserID: Self.userID, completion: completed)
        })
    }

    func mockResponse(_ offers: [[String: Any]]) {
        self.httpClient.mock(requestPath: .postOfferForSigning,
                             response: .init(statusCode: .success, response: ["offers": offers]))
    }

    func offer(_ productID: String, _ offerID: String, _ signature: String) -> [String: Any] {
        return ["offer_id": offerID, "product_id": productID, "key_id": "key",
                "signature_data": ["signature": signature, "nonce": UUID().uuidString, "timestamp": 12345]]
    }

}
