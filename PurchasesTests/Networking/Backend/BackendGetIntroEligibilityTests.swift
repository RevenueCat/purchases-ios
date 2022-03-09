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
        backend.getIntroEligibility(appUserID: Self.userID,
                                    receiptData: Data(),
                                    productIdentifiers: [],
                                    completion: { _, error in
            expect(error).to(beNil())
        })

        expect(self.httpClient.calls.count).to(equal(0))
    }

    func testPostsProductIdentifiers() throws {
        self.httpClient.mock(
            requestPath: .getIntroEligibility(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: ["producta": true, "productb": false, "productd": NSNull()])
        )

        var eligibility: [String: IntroEligibility]?

        let products = ["producta", "productb", "productc", "productd"]
        backend.getIntroEligibility(appUserID: Self.userID,
                                    receiptData: Data(1...3),
                                    productIdentifiers: products,
                                    completion: {(productEligibility, error) in
            expect(error).to(beNil())
            eligibility = productEligibility

        })

        let expectedCall = MockHTTPClient.Call(
            request: .init(method: .post([:]), path: .getIntroEligibility(appUserID: Self.userID)),
            headers: HTTPClient.authorizationHeader(withAPIKey: Self.apiKey)
        )

        expect(self.httpClient.calls).toEventually(haveCount(1))
        if httpClient.calls.count > 0 {
            let call = httpClient.calls[0]

            try call.expectToEqual(expectedCall)
        }

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
        backend.getIntroEligibility(appUserID: Self.userID,
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
        // Set us up for a 404 because if the input sanitizing code fails, it will execute and we'd get a 404.
        self.httpClient.mock(
            requestPath: .getIntroEligibility(appUserID: ""),
            response: .init(statusCode: .notFoundError, response: nil)
        )

        var eligibility: [String: IntroEligibility]?
        let products = ["producta"]
        var eventualError: NSError?
        backend.getIntroEligibility(appUserID: "",
                                    receiptData: Data.init(1...2),
                                    productIdentifiers: products,
                                    completion: {(productEligibility, error) in
            eventualError = error as NSError?
            eligibility = productEligibility
        })

        expect(eligibility).toEventuallyNot(beNil())
        expect(eligibility!["producta"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eventualError).toEventuallyNot(beNil())
        expect(eventualError?.domain).to(equal(RCPurchasesErrorCodeDomain))
        expect(eventualError?.localizedDescription).to(equal(ErrorUtils.missingAppUserIDError().localizedDescription))

        var errorComingFromBackend = (eventualError?.userInfo[NSUnderlyingErrorKey]) as? NSError
        var wasRequestSent = errorComingFromBackend != nil
        expect(wasRequestSent) == false

        backend.getIntroEligibility(appUserID: "   ",
                                    receiptData: Data.init(1...2),
                                    productIdentifiers: products,
                                    completion: {(productEligibility, error) in
            eventualError = error as NSError?
            eligibility = productEligibility
        })

        expect(eligibility!["producta"]!.status).toEventually(equal(IntroEligibilityStatus.unknown))
        expect(eventualError).toEventuallyNot(beNil())
        expect(eventualError?.domain).to(equal(RCPurchasesErrorCodeDomain))
        expect(eventualError?.localizedDescription).to(equal(ErrorUtils.missingAppUserIDError().localizedDescription))

        errorComingFromBackend = (eventualError?.userInfo[NSUnderlyingErrorKey]) as? NSError
        wasRequestSent = errorComingFromBackend != nil
        expect(wasRequestSent) == false

    }

    func testEligibilityUnknownIfUnknownError() {
        let error = NSError(domain: "myhouse", code: 12, userInfo: nil) as Error
        self.httpClient.mock(
            requestPath: .getIntroEligibility(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.serverErrorResponse, error: error)
        )

        var eligibility: [String: IntroEligibility]?

        let products = ["producta", "productb", "productc"]
        backend.getIntroEligibility(appUserID: Self.userID,
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
        backend.getIntroEligibility(appUserID: Self.userID,
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
