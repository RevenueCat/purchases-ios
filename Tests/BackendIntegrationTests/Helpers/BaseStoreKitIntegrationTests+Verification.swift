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
        file: FileString = #file,
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
            try await failTest("Expected 1 Entitlement. Got: \(entitlements)")
        }

        let entitlement: EntitlementInfo

        do {
            entitlement = try XCTUnwrap(
                entitlements[Self.entitlementIdentifier],
                file: file, line: line
            )
        } catch {
            await self.printReceiptContent()
            throw error
        }

        if !entitlement.isActive {
            try await failTest("Entitlement is not active: \(entitlement)")
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
            description: "Expected no active entitlements"
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
            description: "Expected no entitlements. Got: \(customerInfo.entitlements.all)"
        )
    }

    func verifyTransactionWasFinished(
        count: Int = 1,
        file: FileString = #file,
        line: UInt = #line
    ) {
        self.logger.verifyMessageWasLogged(Self.finishingTransactionLog,
                                           level: .info,
                                           expectedCount: count,
                                           file: file,
                                           line: line)
    }

    func verifyNoTransactionsWereFinished(
        file: FileString = #file,
        line: UInt = #line
    ) {
        self.logger.verifyMessageWasNotLogged(Self.finishingTransactionLog, file: file, line: line)
    }

    func verifyTransactionIsEventuallyFinished(
        count: Int? = nil,
        file: FileString = #file,
        line: UInt = #line
    ) async throws {
        try await self.logger.verifyMessageIsEventuallyLogged(
            Self.finishingTransactionLog,
            level: .info,
            expectedCount: count,
            timeout: .seconds(5),
            pollInterval: .milliseconds(100),
            file: file,
            line: line
        )
    }

    func verifyCustomerInfoWasComputedOffline(
        logger: TestLogHandler? = nil,
        file: FileString = #file,
        line: UInt = #line
    ) {
        let logger: TestLogHandler = logger ?? self.logger
        logger.verifyMessageWasLogged(
            Strings.offlineEntitlements.computing_offline_customer_info,
            level: .info,
            file: file,
            line: line
        )
    }

    func verifyCustomerInfoWasNotComputedOffline(
        logger: TestLogHandler? = nil,
        file: FileString = #file,
        line: UInt = #line
    ) {
        let logger: TestLogHandler = logger ?? self.logger

        logger.verifyMessageWasNotLogged(
            Strings.offlineEntitlements.computing_offline_customer_info,
            file: file,
            line: line
        )
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

}
