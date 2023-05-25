//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OtherIntegrationTests.swift
//
//  Created by Nacho Soto on 10/10/22.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

class OtherIntegrationTests: BaseBackendIntegrationTests {

    func testHealthRequest() async throws {
        try await Purchases.shared.healthRequest(signatureVerification: false)
    }

    func testHealthRequestWithVerification() async throws {
        try await Purchases.shared.healthRequest(signatureVerification: true)
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testProductEntitlementMapping() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let result = try await Purchases.shared.productEntitlementMapping()
        expect(result.entitlementsByProduct).to(haveCount(14))
        expect(result.entitlementsByProduct["com.revenuecat.monthly_4.99.1_week_intro"]) == ["premium"]
        expect(result.entitlementsByProduct["com.revenuecat.intro_test.monthly.1_week_intro"]).to(beEmpty())
    }

    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    func testEnableAdServicesAttributionTokenCollection() async throws {
        let logger = TestLogHandler()

        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()

        try await logger.verifyMessageIsEventuallyLogged(
            Strings.attribution.adservices_token_post_succeeded.description,
            level: .debug,
            timeout: .seconds(3),
            pollInterval: .milliseconds(200)
        )
    }

}
