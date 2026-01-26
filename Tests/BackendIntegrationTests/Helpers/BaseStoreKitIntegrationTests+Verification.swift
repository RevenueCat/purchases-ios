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
import XCTest

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@testable import RevenueCat_CustomEntitlementComputation
#else
@testable import RevenueCat
#endif

extension BaseStoreKitIntegrationTests {

    @discardableResult
    func verifyEntitlementWentThrough(
        _ customerInfo: CustomerInfo,
        file: FileString = #filePath,
        filename: StaticString = #file,
        line: UInt = #line
    ) async throws -> EntitlementInfo {
        // This is used to throw an error when the test fails.
        // For some reason XCTest is continuing execution even after a test failure
        // despite having `self.continueAfterFailure = false`
        //
        // By doing this, instead of only calling `fail`, we ensure that
        // Swift stops executing code when an assertion has failed,
        // and therefore avoid code running after the test has already failed.
        // This prevents test crashes from code calling `Purchases.shared` after the test has ended.
        func failTest(_ message: String) async throws {
            struct ExpectationFailure: Swift.Error {}

            await self.printReceiptContent()

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
        file: FileString = #file,
        line: UInt = #line
    ) async throws {
        try await self.logger.verifyMessageIsEventuallyLogged(
            Strings.network.operation_state(PostReceiptDataOperation.self, state: "Finished").description,
            timeout: .seconds(3),
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

    func waitForCachedTransactionMetadataSyncToFinish(
        timeout: NimbleTimeInterval = .seconds(5),
        pollInterval: NimbleTimeInterval = .milliseconds(100),
        file: FileString = #file,
        line: UInt = #line
    ) async throws {
        let expectedEntry = Self.finishedPostingCachedMetadataLog
        try await asyncWait(
            description: "Neither '\(Self.noCachedTransactionMetadataToPostLog)' " +
                         "nor '\(Self.finishedPostingCachedMetadataLog)' was logged. " +
                         "Logged messages: \(self.logger.messages)",
            timeout: timeout,
            pollInterval: pollInterval,
            file: file,
            line: line
        ) {
            self.logger.messages.contains { entry in
                entry.message.contains(expectedEntry)
            }
        }
    }

}
