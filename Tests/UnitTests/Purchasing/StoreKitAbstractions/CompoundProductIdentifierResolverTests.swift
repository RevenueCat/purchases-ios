//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CompoundProductIdentifierResolverTests.swift
//
//  Created by Will Taylor on 5/26/26.
//

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

class CompoundProductIdentifierResolverTests: TestCase {

    func testResolverDropsInvalidIdentifiersAndLogsWarningOnce() throws {
        self.logger.clearMessages()

        let resolvedIdentifiers = CompoundProductIdentifierResolver.resolve(
            [
                "",
                "com.revenuecat.subscription",
                "com.revenuecat.subscription:monthly:extra"
            ],
            supportsBillingPlans: { _ in true }
        )

        expect(resolvedIdentifiers.compoundProductIdentifiers) == Set([
            try XCTUnwrap(CompoundProductIdentifier(
                compoundProductIdentifier: "com.revenuecat.subscription"
            ))
        ])
        expect(resolvedIdentifiers.storeKitProductIdentifiers) == Set(["com.revenuecat.subscription"])

        let invalidIdentifierWarningCount = self.logger.messages.filter { message in
            message.level == .warn
                && message.message.contains("Invalid product identifiers were ignored")
        }.count
        expect(invalidIdentifierWarningCount) == 1
        self.logger.verifyMessageWasLogged(
            regexPattern: "Invalid product identifiers were ignored: .*com\\.revenuecat\\.subscription:monthly:extra",
            level: .warn
        )
        self.logger.verifyMessageWasLogged(
            regexPattern: "Invalid product identifiers were ignored: .*\"\"",
            level: .warn
        )
    }

    func testResolverRetainsBaseIdentifiers() throws {
        let resolvedIdentifiers = CompoundProductIdentifierResolver.resolve(
            [
                "com.revenuecat.monthly",
                "com.revenuecat.annual"
            ],
            supportsBillingPlans: { _ in false }
        )

        expect(resolvedIdentifiers.compoundProductIdentifiers) == Set([
            try XCTUnwrap(CompoundProductIdentifier(compoundProductIdentifier: "com.revenuecat.monthly")),
            try XCTUnwrap(CompoundProductIdentifier(compoundProductIdentifier: "com.revenuecat.annual"))
        ])
        expect(resolvedIdentifiers.storeKitProductIdentifiers) == Set([
            "com.revenuecat.monthly",
            "com.revenuecat.annual"
        ])
    }

    func testResolverRetainsBillingPlanIdentifiersWhenSupported() throws {
        let resolvedIdentifiers = CompoundProductIdentifierResolver.resolve(
            [
                "com.revenuecat.subscription:monthly",
                "com.revenuecat.subscription:upFront"
            ],
            supportsBillingPlans: { _ in true }
        )

        expect(resolvedIdentifiers.compoundProductIdentifiers) == Set([
            try XCTUnwrap(CompoundProductIdentifier(compoundProductIdentifier: "com.revenuecat.subscription:monthly")),
            try XCTUnwrap(CompoundProductIdentifier(compoundProductIdentifier: "com.revenuecat.subscription:upFront"))
        ])
        expect(resolvedIdentifiers.storeKitProductIdentifiers) == Set(["com.revenuecat.subscription"])
    }

    func testResolverDropsBillingPlanIdentifiersWhenUnsupported() {
        let resolvedIdentifiers = CompoundProductIdentifierResolver.resolve(
            [
                "com.revenuecat.subscription:monthly",
                "com.revenuecat.subscription:upFront"
            ],
            supportsBillingPlans: { _ in false }
        )

        expect(resolvedIdentifiers.compoundProductIdentifiers).to(beEmpty())
        expect(resolvedIdentifiers.storeKitProductIdentifiers).to(beEmpty())
    }

    func testResolverDeduplicatesStoreKitProductIdentifiersForSharedBaseProduct() throws {
        let resolvedIdentifiers = CompoundProductIdentifierResolver.resolve(
            [
                "com.revenuecat.subscription",
                "com.revenuecat.subscription:monthly",
                "com.revenuecat.subscription:upFront"
            ],
            supportsBillingPlans: { _ in true }
        )

        expect(resolvedIdentifiers.compoundProductIdentifiers) == Set([
            try XCTUnwrap(CompoundProductIdentifier(compoundProductIdentifier: "com.revenuecat.subscription")),
            try XCTUnwrap(CompoundProductIdentifier(compoundProductIdentifier: "com.revenuecat.subscription:monthly")),
            try XCTUnwrap(CompoundProductIdentifier(compoundProductIdentifier: "com.revenuecat.subscription:upFront"))
        ])
        expect(resolvedIdentifiers.storeKitProductIdentifiers) == Set(["com.revenuecat.subscription"])
    }

    func testResolverResolvesMixedInput() throws {
        let resolvedIdentifiers = CompoundProductIdentifierResolver.resolve(
            [
                "",
                "com.revenuecat.base",
                "com.revenuecat.subscription:monthly",
                "com.revenuecat.other_subscription:upFront",
                "com.revenuecat.invalid:monthly:extra"
            ],
            supportsBillingPlans: { compoundIdentifier in
                compoundIdentifier.productPlanIdentifier == "monthly"
            }
        )

        expect(resolvedIdentifiers.compoundProductIdentifiers) == Set([
            try XCTUnwrap(CompoundProductIdentifier(compoundProductIdentifier: "com.revenuecat.base")),
            try XCTUnwrap(CompoundProductIdentifier(compoundProductIdentifier: "com.revenuecat.subscription:monthly"))
        ])
        expect(resolvedIdentifiers.storeKitProductIdentifiers) == Set([
            "com.revenuecat.base",
            "com.revenuecat.subscription"
        ])
    }

}
