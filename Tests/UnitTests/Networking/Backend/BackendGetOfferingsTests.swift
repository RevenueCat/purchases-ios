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

        let result = waitUntilValue { completed in
            self.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: false, completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadRandomDelayParam) == false
    }

    func testGetOfferingsCallsHTTPMethodWithRandomDelay() {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.noOfferingsResponse as [String: Any])
        )

        let result = waitUntilValue { completed in
            self.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: true, completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadRandomDelayParam) == true
    }

    func testGetOfferingsCachesForSameUserID() {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: Self.noOfferingsResponse as [String: Any],
                            delay: .milliseconds(10))
        )
        self.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: false) { _ in }
        self.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: false) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testRepeatedRequestsLogDebugMessage() {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: Self.noOfferingsResponse as [String: Any],
                            delay: .milliseconds(10))
        )
        self.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: false) { _ in }
        self.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: false) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))

        self.logger.verifyMessageWasLogged(
            "Network operation '\(GetOfferingsOperation.self)' found with the same cache key",
            level: .debug
        )
    }

    func testGetEntitlementsDoesntCacheForMultipleUserID() {
        let response = MockHTTPClient.Response(statusCode: .success,
                                               response: Self.noOfferingsResponse as [String: Any])
        let userID2 = "user_id_2"

        self.httpClient.mock(requestPath: .getOfferings(appUserID: Self.userID), response: response)
        self.httpClient.mock(requestPath: .getOfferings(appUserID: userID2), response: response)

        self.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: false, completion: { _ in })
        self.offerings.getOfferings(appUserID: userID2, isAppBackgrounded: false, completion: { _ in })

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testGetOfferingsOneOffering() throws {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.oneOfferingResponse)
        )

        let result: Atomic<Result<OfferingsResponse, BackendError>?> = nil
        self.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: false) {
            result.value = $0
        }

        expect(result.value).toEventuallyNot(beNil())

        let response = try XCTUnwrap(result.value?.value)
        let offerings = try XCTUnwrap(response.offerings)
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
        expect(response.currentOfferingId) == "offering_a"
    }

    func testGetOfferingsFailSendsNil() {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(error: .unexpectedResponse(nil))
        )

        let result = waitUntilValue { completed in
            self.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: false, completion: completed)
        }

        expect(result).to(beFailure())
    }

    func testGetOfferingsNetworkErrorSendsError() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(error: mockedError)
        )

        let result = waitUntilValue { completed in
            self.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: false, completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testGetOfferingsSkipsBackendCallIfAppUserIDIsEmpty() {
        waitUntil { completed in
            self.offerings.getOfferings(appUserID: "", isAppBackgrounded: false) { _ in
                completed()
            }
        }

        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetOfferingsCallsCompletionWithErrorIfAppUserIDIsEmpty() {
        let receivedError = waitUntilValue { completed in
            self.offerings.getOfferings(appUserID: "", isAppBackgrounded: false) { result in
                completed(result.error)
            }
        }

        expect(receivedError) == .missingAppUserID()
    }

}

private extension BackendGetOfferingsTests {

    static let noOfferingsResponse: [String: Any?] = [
        "offerings": [] as [Any],
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
            ] as [String: Any]
        ],
        "current_offering_id": "offering_a"
    ]

}
