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

    override func setUp() async throws {
        // Some tests need to introspect logs during initialization.
        super.initializeLogger()

        try await super.setUp()
    }

    func testGetCustomerInfo() async throws {
        let info = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        expect(info.entitlements.all).to(beEmpty())
        expect(info.isComputedOffline) == false
    }

    func testGetCustomerInfoMultipleTimesInParallel() async throws {
        let requestCount = 3

        let purchases = try self.purchases

        // 1. Make sure any existing customer info requests finish
        _ = try await purchases.customerInfo()
        // 2. Invalidate cache
        purchases.invalidateCustomerInfoCache()
        self.logger.clearMessages()

        // 3. Request customer info multiple times in parallel
        await withThrowingTaskGroup(of: Void.self) {
            for _ in 0..<requestCount {
                $0.addTask { _ = try await purchases.customerInfo() }
            }
        }

        // 4. Verify N-1 requests were de-duped
        self.logger.verifyMessageWasLogged(
            "Network operation 'GetCustomerInfoOperation' found with the same cache key",
            level: .debug,
            expectedCount: requestCount - 1
        )
        self.logger.verifyMessageWasLogged(
            Strings.network.api_request_completed(
                .init(method: .get,
                      path: .getCustomerInfo(appUserID: try self.purchases.appUserID)),
                httpCode: .notModified
            ),
            level: .debug,
            expectedCount: 1
        )
    }

    func testGetCustomerInfoCaching() async throws {
        _ = try await self.purchases.customerInfo()

        self.logger.clearMessages()

        _ = try await self.purchases.customerInfo()

        self.logger.verifyMessageWasLogged(Strings.customerInfo.vending_cache, level: .debug)
        self.logger.verifyMessageWasNotLogged("API request started")
    }

    func testGetOfferingsMultipleTimesInParallel() async throws {
        let requestCount = 3

        let purchases = try self.purchases

        // 1. Invalidate cache
        purchases.invalidateOfferingsCache()
        self.logger.clearMessages()

        // 2. Request offerings multiple times in parallel
        await withThrowingTaskGroup(of: Void.self) {
            for _ in 0..<requestCount {
                $0.addTask { _ = try await purchases.offerings() }
            }
        }

        // 3. Verify N-1 requests were de-duped
        self.logger.verifyMessageWasLogged(
            "Network operation 'GetOfferingsOperation' found with the same cache key",
            level: .debug,
            expectedCount: requestCount - 1
        )
        self.logger.verifyMessageWasLogged(
            Strings.network.api_request_completed(
                .init(method: .get,
                      path: .getOfferings(appUserID: try self.purchases.appUserID)),
                httpCode: .notModified
            ),
            level: .debug,
            expectedCount: 1
        )
    }

    func testGetCustomerInfoReturnsNotModified() async throws {
        // 1. Fetch user once
        _ = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)

        // 2. Re-fetch user
        _ = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)

        let expectedRequest = HTTPRequest(method: .get,
                                          path: .getCustomerInfo(appUserID: try self.purchases.appUserID))

        // 3. Verify response was 304
        self.logger.verifyMessageWasLogged(
            Strings.network.api_request_completed(expectedRequest, httpCode: .notModified)
        )
    }

    func testGetCustomerInfoAfterLogInReturnsNotModified() async throws {
        // 1. Log-in to force a new user
        _ = try await self.purchases.logIn(UUID().uuidString)

        // 2. Fetch user once
        _ = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)

        // 3. Re-fetch user
        _ = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)

        let expectedRequest = HTTPRequest(method: .get,
                                          path: .getCustomerInfo(appUserID: try self.purchases.appUserID))

        // 4. Verify response was 304
        self.logger.verifyMessageWasLogged(
            Strings.network.api_request_completed(expectedRequest, httpCode: .notModified)
        )
    }

    func testOfferingsAreOnlyFetchedOnceOnSDKInitialization() async throws {
        self.logger.verifyMessageWasLogged(Strings.offering.offerings_stale_updating_in_foreground,
                                           level: .debug,
                                           expectedCount: 1)
        self.logger.verifyMessageWasLogged("GetOfferingsOperation: Started",
                                           level: .debug,
                                           expectedCount: 1)
    }

    func testHealthRequest() async throws {
        try await self.purchases.healthRequest(signatureVerification: false)
    }

    func testHealthRequestWithVerification() async throws {
        try await self.purchases.healthRequest(signatureVerification: true)
    }

    func testHandledByProductionServer() async throws {
        try await self.purchases.healthRequest(signatureVerification: false)

        self.logger.verifyMessageWasNotLogged(Strings.network.request_handled_by_load_shedder(HTTPRequest.Path.health))
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testProductEntitlementMapping() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let result = try await self.purchases.productEntitlementMapping().entitlementsByProduct
        expect(result).to(haveCount(17))
        expect(result["com.revenuecat.monthly_4.99.1_week_intro"]) == ["premium"]
        expect(result["lifetime"]) == ["premium"]
        expect(result["com.revenuecat.intro_test.monthly.1_week_intro"]).to(beEmpty())
        expect(result["consumable.10_coins"]).to(beEmpty())
    }

    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    func testEnableAdServicesAttributionTokenCollection() async throws {
        try self.purchases.attribution.enableAdServicesAttributionTokenCollection()

        try await self.logger.verifyMessageIsEventuallyLogged(
            Strings.attribution.adservices_token_post_succeeded.description,
            level: .debug,
            timeout: .seconds(3),
            pollInterval: .milliseconds(200)
        )
    }

}
