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

class PurchasesDiagnosticsTests: TestCase {

    private var purchases: MockPurchases!
    private var diagnostics: PurchasesDiagnostics!

    override func setUp() async throws {
        try await super.setUp()

        self.purchases = .init()
        self.diagnostics = .init(purchases: self.purchases)

        self.purchases.mockedHealthRequestResponse = .success(())
        self.purchases.mockedCustomerInfoResponse = .success(.emptyInfo)
        self.purchases.mockedOfferingsResponse = .success(
            .init(offerings: [:],
                  currentOfferingID: nil,
                  placements: nil,
                  targeting: nil,
                  response: .init(currentOfferingId: nil,
                                  offerings: [],
                                  placements: nil,
                                  targeting: nil,
                                  uiConfig: nil))
        )
    }

    func testFailingHealthRequest() async throws {
        self.purchases.mockedHealthReportRequestResponse = .success(
            HealthReport(status: .failed, projectId: nil, appId: nil, checks: [
                HealthCheck(name: HealthCheckType.apiKey, status: HealthCheckStatus.failed)
            ])
        )
        do {
            try await self.diagnostics.testSDKHealth()
            fail("Expected error")
        } catch PurchasesDiagnostics.Error.invalidAPIKey {
            /* Test succeeds */
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

    func testNoOfferings() {
        let error = PurchasesDiagnostics.Error.noOfferings

        expect(error.errorUserInfo[NSUnderlyingErrorKey] as? NSNull).toNot(beNil())
        expect(error.localizedDescription) == "No offerings configured"
    }

    func testOfferingConfigurationError() {
        let error = PurchasesDiagnostics.Error.offeringConfiguration(
            [
                .init(
                    identifier: "test_offering",
                    packages: [
                        .init(
                            identifier: "failing_package",
                            title: "Failing Package",
                            status: .notFound,
                            description: "Could not find package",
                            productIdentifier: "failing_product_identifier",
                            productTitle: "Failing Product Title"
                        )
                    ],
                    status: .failed
                )
            ]
        )

        expect(error.errorUserInfo[NSUnderlyingErrorKey] as? NSNull).toNot(beNil())
        let expected = "Offering 'test_offering' uses 1 products that are not ready in App Store Connect."
        expect(error.localizedDescription) == expected
    }

    func testOfferingConfigurationWithNoPackages() {
        let error = PurchasesDiagnostics.Error.offeringConfiguration(
            [
                .init(
                    identifier: "test_offering",
                    packages: [],
                    status: .failed
                )
            ]
        )

        expect(error.errorUserInfo[NSUnderlyingErrorKey] as? NSNull).toNot(beNil())
        let expected = "Offering 'test_offering' has no packages"
        expect(error.localizedDescription) == expected
    }

    func testGenericOfferingConfigurationError() {
        let error = PurchasesDiagnostics.Error.offeringConfiguration([])

        expect(error.errorUserInfo[NSUnderlyingErrorKey] as? NSNull).toNot(beNil())
        let expected = "Default offering is not configured correctly"
        expect(error.localizedDescription) == expected
    }
}
