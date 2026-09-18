//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BaseStoreKitIntegrationTests+Verification.swift
//
//  Created by Nacho Soto on 9/14/23.

import Foundation
import Nimble
import StoreKit
import XCTest

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@testable import RevenueCat_CustomEntitlementComputation
#else
@testable import RevenueCat
#endif

extension BaseStoreKitIntegrationTests {

    // Match StoreKit's current identifier, not the SDK's captured fallback UUID (see PR #7739).
    func storeKitIdentifier(for transaction: StoreTransaction) -> String? {
        if Self.storeKitVersion == .storeKit1 {
            return transaction.sk1Transaction?.transactionIdentifier
        } else {
            return transaction.transactionIdentifier
        }
    }

    func verifyTransactionIsEventuallyRemovedFromSK1Queue(
        _ transaction: StoreTransaction,
        file: FileString = #filePath,
        line: UInt = #line
    ) async {
        await expect(file: file, line: line) {
            guard let identifier = self.storeKitIdentifier(for: transaction) else { return false }
            return !SKPaymentQueue.default().transactions.contains {
                $0.transactionIdentifier == identifier &&
                    $0.payment.productIdentifier == transaction.productIdentifier
            }
        }.toEventually(beTrue(), timeout: .seconds(5))
    }

    @discardableResult
    func verifyEntitlementWentThrough(
        _ customerInfo: CustomerInfo,
        file: FileString = #filePath,
        filename: StaticString = #file,
        line: UInt = #line
    ) async throws -> EntitlementInfo {
        // Record the test failure, then stop this async helper by throwing a Swift error.
        // Temporarily allow execution past `fail()` so we reach the explicit throw,
        // and restore the original setting when leaving this scope.
        func failTest(_ message: String) async throws {
            struct ExpectationFailure: Swift.Error {}

            await self.printReceiptContent()

            let previousContinueAfterFailure = self.continueAfterFailure
            self.continueAfterFailure = true
            defer { self.continueAfterFailure = previousContinueAfterFailure }
            fail(message, file: file, line: line)
            throw ExpectationFailure()
        }

        let entitlements = customerInfo.entitlements.all
        if entitlements.count != 1 {
            try await failTest("\(Date()): Expected 1 Entitlement. Got: \(entitlements)")
        }

        let entitlement: EntitlementInfo

        do {
            entitlement = try XCTUnwrap(
                entitlements[Self.entitlementIdentifier],
                file: filename, line: line
            )
        } catch {
            await self.printReceiptContent()
            throw error
        }

        if !entitlement.isActive {
            try await failTest("\(Date()): Entitlement is not active: \(entitlement)")
        }

        return entitlement
    }

