//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomEntitlementsComputationIntegrationTests.swift
//
//  Created by Nacho Soto on 5/31/23.

import Nimble
@testable import RevenueCat_CustomEntitlementComputation
import StoreKit
import StoreKitTest
import XCTest

// swiftlint:disable type_name

final class CustomEntitlementsComputationIntegrationTests: BaseStoreKitIntegrationTests {

    override func setUp() async throws {
        try await super.setUp()

        self.addTeardownBlock { [logger = self.logger!] in
            // No `GetCustomerInfoOperation` requests should be made
            logger.verifyMessageWasNotLogged("GetCustomerInfoOperation")
        }
    }

    override func configurePurchases() {
        Purchases.configureInCustomEntitlementsComputationMode(apiKey: self.apiKey, appUserID: Self.userID)
    }

    private static let userID = UUID().uuidString

    // MARK: - Tests

    func testPurchasesDiagnostics() async throws {
        let diagnostics = PurchasesDiagnostics(purchases: try self.purchases)

        try await diagnostics.testSDKHealth()
    }

    func testCanGetOfferings() async throws {
        let receivedOfferings = try await self.purchases.offerings()
        expect(receivedOfferings.all).toNot(beEmpty())
    }

    func testCanSwitchUser() async throws {
        let newUser = UUID().uuidString

        try self.purchases.switchUser(to: newUser)

        let info = try await self.purchaseMonthlyOffering().customerInfo
        expect(info.originalAppUserId) == newUser
    }

    func testCanPurchasePackage() async throws {
        try await self.purchaseMonthlyOffering()
    }

    @available(iOS 14.3, *)
    func testPurchasingPostsAdAttributionToken() async throws {
        try self.purchases.attribution.enableAdServicesAttributionTokenCollection()

        let info = try await self.purchaseMonthlyOffering().customerInfo

        self.logger.verifyMessageWasLogged(
            Strings.attribution.adservices_marking_as_synced(appUserID: info.originalAppUserId),
            level: .info
        )
    }

    #if swift(>=5.9)
    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
    func testPurchaseCancellationsAreReportedCorrectly() async throws {
        try AvailabilityChecks.iOS17APIAvailableOrSkipTest()

        try await self.testSession.setSimulatedError(.generic(.userCancelled), forAPI: .purchase)

        do {
            _ = try await self.purchases.purchase(package: self.monthlyPackage)
            fail("Expected error")
        } catch ErrorCode.purchaseCancelledError {
            // Expected error
        } catch {
            throw error
        }
    }
    #endif

}
