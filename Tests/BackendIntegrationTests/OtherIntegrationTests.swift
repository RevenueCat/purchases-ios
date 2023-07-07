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

    func testGetCustomerInfo() async throws {
        let info = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
        expect(info.entitlements.all).to(beEmpty())
        expect(info.isComputedOffline) == false
    }

    func testGetCustomerInfoReturnsNotModified() async throws {
        // 1. Fetch user once
        _ = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)

        let logger = TestLogHandler()

        // 2. Re-fetch user
        _ = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)

        let expectedRequest = HTTPRequest(method: .get,
                                          path: .getCustomerInfo(appUserID: Purchases.shared.appUserID))

        // 3. Verify response was 304
        logger.verifyMessageWasLogged(
            Strings.network.api_request_completed(expectedRequest, httpCode: .notModified)
        )
    }

    func testGetCustomerInfoAfterLogInReturnsNotModified() async throws {
        // 1. Log-in to force a new user
        _ = try await Purchases.shared.logIn(UUID().uuidString)

        // 2. Fetch user once
        _ = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)

        let logger = TestLogHandler()

        // 3. Re-fetch user
        _ = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)

        let expectedRequest = HTTPRequest(method: .get,
                                          path: .getCustomerInfo(appUserID: Purchases.shared.appUserID))

        // 4. Verify response was 304
        logger.verifyMessageWasLogged(
            Strings.network.api_request_completed(expectedRequest, httpCode: .notModified)
        )
    }

    func testHealthRequest() async throws {
        try await Purchases.shared.healthRequest(signatureVerification: false)
    }

    func testHealthRequestWithVerification() async throws {
        try await Purchases.shared.healthRequest(signatureVerification: true)
    }

    func testHandledByProductionServer() async throws {
        let logger = TestLogHandler()

        try await Purchases.shared.healthRequest(signatureVerification: false)

        logger.verifyMessageWasNotLogged(Strings.network.request_handled_by_load_shedder(.health))
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
