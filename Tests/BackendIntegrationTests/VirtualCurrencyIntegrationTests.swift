//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyIntegrationTests.swift
//
//  Created by Will Taylor on 6/29/25.

import Foundation
import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

class VirtualCurrencyStoreKit2IntegrationTests: BaseStoreKitIntegrationTests {
    override class var storeKitVersion: StoreKitVersion { .storeKit2 }
}

class VirtualCurrencyStoreKit1IntegrationTests: BaseStoreKitIntegrationTests {

    override var apiKey: String { return Constants.apiKey }

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

    func testGrantsVCForConsumableWithVCGrant() async throws {
        let userID1 = "vc_user_\(UUID().uuidString)"
        let userID2 = "vc_user_\(UUID().uuidString)"

        _ = try await self.purchases.logIn(userID1)

        try self.purchases.invalidateVirtualCurrenciesCache()
        let virtualCurrenciesBeforePurchase = try await self.purchases.virtualCurrencies()
        assertAllVirtualCurrenciesHaveZeroBalances(virtualCurrenciesBeforePurchase)

        let resultData = try await self.purchaseConsumablePackage()
        let transaction = try XCTUnwrap(resultData.transaction)
        self.verifySpecificTransactionWasFinished(transaction)

        try self.purchases.invalidateVirtualCurrenciesCache()

        let virtualCurrenciesAfterPurchase = try await self.purchases.virtualCurrencies()

        expect(virtualCurrenciesAfterPurchase["TEST"]?.balance).to(equal(1))
        expect(virtualCurrenciesAfterPurchase["TEST"]?.code).to(equal("TEST"))
        expect(virtualCurrenciesAfterPurchase["TEST"]?.name).to(equal("Test Currency"))
        expect(virtualCurrenciesAfterPurchase["TEST"]?.serverDescription).to(equal("This is a test currency"))
        assertVCCodeHasNoBalance(virtualCurrenciesAfterPurchase, vcCode: "TEST2")
        assertVCCodeHasNoBalance(virtualCurrenciesAfterPurchase, vcCode: "TEST3")
        expect(virtualCurrenciesAfterPurchase.all.count).to(equal(3))

        // Ensure that this purchase didn't grant VCs to other subscribers
        _ = try await self.purchases.logIn(userID2)
        let virtualCurrenciesForOtherUser = try await self.purchases.virtualCurrencies()

        assertAllVirtualCurrenciesHaveZeroBalances(virtualCurrenciesForOtherUser)
    }

    func testGrantsVCForNonConsumableWithVCGrant() async throws {
        let userID1 = "vc_user_\(UUID().uuidString)"
        let userID2 = "vc_user_\(UUID().uuidString)"

        _ = try await self.purchases.logIn(userID1)

        try self.purchases.invalidateVirtualCurrenciesCache()
        let virtualCurrenciesBeforePurchase = try await self.purchases.virtualCurrencies()
        assertAllVirtualCurrenciesHaveZeroBalances(virtualCurrenciesBeforePurchase)

        let resultData = try await self.purchaseNonConsumablePackage()
        let transaction = try XCTUnwrap(resultData.transaction)
        self.verifySpecificTransactionWasFinished(transaction)

        try self.purchases.invalidateVirtualCurrenciesCache()

        let virtualCurrenciesAfterPurchase = try await self.purchases.virtualCurrencies()

        expect(virtualCurrenciesAfterPurchase["TEST"]?.balance).to(equal(2))
        expect(virtualCurrenciesAfterPurchase["TEST"]?.code).to(equal("TEST"))
        expect(virtualCurrenciesAfterPurchase["TEST"]?.name).to(equal("Test Currency"))
        expect(virtualCurrenciesAfterPurchase["TEST"]?.serverDescription).to(equal("This is a test currency"))
        assertVCCodeHasNoBalance(virtualCurrenciesAfterPurchase, vcCode: "TEST2")
        assertVCCodeHasNoBalance(virtualCurrenciesAfterPurchase, vcCode: "TEST3")
        expect(virtualCurrenciesAfterPurchase.all.count).to(equal(3))

        // Ensure that this purchase didn't grant VCs to other subscribers
        _ = try await self.purchases.logIn(userID2)
        let virtualCurrenciesForOtherUser = try await self.purchases.virtualCurrencies()
        assertAllVirtualCurrenciesHaveZeroBalances(virtualCurrenciesForOtherUser)
    }

