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

        var offeringsData: [String: Any]?

        backend.getOfferings(appUserID: Self.userID, completion: { (responseFromBackend, _) in
            offeringsData = responseFromBackend
        })

        expect(self.httpClient.calls.count).toEventuallyNot(equal(0))
        expect(offeringsData).toEventuallyNot(beNil())
    }

    func testGetOfferingsCachesForSameUserID() {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.noOfferingsResponse as [String: Any])
        )
        backend.getOfferings(appUserID: Self.userID) { (_, _) in }
        backend.getOfferings(appUserID: Self.userID) { (_, _) in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testGetEntitlementsDoesntCacheForMultipleUserID() {
        let response = MockHTTPClient.Response(statusCode: .success,
                                               response: Self.noOfferingsResponse as [String: Any])
        let userID2 = "user_id_2"

        self.httpClient.mock(requestPath: .getOfferings(appUserID: Self.userID), response: response)
        self.httpClient.mock(requestPath: .getOfferings(appUserID: userID2), response: response)

        backend.getOfferings(appUserID: Self.userID, completion: { (_, _) in })
        backend.getOfferings(appUserID: userID2, completion: { (_, _) in })

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testGetOfferingsOneOffering() {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.oneOfferingResponse)
        )

        var responseReceived: [String: Any]?
        var offerings: [[String: Any]]?
        var offeringA: [String: Any]?
        var packageA: [String: String]?
        var packageB: [String: String]?
        backend.getOfferings(appUserID: Self.userID, completion: { (response, _) in
            offerings = response?["offerings"] as? [[String: Any]]
            offeringA = offerings?[0]
            let packages = offeringA?["packages"] as? [[String: String]]
            packageA = packages?[0]
            packageB = packages?[1]
            responseReceived = response
        })

        expect(offerings?.count).toEventually(equal(1))
        expect(offeringA?["identifier"] as? String).toEventually(equal("offering_a"))
        expect(offeringA?["description"] as? String).toEventually(equal("This is the base offering"))
        expect(packageA?["identifier"]).toEventually(equal("$rc_monthly"))
        expect(packageA?["platform_product_identifier"]).toEventually(equal("monthly_freetrial"))
        expect(packageB?["identifier"]).toEventually(equal("$rc_annual"))
        expect(packageB?["platform_product_identifier"]).toEventually(equal("annual_freetrial"))
        expect(responseReceived?["current_offering_id"] as? String).toEventually(equal("offering_a"))
    }

    func testGetOfferingsFailSendsNil() {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .internalServerError, response: Self.oneOfferingResponse)
        )

        var offerings: [String: Any]? = [:]

        backend.getOfferings(appUserID: Self.userID, completion: { (newOfferings, _) in
            offerings = newOfferings
        })

        expect(offerings).toEventually(beNil())
    }

    func testGetOfferingsNetworkErrorSendsNilAndError() {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: nil,
                            error: NSError(domain: NSURLErrorDomain, code: -1009))
        )

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?
        backend.getOfferings(appUserID: Self.userID, completion: { (_, error) in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(ErrorCode._nsErrorDomain))
        expect(receivedError?.code).toEventually(equal(ErrorCode.networkError.rawValue))
        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.domain).toEventually(equal(NSURLErrorDomain))
        expect(receivedUnderlyingError?.code).toEventually(equal(-1009))
    }

    func test500GetOfferingsUnexpectedResponse() {
        self.httpClient.mock(
            requestPath: .getOfferings(appUserID: Self.userID),
            response: .init(statusCode: .internalServerError, response: Self.serverErrorResponse)
        )

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?
        backend.getOfferings(appUserID: Self.userID, completion: { (_, error) in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.code).toEventually(be(ErrorCode.invalidCredentialsError.rawValue))

        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.localizedDescription) == Self.serverErrorResponse["message"]
    }

    func testGetOfferingsSkipsBackendCallIfAppUserIDIsEmpty() {
        var completionCalled = false

        backend.getOfferings(appUserID: "", completion: { (_, _) in
            completionCalled = true
        })

        expect(completionCalled).toEventually(beTrue())
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetOfferingsCallsCompletionWithErrorIfAppUserIDIsEmpty() {
        var completionCalled = false
        var receivedError: Error?

        backend.getOfferings(appUserID: "", completion: { (_, error) in
            completionCalled = true
            receivedError = error
        })

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
