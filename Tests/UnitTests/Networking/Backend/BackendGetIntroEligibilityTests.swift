//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendGetIntroEligibilityTests.swift
//
//  Created by Nacho Soto on 3/7/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendGetIntroEligibilityTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testEmptyEligibilityCheckDoesNothing() {
        var error: NSError??

        self.backend.offerings.getIntroEligibility(appUserID: Self.userID,
                                                   receiptData: Data(),
                                                   productIdentifiers: []) {
            error = $1 as NSError?
        }

        expect(error).toEventually(equal(.some(nil)))
        expect(self.httpClient.calls.count) == 0
    }

    func testPostsProductIdentifiers() throws {
        self.httpClient.mock(
            requestPath: .getIntroEligibility(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: ["producta": true, "productb": false, "productd": NSNull()])
        )

        var eligibility: [String: IntroEligibility]?

        let products = ["producta", "productb", "productc", "productd"]
        self.offerings.getIntroEligibility(appUserID: Self.userID,
                                           receiptData: Data(1...3),
                                           productIdentifiers: products,
                                           completion: {(productEligibility, error) in
            expect(error).to(beNil())
            eligibility = productEligibility

        })

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(eligibility).toEventuallyNot(beNil())

        expect(eligibility?.keys).to(contain(products))
        expect(eligibility?["producta"]?.status) == .eligible
        expect(eligibility?["productb"]?.status) == .ineligible
        expect(eligibility?["productc"]?.status) == .unknown
        expect(eligibility?["productd"]?.status) == .unknown
    }

    func testEligibilityUnknownIfError() {
        self.httpClient.mock(
            requestPath: .getIntroEligibility(appUserID: Self.userID),
            response: .init(statusCode: .invalidRequest, response: Self.serverErrorResponse)
        )

        var eligibility: [String: IntroEligibility]?

        let products = ["producta", "productb", "productc"]
        self.offerings.getIntroEligibility(appUserID: Self.userID,
                                           receiptData: Data.init(1...2),
                                           productIdentifiers: products,
                                           completion: {(productEligibility, error) in
            expect(error).to(beNil())
            eligibility = productEligibility
        })

        expect(eligibility).toEventuallyNot(beNil())

        expect(eligibility?["producta"]?.status) == .unknown
        expect(eligibility?["productb"]?.status) == .unknown
        expect(eligibility?["productc"]?.status) == .unknown
    }

    func testEligibilityUnknownIfMissingAppUserID() {
        self.httpClient.mock(
            requestPath: .getIntroEligibility(appUserID: ""),
            response: .init(error: .unexpectedResponse(nil))
        )

        var eligibility: [String: IntroEligibility]?
        let products = ["producta"]
        var eventualError: BackendError?
        self.backend.offerings.getIntroEligibility(appUserID: "",
                                                   receiptData: Data.init(1...2),
                                                   productIdentifiers: products,
                                                   completion: {(productEligibility, error) in
            eventualError = error
            eligibility = productEligibility
        })

        expect(eligibility).toEventuallyNot(beNil())
        expect(eligibility?["producta"]?.status) == IntroEligibilityStatus.unknown
        expect(eventualError) == .missingAppUserID()

        eligibility = nil
        eventualError = nil

        self.offerings.getIntroEligibility(appUserID: "   ",
                                           receiptData: Data.init(1...2),
                                           productIdentifiers: products,
                                           completion: {(productEligibility, error) in
            eventualError = error
            eligibility = productEligibility
        })

        expect(eligibility).toEventuallyNot(beNil())
        expect(eligibility?["producta"]?.status) == IntroEligibilityStatus.unknown
        expect(eventualError) == .missingAppUserID()
    }

    func testEligibilityUnknownIfUnknownError() {
        let error: NetworkError = .networkError(NSError(domain: "myhouse", code: 12, userInfo: nil))
        self.httpClient.mock(
            requestPath: .getIntroEligibility(appUserID: Self.userID),
            response: .init(error: error)
        )

        var eligibility: [String: IntroEligibility]?

        let products = ["producta", "productb", "productc"]
        self.offerings.getIntroEligibility(appUserID: Self.userID,
                                           receiptData: Data.init(1...2),
                                           productIdentifiers: products,
                                           completion: {(productEligbility, error) in
            expect(error).to(beNil())
            eligibility = productEligbility
        })

        expect(eligibility).toEventuallyNot(beNil())

        expect(eligibility?["producta"]?.status) == .unknown
        expect(eligibility?["productb"]?.status) == .unknown
        expect(eligibility?["productc"]?.status) == .unknown
    }

    func testEligibilityUnknownIfNoReceipt() {
        var eligibility: [String: IntroEligibility]?

        let products = ["producta", "productb", "productc"]
        self.offerings.getIntroEligibility(appUserID: Self.userID,
                                           receiptData: Data(),
                                           productIdentifiers: products,
                                           completion: {(productEligibility, error) in
            expect(error).to(beNil())
            eligibility = productEligibility
        })

        expect(eligibility).toEventuallyNot(beNil())

        expect(eligibility?["producta"]?.status) == .unknown
        expect(eligibility?["productb"]?.status) == .unknown
        expect(eligibility?["productc"]?.status) == .unknown
    }

}
