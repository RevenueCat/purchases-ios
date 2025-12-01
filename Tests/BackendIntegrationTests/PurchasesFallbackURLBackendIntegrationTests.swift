//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesFallbackURLBackendIntegrationTests.swift
//
//  Created by Antonio Pallares on 24/10/25.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

// swiftlint:disable:next type_name
class PurchasesFallbackURLBackendStoreKit1IntegrationTests: PurchasesFallbackURLBackendStoreKit2IntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

}

// swiftlint:disable:next type_name
class PurchasesFallbackURLBackendStoreKit2IntegrationTests: BaseStoreKitIntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return Signing.enforcedVerificationMode()
    }

    override func setUp() async throws {
        self.mainServerDown()

        try await super.setUp() // Initially for these tests, the main server is down
    }

    func testWhenOnlyFallbackURLThenCustomerInfoIsComputedOffline() async throws {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            verifyCustomerInfoWasComputedOffline(customerInfo: customerInfo)
        } catch let error {
            fail("Unexpected error: \(error)")
        }
    }

    func testCanMakePurchasesFromFallbackURLUsingOfflineEntitlements() async throws {
        let purchaseData = try await purchaseMonthlyProduct(allowOfflineEntitlements: true)
        verifyCustomerInfoWasComputedOffline(customerInfo: purchaseData.customerInfo)

        let transaction = try XCTUnwrap(purchaseData.transaction)
        verifySpecificTransactionWasNotFinished(storeTransaction: transaction)
    }

    func testPostsPurchasePerformedOnFallbackURLWhenRecoveringToMainServer() async throws {
        let purchaseData = try await purchaseMonthlyProduct(allowOfflineEntitlements: true)
        verifyCustomerInfoWasComputedOffline(customerInfo: purchaseData.customerInfo)

        let transaction = try XCTUnwrap(purchaseData.transaction)
        verifySpecificTransactionWasNotFinished(storeTransaction: transaction)

        let offlineCustomerInfo = try await self.purchases.customerInfo()

        XCTAssertTrue(offlineCustomerInfo.isComputedOffline)
        let offlineEntitlementInfo = try XCTUnwrap(offlineCustomerInfo.entitlements[Self.entitlementIdentifier])
        XCTAssertTrue(offlineEntitlementInfo.isActive)
        verifySpecificTransactionWasNotFinished(storeTransaction: transaction)

        self.allServersUp() // Simulate main server recovery
        logger.clearMessages()

        let onlineCustomerInfo = try await self.purchases.customerInfo()

        verifyCustomerInfoWasNotComputedOffline(customerInfo: onlineCustomerInfo)
        verifySpecificTransactionWasFinished(storeTransaction: transaction)

        XCTAssertFalse(onlineCustomerInfo.isComputedOffline)
        let onlineEntitlementInfo = try XCTUnwrap(onlineCustomerInfo.entitlements[Self.entitlementIdentifier])
        XCTAssertTrue(onlineEntitlementInfo.isActive)
    }

    func testPostsPurchasePerformedOnFallbackURLWhenRecoveringAfterRestartToMainServer() async throws {
        let purchaseData = try await purchaseMonthlyProduct(allowOfflineEntitlements: true)
        verifyCustomerInfoWasComputedOffline(customerInfo: purchaseData.customerInfo)
        verifyNoTransactionsWereFinished()

        let offlineCustomerInfo = try await self.purchases.customerInfo()

        XCTAssertTrue(offlineCustomerInfo.isComputedOffline)
        let offlineEntitlementInfo = try XCTUnwrap(offlineCustomerInfo.entitlements[Self.entitlementIdentifier])
        XCTAssertTrue(offlineEntitlementInfo.isActive)
        verifyNoTransactionsWereFinished()

        self.allServersUp() // Simulate main server recovery
        logger.clearMessages()

        await resetSingleton()

        let onlineCustomerInfo = try await self.purchases.customerInfo()

        verifyAnyTransactionWasFinished(count: nil)

        verifyCustomerInfoWasNotComputedOffline(customerInfo: onlineCustomerInfo)

        let onlineEntitlementInfo = try XCTUnwrap(onlineCustomerInfo.entitlements[Self.entitlementIdentifier])
        XCTAssertTrue(onlineEntitlementInfo.isActive)
    }

}
