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
        self.testSession.timeRate = .realTime
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
        verifySpecificTransactionWasNotFinished(transaction)
    }

    func testPostsPurchasePerformedOnFallbackURLWhenRecoveringToMainServer() async throws {
        let purchaseData = try await purchaseMonthlyProduct(allowOfflineEntitlements: true)
        verifyCustomerInfoWasComputedOffline(customerInfo: purchaseData.customerInfo)

        let transaction = try XCTUnwrap(purchaseData.transaction)
        verifySpecificTransactionWasNotFinished(transaction)

        let offlineCustomerInfo = try await self.purchases.customerInfo()

        XCTAssertTrue(offlineCustomerInfo.isComputedOffline)
        let offlineEntitlementInfo = try XCTUnwrap(offlineCustomerInfo.entitlements[Self.entitlementIdentifier])
        XCTAssertTrue(offlineEntitlementInfo.isActive)
        verifySpecificTransactionWasNotFinished(transaction)

        let pendingNativeTransaction: SKPaymentTransaction?
        if Self.storeKitVersion == .storeKit1, !transaction.hasKnownTransactionIdentifier {
            // The captured fallback UUID may differ from the native identifier populated later by StoreKit.
            let nativeTransaction = try XCTUnwrap(transaction.sk1Transaction)
            await expect {
                SKPaymentQueue.default().transactions.contains { $0 === nativeTransaction }
            }.toEventually(beTrue(), timeout: .seconds(5))
            pendingNativeTransaction = nativeTransaction
        } else {
            pendingNativeTransaction = nil
        }

        await self.captureRecoveryDiagnostics(transaction: transaction, stage: "beforeRecovery")
        self.allServersUp() // Simulate main server recovery
        logger.clearMessages()

        let onlineCustomerInfo = try await self.purchases.customerInfo()

        await self.captureRecoveryDiagnostics(transaction: transaction, stage: "afterRecovery")
        verifyCustomerInfoWasNotComputedOffline(customerInfo: onlineCustomerInfo)
        if let nativeTransaction = pendingNativeTransaction {
            await expect {
                SKPaymentQueue.default().transactions.contains { $0 === nativeTransaction }
            }.toEventually(beFalse(), timeout: .seconds(5))
        } else {
            try await self.verifySpecificTransactionIsEventuallyFinished(
                transactionId: transaction.transactionIdentifier,
                productId: transaction.productIdentifier
            )
        }

        XCTAssertFalse(onlineCustomerInfo.isComputedOffline)
        let onlineEntitlementInfo = try XCTUnwrap(onlineCustomerInfo.entitlements[Self.entitlementIdentifier])
        XCTAssertTrue(onlineEntitlementInfo.isActive)
    }

    private func captureRecoveryDiagnostics(transaction: StoreTransaction, stage: String) async {
        var verifiedCount = 0
        var unverifiedCount = 0
        var verifiedExpectedMatch = false
        var unverifiedExpectedMatch = false
        var verifiedProductMatch = false
        for await result in StoreKit.Transaction.unfinished {
            switch result {
            case let .verified(pending):
                verifiedCount += 1
                verifiedExpectedMatch = verifiedExpectedMatch || String(pending.id) == transaction.transactionIdentifier
                verifiedProductMatch = verifiedProductMatch || pending.productID == transaction.productIdentifier
            case let .unverified(pending, _):
                unverifiedCount += 1
                unverifiedExpectedMatch = unverifiedExpectedMatch ||
                    String(pending.id) == transaction.transactionIdentifier
            }
        }

        let nativeTransaction = transaction.sk1Transaction
        let queue = SKPaymentQueue.default().transactions
        let queueExpectedMatchCount = queue.filter {
            $0.transactionIdentifier == transaction.transactionIdentifier &&
                $0.payment.productIdentifier == transaction.productIdentifier
        }.count
        let queueNativeObjectMatchCount = queue.filter { $0 === nativeTransaction }.count
        let nativeIdentifierMatchesExpected = nativeTransaction?.transactionIdentifier ==
            transaction.transactionIdentifier
        print("RC_CI_FALLBACK stage=\(stage) sk1=\(Self.storeKitVersion == .storeKit1) " +
              "knownIdentifier=\(transaction.hasKnownTransactionIdentifier) " +
              "verifiedCount=\(verifiedCount) unverifiedCount=\(unverifiedCount) " +
              "verifiedExpectedMatch=\(verifiedExpectedMatch) unverifiedExpectedMatch=\(unverifiedExpectedMatch) " +
              "verifiedProductMatch=\(verifiedProductMatch) queueExpectedMatchCount=\(queueExpectedMatchCount) " +
              "queueNativeObjectMatchCount=\(queueNativeObjectMatchCount) " +
              "nativeIdentifierMatchesExpected=\(nativeIdentifierMatchesExpected)")
    }

    func testPostsPurchasePerformedOnFallbackURLWhenRecoveringAfterRestartToMainServer() async throws {
        let purchaseData = try await purchaseMonthlyProduct(allowOfflineEntitlements: true)
        verifyCustomerInfoWasComputedOffline(customerInfo: purchaseData.customerInfo)
        let transaction = try XCTUnwrap(purchaseData.transaction)
        verifySpecificTransactionWasNotFinished(transaction)

        let offlineCustomerInfo = try await self.purchases.customerInfo()

        XCTAssertTrue(offlineCustomerInfo.isComputedOffline)
        let offlineEntitlementInfo = try XCTUnwrap(offlineCustomerInfo.entitlements[Self.entitlementIdentifier])
        XCTAssertTrue(offlineEntitlementInfo.isActive)
        verifySpecificTransactionWasNotFinished(transaction)

        self.allServersUp() // Simulate main server recovery
        logger.clearMessages()

        await resetSingleton()

        let onlineCustomerInfo = try await self.purchases.customerInfo()

        try await self.verifySpecificTransactionIsEventuallyFinished(
            transactionId: transaction.transactionIdentifier,
            productId: transaction.productIdentifier,
            count: nil
        )

        verifyCustomerInfoWasNotComputedOffline(customerInfo: onlineCustomerInfo)

        let onlineEntitlementInfo = try XCTUnwrap(onlineCustomerInfo.entitlements[Self.entitlementIdentifier])
        XCTAssertTrue(onlineEntitlementInfo.isActive)
    }

}
