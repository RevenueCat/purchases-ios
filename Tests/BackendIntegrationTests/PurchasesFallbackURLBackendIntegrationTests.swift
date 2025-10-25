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

    func testCanMakePurchasesFromFallbackURLUsingOfflineEntitlements() async throws {
        try await purchaseMonthlyProduct(allowOfflineEntitlements: true)
        verifyCustomerInfoWasComputedOffline()
    }

    func testPostsPurchasePerformedOnFallbackURLWhenRecoveringToMainServer() async throws {
        try await purchaseMonthlyProduct(allowOfflineEntitlements: true)
        verifyCustomerInfoWasComputedOffline()
        verifyNoTransactionsWereFinished()

        let offlineCustomerInfo = try await self.purchases.customerInfo()
        XCTAssertTrue(offlineCustomerInfo.isComputedOffline)

        self.mainServerDown = false // Simulate main server recovery
        logger.clearMessages()

        let onlineCustomerInfo = try await self.purchases.customerInfo()

        verifyCustomerInfoWasNotComputedOffline()
        verifyTransactionWasFinished()

        XCTAssertFalse(onlineCustomerInfo.isComputedOffline)
    }

    func testPostsPurchasePerformedOnFallbackURLWhenRecoveringAfterRestartToMainServer() async throws {
        try await purchaseMonthlyProduct(allowOfflineEntitlements: true)
        verifyCustomerInfoWasComputedOffline()
        verifyNoTransactionsWereFinished()

        let offlineCustomerInfo = try await self.purchases.customerInfo()
        XCTAssertTrue(offlineCustomerInfo.isComputedOffline)

        self.mainServerDown = false // Simulate main server recovery
        logger.clearMessages()

        configurePurchases()

        verifyCustomerInfoWasNotComputedOffline()
        verifyTransactionWasFinished()

        let onlineCustomerInfo = try await self.purchases.customerInfo()
        XCTAssertFalse(onlineCustomerInfo.isComputedOffline)
    }

}
