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

        var result: Result<[String: Any], Error>?

        backend.getOfferings(appUserID: Self.userID) {
            result = $0
        }

        expect(self.httpClient.calls.count).toEventuallyNot(equal(0))
        expect(result).toEventuallyNot(beNil())
    }

    func testGetOfferingsCachesForSameUserID() {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.noOfferingsResponse as [String: Any])
        )
        backend.getOfferings(appUserID: Self.userID) { _ in }
        backend.getOfferings(appUserID: Self.userID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testGetEntitlementsDoesntCacheForMultipleUserID() {
        let response = MockHTTPClient.Response(statusCode: .success,
                                               response: Self.noOfferingsResponse as [String: Any])
        let userID2 = "user_id_2"

        self.httpClient.mock(requestPath: .getOfferings(appUserID: Self.userID), response: response)
        self.httpClient.mock(requestPath: .getOfferings(appUserID: userID2), response: response)

        backend.getOfferings(appUserID: Self.userID, completion: { _ in })
        backend.getOfferings(appUserID: userID2, completion: { _ in })

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testGetOfferingsOneOffering() throws {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.oneOfferingResponse)
        )

        var result: Result<[String: Any], Error>?
        backend.getOfferings(appUserID: Self.userID) {
            result = $0
        }

        expect(result).toEventuallyNot(beNil())

        let offerings = try XCTUnwrap(result?.value?["offerings"] as? [[String: Any]])
        let offeringA = try XCTUnwrap(offerings[0])
        let packages = try XCTUnwrap(offeringA["packages"] as? [[String: String]])
        let packageA = packages[0]
        let packageB = packages[1]

        expect(offerings).to(haveCount(1))
        expect(offeringA["identifier"] as? String) == "offering_a"
        expect(offeringA["description"] as? String) == "This is the base offering"
        expect(packageA["identifier"]) == "$rc_monthly"
        expect(packageA["platform_product_identifier"]) == "monthly_freetrial"
        expect(packageB["identifier"]) == "$rc_annual"
        expect(packageB["platform_product_identifier"]) == "annual_freetrial"
        expect(result?.value?["current_offering_id"] as? String) == "offering_a"
    }

    func testGetOfferingsFailSendsNil() {
        let mockedError = ErrorCode.unknownBackendError as NSError

        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(error: mockedError)
        )

        var offerings: [String: Any]? = [:]

        backend.getOfferings(appUserID: Self.userID) { result in
            offerings = result.value
        }

        expect(offerings).toEventually(beNil())
    }

    func testGetOfferingsNetworkErrorSendsError() {
        let mockedError = NSError(domain: NSURLErrorDomain, code: -1009)

        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(error: mockedError)
        )

        var result: Result<[String: Any], Error>?
        backend.getOfferings(appUserID: Self.userID) {
            result = $0
        }

        expect(result).toEventuallyNot(beNil())
        expect(result).to(beFailure())
        expect(result?.error as NSError?) == mockedError
    }

    func testGetOfferingsSkipsBackendCallIfAppUserIDIsEmpty() {
        var completionCalled = false

        backend.getOfferings(appUserID: "") { _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetOfferingsCallsCompletionWithErrorIfAppUserIDIsEmpty() {
        var completionCalled = false
        var receivedError: Error?

        backend.getOfferings(appUserID: "") { result in
            completionCalled = true
            receivedError = result.error
        }

        expect(completionCalled).toEventually(beTrue())
        expect((receivedError! as NSError).code) == ErrorCode.invalidAppUserIdError.rawValue
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
