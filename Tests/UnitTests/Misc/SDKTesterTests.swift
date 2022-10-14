//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SDKTesterTests.swift
//
//  Created by Nacho Soto on 10/10/22.

import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
class SDKTesterTests: TestCase {

    private var purchases: MockPurchases!
    private var tester: SDKTester!

    override func setUp() async throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        self.purchases = .init()
        self.tester = .init(purchases: self.purchases)

        self.purchases.mockedHealthRequestResponse = .success(())
        self.purchases.mockedCustomerInfoResponse = .success(
            try CustomerInfo(data: [
                "request_date": "2019-08-16T10:30:42Z",
                "subscriber": [
                    "first_seen": "2019-07-17T00:05:54Z",
                    "original_app_user_id": "",
                    "subscriptions": [:],
                    "other_purchases": [:]
                ]])
        )
        self.purchases.mockedOfferingsResponse = .success(.init(offerings: [:], currentOfferingID: nil))
    }

    func testFailingHealthRequest() async throws {
        let error = ErrorUtils.offlineConnectionError().asPublicError
        self.purchases.mockedHealthRequestResponse = .failure(error)

        do {
            try await self.tester.test()
            fail("Expected error")
        } catch let SDKTester.Error.failedConnectingToAPI(underlyingError) {
            expect(underlyingError).to(matchError(error))
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testFailingAuthenticatedRequest() async throws {
        let error = ErrorUtils
            .backendError(withBackendCode: .invalidAPIKey, backendMessage: "Invalid API key")
            .asPublicError
        self.purchases.mockedCustomerInfoResponse = .failure(error)

        do {
            try await self.tester.test()
            fail("Expected error")
        } catch SDKTester.Error.invalidAPIKey {
            // Expected error
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testFailingOfferingsRequest() async throws {
        let error = OfferingsManager.Error.missingProducts(identifiers: ["a"]).asPublicError
        self.purchases.mockedOfferingsResponse = .failure(error)

        do {
            try await self.tester.test()
            fail("Expected error")
        } catch let SDKTester.Error.failedFetchingOfferings(offeringsError) {
            expect(offeringsError).to(matchError(error))
            expect(self.purchases.invokedGetOfferingsParameters) == .failIfProductsAreMissing
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testSuccessfulTest() async throws {
        do {
            try await self.tester.test()
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    // MARK: - Errors

    func testUnknownError() {
        let underlyingError = ErrorUtils.missingReceiptFileError()
        let error = SDKTester.Error.unknown(underlyingError)

        expect(error.errorUserInfo[NSUnderlyingErrorKey] as? NSError).to(matchError(underlyingError))
        expect(error.localizedDescription) == "Unknown error: \(underlyingError.localizedDescription)"
    }

    func testInvalidAPIKey() {
        let error = SDKTester.Error.invalidAPIKey

        expect(error.errorUserInfo[NSUnderlyingErrorKey] as? NSNull).toNot(beNil())
        expect(error.localizedDescription) == "API key is not valid"
    }

    func testFailedConnectingToAPI() {
        let underlyingError = ErrorUtils.offlineConnectionError()
        let error = SDKTester.Error.failedConnectingToAPI(underlyingError)

        expect(error.errorUserInfo[NSUnderlyingErrorKey] as? NSError).to(matchError(underlyingError))
        expect(error.localizedDescription) == "Error connecting to API: \(underlyingError.localizedDescription)"
    }

    func testFailedFetchingOfferings() {
        let underlyingError = OfferingsManager.Error.missingProducts(identifiers: ["a"]).asPublicError
        let error = SDKTester.Error.failedFetchingOfferings(underlyingError)

        expect(error.errorUserInfo[NSUnderlyingErrorKey] as? NSError).to(matchError(underlyingError))
        expect(error.localizedDescription) == "Failed fetching offerings: \(underlyingError.localizedDescription)"
    }

}