    func assertNoActiveSubscription(
        _ customerInfo: CustomerInfo,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file, line: line,
            customerInfo.entitlements.active
        ).to(
            beEmpty(),
            description: "\(Date()): Expected no active entitlements"
        )
    }

    func assertNoPurchases(
        _ customerInfo: CustomerInfo,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file, line: line,
            customerInfo.entitlements.all
        )
        .to(
            beEmpty(),
            description: "\(Date()): Expected no entitlements. Got: \(customerInfo.entitlements.all)"
        )
    }

    func verifyAnyTransactionWasFinished(
        count: Int? = 1,
        file: FileString = #file,
        line: UInt = #line
    ) {
        self.logger.verifyMessageWasLogged(Self.finishingAnyTransactionLog,
                                           level: .info,
                                           expectedCount: count,
                                           file: file,
                                           line: line)
    }

    func verifySpecificTransactionWasFinished(
        _ storeTransaction: StoreTransaction,
        count: Int? = 1,
        file: FileString = #file,
        line: UInt = #line
    ) {
        self.verifySpecificTransactionWasFinished(transactionId: storeTransaction.transactionIdentifier,
                                                  productId: storeTransaction.productIdentifier,
                                                  count: count,
                                                  file: file,
                                                  line: line)
    }

    func verifySpecificTransactionWasFinished(
        transactionId: String,
        productId: String,
        count: Int? = 1,
        file: FileString = #file,
        line: UInt = #line
    ) {
        let expectedLog = Self.finishingSpecificTransactionLog(transactionId: transactionId, productId: productId)
        self.logger.verifyMessageWasLogged(expectedLog,
                                           level: .info,
                                           expectedCount: count,
                                           file: file,
                                           line: line)
    }

    func verifySpecificTransactionIsEventuallyFinished(
        _ transaction: StoreTransaction,
        count: Int? = 1,
        file: FileString = #file,
        line: UInt = #line
    ) async throws {
        try await asyncWait(description: "StoreKit transaction identifier is not available", timeout: .seconds(5)) {
            await self.storeKitIdentifier(for: transaction) != nil
        }
        let identifier = try XCTUnwrap(self.storeKitIdentifier(for: transaction))
        try await self.verifySpecificTransactionIsEventuallyFinished(
            transactionId: identifier,
            productId: transaction.productIdentifier,
            count: count,
            file: file,
            line: line
        )
    }

    func verifySpecificTransactionIsEventuallyFinished(
        transactionId: String,
        productId: String,
        count: Int? = 1,
        file: FileString = #file,
        line: UInt = #line
    ) async throws {
        let expectedLog = Self.finishingSpecificTransactionLog(transactionId: transactionId, productId: productId)
        try await self.logger.verifyMessageIsEventuallyLogged(
            expectedLog,
            level: .info,
            expectedCount: count,
            timeout: .seconds(5),
            pollInterval: .milliseconds(100),
            file: file,
            line: line
        )
    }

    /// Use this method to check a transaction was finished for a specific product identifier
    /// when you don't have access to the specific `StoreTransaction` object.
    func verifyTransactionWasFinishedForProductIdentifier(
        _ productIdentifier: String,
        count: Int? = 1,
        file: FileString = #file,
        line: UInt = #line
    ) {
        let expectedLogRegexPattern = Self.finishingTransactionLogRegexPattern(productIdentifier: productIdentifier)
        self.logger.verifyMessageWasLogged(regexPattern: expectedLogRegexPattern,
                                           level: .info,
                                           expectedCount: count,
                                           file: file,
                                           line: line)
    }

    func verifyNoTransactionsWereFinished(
        file: FileString = #file,
        line: UInt = #line
    ) {
        self.logger.verifyMessageWasNotLogged(Self.finishingAnyTransactionLog, file: file, line: line)
    }

    func verifySpecificTransactionWasNotFinished(
        _ storeTransaction: StoreTransaction,
        file: FileString = #file,
        line: UInt = #line
    ) {
        let expectedLog = Self.finishingSpecificTransactionLog(transactionId: storeTransaction.transactionIdentifier,
                                                               productId: storeTransaction.productIdentifier)
        self.logger.verifyMessageWasNotLogged(expectedLog, file: file, line: line)
    }

    func verifyAnyTransactionIsEventuallyFinished(
        count: Int? = nil,
        file: FileString = #file,
        line: UInt = #line
    ) async throws {
        try await self.logger.verifyMessageIsEventuallyLogged(
            Self.finishingAnyTransactionLog,
            level: .info,
            expectedCount: count,
            timeout: .seconds(5),
            pollInterval: .milliseconds(100),
            file: file,
            line: line
        )
    }

    func verifyCustomerInfoWasComputedOffline(
        customerInfo: CustomerInfo,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file,
            line: line,
            customerInfo.isComputedOffline
        ).to(beTrue(), description: "Expected customer info to be computed offline")
        expect(
            file: file,
            line: line,
            customerInfo.originalSource
        ).to(equal(.offlineEntitlements), description: "Expected original source to be offline entitlements")
        expect(customerInfo.isLoadedFromCache).to(
            beFalse(),
            description: "Offline-computed customer info is never loaded from cache")
    }

    func verifyCustomerInfoWasNotComputedOffline(
        customerInfo: CustomerInfo,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file,
            line: line,
            customerInfo.isComputedOffline
        ).to(beFalse(), description: "Expected customer info not to be computed offline")
        expect(
            file: file,
            line: line,
            customerInfo.originalSource
        ).toNot(equal(.offlineEntitlements), description: "Expected original source not to be offline entitlements")
    }

    func verifyReceiptIsEventuallyPosted(
        timeout: NimbleTimeInterval = .seconds(3),
        file: FileString = #file,
        line: UInt = #line
    ) async throws {
        try await self.logger.verifyMessageIsEventuallyLogged(
            Strings.network.operation_state(PostReceiptDataOperation.self, state: "Finished").description,
            timeout: timeout,
            pollInterval: .milliseconds(100),
            file: file,
            line: line
        )
    }

    #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    @discardableResult
    func verifySubscriptionExpired() async throws -> CustomerInfo {
        let info = try await self.purchases.syncPurchases()
        self.assertNoActiveSubscription(info)

        return info
    }
    #endif

}
