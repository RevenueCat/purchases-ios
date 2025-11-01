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
class PurchasesFallbackURLBackendIntegrationTests: BaseStoreKitIntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

    private var mainServerDown: Bool = true // Initially for these tests, the main server is down

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return .disabled
    }

    override var forceServerErrorStrategy: ForceServerErrorStrategy? {
        return .init { [weak self] (request: HTTPClient.Request) in
            guard self?.mainServerDown == true else {
                return false // no failures
            }
            return !request.isRequestToFallbackUrl // Only fail for main server requests
        }
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
    }

    func testPostsPurchasePerformedOnFallbackURLWhenRecoveringToMainServer() async throws {
        let purchaseData = try await purchaseMonthlyProduct(allowOfflineEntitlements: true)
        verifyCustomerInfoWasComputedOffline(customerInfo: purchaseData.customerInfo)
        verifyNoTransactionsWereFinished()

        let offlineCustomerInfo = try await self.purchases.customerInfo()

        XCTAssertTrue(offlineCustomerInfo.isComputedOffline)
        let offlineEntitlementInfo = try XCTUnwrap(offlineCustomerInfo.entitlements[Self.entitlementIdentifier])
        XCTAssertTrue(offlineEntitlementInfo.isActive)
        verifyNoTransactionsWereFinished()

        self.mainServerDown = false // Simulate main server recovery
        logger.clearMessages()

        let onlineCustomerInfo = try await self.purchases.customerInfo()

        verifyCustomerInfoWasNotComputedOffline(customerInfo: onlineCustomerInfo)
        verifyTransactionWasFinished()

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

        self.mainServerDown = false // Simulate main server recovery
        logger.clearMessages()

        await resetSingleton()

        let onlineCustomerInfo = try await self.purchases.customerInfo()

        verifyTransactionWasFinished(count: nil)

        verifyCustomerInfoWasNotComputedOffline(customerInfo: onlineCustomerInfo)

        let onlineEntitlementInfo = try XCTUnwrap(onlineCustomerInfo.entitlements[Self.entitlementIdentifier])
        XCTAssertTrue(onlineEntitlementInfo.isActive)
    }

}
