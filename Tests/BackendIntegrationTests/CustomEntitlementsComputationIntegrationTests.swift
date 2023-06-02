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

    private var logger: TestLogHandler!

    override func setUp() async throws {
        self.logger = .init()

        self.addTeardownBlock { [logger = self.logger!] in
            // No `GetCustomerInfoOperation` requests should be made
            logger.verifyMessageWasNotLogged("GetCustomerInfoOperation")
        }

        try await super.setUp()
    }

    override func tearDown() {
        self.logger = nil

        super.tearDown()
    }

    override func configurePurchases() {
        Purchases.configureInCustomEntitlementsComputationMode(apiKey: self.apiKey, appUserID: Self.userID)
    }

    private static let userID = UUID().uuidString

    // MARK: - Tests

    func testPurchasesDiagnostics() async throws {
        let diagnostics = PurchasesDiagnostics(purchases: Purchases.shared)

        try await diagnostics.testSDKHealth()
    }

    func testCanGetOfferings() async throws {
        let receivedOfferings = try await Purchases.shared.offerings()
        expect(receivedOfferings.all).toNot(beEmpty())
    }

    func testCanSwitchUser() async throws {
        let newUser = UUID().uuidString

        Purchases.shared.switchUser(to: newUser)

        let info = try await self.purchaseMonthlyOffering().customerInfo
        expect(info.originalAppUserId) == newUser
    }

    func testCanPurchasePackage() async throws {
        try await self.purchaseMonthlyOffering()
    }

    @available(iOS 14.3, *)
    func testPurchasingPostsAdAttributionToken() async throws {
        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()

        let logger = TestLogHandler()

        let info = try await self.purchaseMonthlyOffering().customerInfo

        logger.verifyMessageWasLogged(
            Strings.attribution.adservices_marking_as_synced(appUserID: info.originalAppUserId),
            level: .info
        )
    }

}
