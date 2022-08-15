//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendGetOfferingsTests.swift
//
//  Created by Nacho Soto on 3/7/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendGetOfferingsTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testGetOfferingsCallsHTTPMethod() {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.noOfferingsResponse as [String: Any])
        )

        var result: Result<OfferingsResponse, BackendError>?

        self.offerings.getOfferings(appUserID: Self.userID, withRandomDelay: false) {
            result = $0
        }

        expect(self.httpClient.calls.count).toEventually(equal(1))
        expect(result).toEventually(beSuccess())
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadRandomDelayParam) == false
    }

    func testGetOfferingsCallsHTTPMethodWithRandomDelay() {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.noOfferingsResponse as [String: Any])
        )

        var result: Result<OfferingsResponse, BackendError>?

        self.offerings.getOfferings(appUserID: Self.userID, withRandomDelay: true) {
            result = $0
        }

        expect(self.httpClient.calls.count).toEventually(equal(1))
        expect(result).toEventually(beSuccess())
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadRandomDelayParam) == true
    }

    func testGetOfferingsCachesForSameUserID() {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.noOfferingsResponse as [String: Any])
        )
        self.offerings.getOfferings(appUserID: Self.userID, withRandomDelay: false) { _ in }
        self.offerings.getOfferings(appUserID: Self.userID, withRandomDelay: false) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testGetEntitlementsDoesntCacheForMultipleUserID() {
        let response = MockHTTPClient.Response(statusCode: .success,
                                               response: Self.noOfferingsResponse as [String: Any])
        let userID2 = "user_id_2"

        self.httpClient.mock(requestPath: .getOfferings(appUserID: Self.userID), response: response)
        self.httpClient.mock(requestPath: .getOfferings(appUserID: userID2), response: response)

        self.offerings.getOfferings(appUserID: Self.userID, withRandomDelay: false, completion: { _ in })
        self.offerings.getOfferings(appUserID: userID2, withRandomDelay: false, completion: { _ in })

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testGetOfferingsOneOffering() throws {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.oneOfferingResponse)
        )

        var result: Result<OfferingsResponse, BackendError>?
        self.offerings.getOfferings(appUserID: Self.userID, withRandomDelay: false) {
            result = $0
        }

        expect(result).toEventuallyNot(beNil())

        let offerings = try XCTUnwrap(result?.value?.offerings)
        let offeringA = try XCTUnwrap(offerings.first)
        let packages = try XCTUnwrap(offeringA.packages)
        let packageA = packages[0]
        let packageB = packages[1]

        expect(offerings).to(haveCount(1))
        expect(offeringA.identifier) == "offering_a"
        expect(offeringA.description) == "This is the base offering"
        expect(packageA.identifier) == "$rc_monthly"
        expect(packageA.platformProductIdentifier) == "monthly_freetrial"
        expect(packageB.identifier) == "$rc_annual"
        expect(packageB.platformProductIdentifier) == "annual_freetrial"
        expect(result?.value?.currentOfferingId) == "offering_a"
    }

    func testGetOfferingsFailSendsNil() {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(error: .unexpectedResponse(nil))
        )

        var result: Result<OfferingsResponse, BackendError>?

        self.offerings.getOfferings(appUserID: Self.userID, withRandomDelay: false) {
            result = $0
        }

        expect(result).toEventuallyNot(beNil())
        expect(result).to(beFailure())
    }

    func testGetOfferingsNetworkErrorSendsError() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(error: mockedError)
        )

        var result: Result<OfferingsResponse, BackendError>?
        self.offerings.getOfferings(appUserID: Self.userID, withRandomDelay: false) {
            result = $0
        }

        expect(result).toEventuallyNot(beNil())
        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testGetOfferingsSkipsBackendCallIfAppUserIDIsEmpty() {
        var completionCalled = false

        self.offerings.getOfferings(appUserID: "", withRandomDelay: false) { _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetOfferingsCallsCompletionWithErrorIfAppUserIDIsEmpty() {
        var receivedError: BackendError?

        self.offerings.getOfferings(appUserID: "", withRandomDelay: false) { result in
            receivedError = result.error
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError) == .missingAppUserID()
    }

}

private extension BackendGetOfferingsTests {

    static let noOfferingsResponse: [String: Any?] = [
        "offerings": [],
        "current_offering_id": nil
    ]

    static let oneOfferingResponse: [String: Any] = [
        "offerings": [
            [
                "identifier": "offering_a",
                "description": "This is the base offering",
                "packages": [
                    [
                        "identifier": "$rc_monthly",
                        "platform_product_identifier": "monthly_freetrial"
                    ],
                    [
                        "identifier": "$rc_annual",
                        "platform_product_identifier": "annual_freetrial"
                    ]
                ]
            ]
        ],
        "current_offering_id": "offering_a"
    ]

}
