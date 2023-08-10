//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesDiagnosticsTests.swift
//
//  Created by Nacho Soto on 10/10/22.

import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
class PurchasesDiagnosticsTests: TestCase {

    private var purchases: MockPurchases!
    private var diagnostics: PurchasesDiagnostics!

    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        self.purchases = .init()
        self.diagnostics = .init(purchases: self.purchases)

        self.purchases.mockedHealthRequestResponse = .success(())
        self.purchases.mockedCustomerInfoResponse = .success(.emptyInfo)
        self.purchases.mockedOfferingsResponse = .success(.init(offerings: [:],
                                                                currentOfferingID: nil,
                                                                response: .init(currentOfferingId: nil, offerings: [])))
    }

    func testFailingHealthRequest() async throws {
        let error = ErrorUtils.offlineConnectionError().asPublicError
        self.purchases.mockedHealthRequestResponse = .failure(error)

        do {
            try await self.diagnostics.testSDKHealth()
            fail("Expected error")
        } catch let PurchasesDiagnostics.Error.failedConnectingToAPI(underlyingError) {
            expect(underlyingError).to(matchError(error))
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testFailingAuthenticatedRequest() async throws {
        let error = ErrorUtils
            .backendError(withBackendCode: .invalidAPIKey,
                          originalBackendErrorCode: BackendErrorCode.invalidAPIKey.rawValue,
                          backendMessage: "Invalid API key")
            .asPublicError
        self.purchases.mockedCustomerInfoResponse = .failure(error)

        do {
            try await self.diagnostics.testSDKHealth()
            fail("Expected error")
        } catch PurchasesDiagnostics.Error.invalidAPIKey {
            // Expected error
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testFailingOfferingsRequest() async throws {
        let error = OfferingsManager.Error.missingProducts(identifiers: ["a"]).asPublicError
        self.purchases.mockedOfferingsResponse = .failure(error)

        do {
            try await self.diagnostics.testSDKHealth()
            fail("Expected error")
        } catch let PurchasesDiagnostics.Error.failedFetchingOfferings(offeringsError) {
            expect(offeringsError).to(matchError(error))
            expect(self.purchases.invokedGetOfferingsParameters) == .failIfProductsAreMissing
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testDoesNotCheckSignatureVerificationIfDisabled() async throws {
        self.purchases.mockedResponseVerificationMode = .disabled

        self.purchases.mockedHealthRequestWithSignatureVerificationResponse = .failure(
            ErrorUtils.signatureVerificationFailedError(path: HTTPRequest.Path.health.relativePath,
                                                        code: .success).asPublicError
        )

        try await self.diagnostics.testSDKHealth()
    }

    func testFailingSignatureVerification() async throws {
        self.purchases.mockedResponseVerificationMode = Signing.verificationMode(with: .informational)

        let expectedError = ErrorUtils.signatureVerificationFailedError(path: HTTPRequest.Path.health.relativePath,
                                                                        code: .success)
        self.purchases.mockedHealthRequestWithSignatureVerificationResponse = .failure(expectedError.asPublicError)

        do {
            try await self.diagnostics.testSDKHealth()
            fail("Expected error")
        } catch let PurchasesDiagnostics.Error.failedMakingSignedRequest(error) {
            expect(error).to(matchError(expectedError))
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testSuccessfulTest() async throws {
        do {
            try await self.diagnostics.testSDKHealth()
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    // MARK: - Errors

    func testUnknownError() {
        let underlyingError = ErrorUtils.missingReceiptFileError(nil)
        let error = PurchasesDiagnostics.Error.unknown(underlyingError)

        expect(error.errorUserInfo[NSUnderlyingErrorKey] as? NSError).to(matchError(underlyingError))
        expect(error.localizedDescription) == "Unknown error: \(underlyingError.localizedDescription)"
    }

    func testInvalidAPIKey() {
        let error = PurchasesDiagnostics.Error.invalidAPIKey

        expect(error.errorUserInfo[NSUnderlyingErrorKey] as? NSNull).toNot(beNil())
        expect(error.localizedDescription) == "API key is not valid"
    }

    func testFailedConnectingToAPI() {
        let underlyingError = ErrorUtils.offlineConnectionError()
        let error = PurchasesDiagnostics.Error.failedConnectingToAPI(underlyingError)

        expect(error.errorUserInfo[NSUnderlyingErrorKey] as? NSError).to(matchError(underlyingError))
        expect(error.localizedDescription) == "Error connecting to API: \(underlyingError.localizedDescription)"
    }

    func testFailedFetchingOfferings() {
        let underlyingError = OfferingsManager.Error.missingProducts(identifiers: ["a"]).asPublicError
        let error = PurchasesDiagnostics.Error.failedFetchingOfferings(underlyingError)

        expect(error.errorUserInfo[NSUnderlyingErrorKey] as? NSError).to(matchError(underlyingError))
        expect(error.localizedDescription) == "Failed fetching offerings: \(underlyingError.localizedDescription)"
    }

}