    func testGrantsVCForAutoRenewingSubscriptionWithVCGrant() async throws {
        let userID1 = "vc_user_\(UUID().uuidString)"
        let userID2 = "vc_user_\(UUID().uuidString)"

        _ = try await self.purchases.logIn(userID1)

        try self.purchases.invalidateVirtualCurrenciesCache()
        let virtualCurrenciesBeforePurchase = try await self.purchases.virtualCurrencies()
        assertAllVirtualCurrenciesHaveZeroBalances(virtualCurrenciesBeforePurchase)

        let resultData = try await self.purchaseMonthlyOffering()
        let transaction = try XCTUnwrap(resultData.transaction)
        self.verifySpecificTransactionWasFinished(transaction)

        try self.purchases.invalidateVirtualCurrenciesCache()

        let virtualCurrenciesAfterPurchase = try await self.purchases.virtualCurrencies()

        expect(virtualCurrenciesAfterPurchase["TEST"]?.balance).to(equal(3))
        expect(virtualCurrenciesAfterPurchase["TEST"]?.code).to(equal("TEST"))
        expect(virtualCurrenciesAfterPurchase["TEST"]?.name).to(equal("Test Currency"))
        expect(virtualCurrenciesAfterPurchase["TEST"]?.serverDescription).to(equal("This is a test currency"))
        assertVCCodeHasNoBalance(virtualCurrenciesAfterPurchase, vcCode: "TEST2")
        assertVCCodeHasNoBalance(virtualCurrenciesAfterPurchase, vcCode: "TEST3")
        expect(virtualCurrenciesAfterPurchase.all.count).to(equal(3))

        // Ensure that this purchase didn't grant VCs to other subscribers
        _ = try await self.purchases.logIn(userID2)
        let virtualCurrenciesForOtherUser = try await self.purchases.virtualCurrencies()
        assertAllVirtualCurrenciesHaveZeroBalances(virtualCurrenciesForOtherUser)
    }

    func testGrantsVCForNonRenewingSubscriptionWithVCGrant() async throws {
        let userID1 = "vc_user_\(UUID().uuidString)"
        let userID2 = "vc_user_\(UUID().uuidString)"

        _ = try await self.purchases.logIn(userID1)

        try self.purchases.invalidateVirtualCurrenciesCache()
        let virtualCurrenciesBeforePurchase = try await self.purchases.virtualCurrencies()
        assertAllVirtualCurrenciesHaveZeroBalances(virtualCurrenciesBeforePurchase)

        let purchaseResult = try await self.purchaseNonRenewingSubscriptionPackage()
        let transaction = try XCTUnwrap(purchaseResult.transaction)
        self.verifySpecificTransactionWasFinished(transaction)

        try self.purchases.invalidateVirtualCurrenciesCache()

        let virtualCurrenciesAfterPurchase = try await self.purchases.virtualCurrencies()

        expect(virtualCurrenciesAfterPurchase["TEST"]?.balance).to(equal(4))
        expect(virtualCurrenciesAfterPurchase["TEST"]?.code).to(equal("TEST"))
        expect(virtualCurrenciesAfterPurchase["TEST"]?.name).to(equal("Test Currency"))
        expect(virtualCurrenciesAfterPurchase["TEST"]?.serverDescription).to(equal("This is a test currency"))
        assertVCCodeHasNoBalance(virtualCurrenciesAfterPurchase, vcCode: "TEST2")
        assertVCCodeHasNoBalance(virtualCurrenciesAfterPurchase, vcCode: "TEST3")
        expect(virtualCurrenciesAfterPurchase.all.count).to(equal(3))

        // Ensure that this purchase didn't grant VCs to other subscribers
        _ = try await self.purchases.logIn(userID2)
        let virtualCurrenciesForOtherUser = try await self.purchases.virtualCurrencies()

        assertAllVirtualCurrenciesHaveZeroBalances(virtualCurrenciesForOtherUser)
    }

    func testDoesntGrantVCForProductWithoutVCGrant() async throws {
        let userID1 = "vc_user_\(UUID().uuidString)"
        _ = try await self.purchases.logIn(userID1)

        try self.purchases.invalidateVirtualCurrenciesCache()
        let virtualCurrenciesBeforePurchase = try await self.purchases.virtualCurrencies()
        assertAllVirtualCurrenciesHaveZeroBalances(virtualCurrenciesBeforePurchase)

        let product = try await StoreKit.Product.products(for: [Self.weeklyWith3DayTrial]).first!
        _ = try await self.purchases.purchase(product: StoreProduct(sk2Product: product))

        try self.purchases.invalidateVirtualCurrenciesCache()

        let virtualCurrenciesAfterPurchase = try await self.purchases.virtualCurrencies()
        assertAllVirtualCurrenciesHaveZeroBalances(virtualCurrenciesAfterPurchase)
    }

    // MARK: - Assertion Helpers
    private func assertAllVirtualCurrenciesHaveZeroBalances(_ virtualCurrencies: VirtualCurrencies) {
        for vcCode in virtualCurrencies.all.keys {
            assertVCCodeHasNoBalance(virtualCurrencies, vcCode: vcCode)
        }
    }

    private func assertVCCodeHasNoBalance(
        _ virtualCurrencies: VirtualCurrencies,
        vcCode: String
    ) {
        expect(virtualCurrencies[vcCode]?.balance).to(equal(0))
    }
}
