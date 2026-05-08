//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CompoundProductIdentifierTests.swift
//
//  Created by Will Taylor on 5/8/26.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

class CompoundProductIdentifierTests: TestCase {

    func testInit() {
        let productId = "com.revenuecat.subscription"
        let productPlanIdentifier = "monthly"

        let compoundIdentifier = CompoundProductIdentifier(
            productIdentifier: productId,
            productPlanIdentifier: productPlanIdentifier
        )

        expect(compoundIdentifier.productIdentifier) == productId
        expect(compoundIdentifier.productPlanIdentifier) == productPlanIdentifier
    }

    func testStoreKitProductIdentifierReturnsProductIdentifierWithoutProductPlanIdentifier() {
        let identifier = CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: nil
        )

        expect(identifier.storeKitProductIdentifier) == "com.revenuecat.subscription"
    }

    func testStoreKitProductIdentifierReturnsProductIdentifierWithProductPlanIdentifier() {
        let identifier = CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "monthly"
        )

        expect(identifier.storeKitProductIdentifier) == "com.revenuecat.subscription"
    }

    func testCompoundProductIdentifierReturnsProductIdentifierWithoutProductPlanIdentifier() {
        let identifier = CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: nil
        )

        expect(identifier.compoundProductIdentifier) == "com.revenuecat.subscription"
    }

    func testCompoundProductIdentifierCombinesProductIdentifierAndProductPlanIdentifier() {
        let identifier = CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "monthly"
        )

        expect(identifier.compoundProductIdentifier) == "com.revenuecat.subscription:monthly"
    }

    func testCompoundProductIdentifierPreservesProductPlanIdentifierCasing() {
        let identifier = CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "upFront"
        )

        expect(identifier.compoundProductIdentifier) == "com.revenuecat.subscription:upFront"
    }

    func testCompoundProductIdentifierCombinesEmptyProductPlanIdentifier() {
        let identifier = CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: ""
        )

        expect(identifier.compoundProductIdentifier) == "com.revenuecat.subscription:"
    }

    func testEquatableUsesProductIdentifierAndProductPlanIdentifier() {
        let monthlyIdentifier = CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "monthly"
        )
        let sameMonthlyIdentifier = CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "monthly"
        )
        let upFrontIdentifier = CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "upFront"
        )
        let productOnlyIdentifier = CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: nil
        )
        let differentProductIdentifier = CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.other_subscription",
            productPlanIdentifier: "monthly"
        )

        expect(monthlyIdentifier) == sameMonthlyIdentifier
        expect(monthlyIdentifier) != upFrontIdentifier
        expect(monthlyIdentifier) != productOnlyIdentifier
        expect(monthlyIdentifier) != differentProductIdentifier
    }

    func testHashableKeepsDistinctProductPlanIdentifiers() {
        let identifiers: Set<CompoundProductIdentifier> = [
            .init(productIdentifier: "com.revenuecat.subscription", productPlanIdentifier: "monthly"),
            .init(productIdentifier: "com.revenuecat.subscription", productPlanIdentifier: "monthly"),
            .init(productIdentifier: "com.revenuecat.subscription", productPlanIdentifier: "upFront"),
            .init(productIdentifier: "com.revenuecat.subscription", productPlanIdentifier: nil),
            .init(productIdentifier: "com.revenuecat.other_subscription", productPlanIdentifier: "monthly")
        ]

        expect(identifiers).to(haveCount(4))
        expect(identifiers).to(contain(
            .init(productIdentifier: "com.revenuecat.subscription", productPlanIdentifier: "monthly")
        ))
        expect(identifiers).to(contain(
            .init(productIdentifier: "com.revenuecat.subscription", productPlanIdentifier: "upFront")
        ))
        expect(identifiers).to(contain(
            .init(productIdentifier: "com.revenuecat.subscription", productPlanIdentifier: nil)
        ))
        expect(identifiers).to(contain(
            .init(productIdentifier: "com.revenuecat.other_subscription", productPlanIdentifier: "monthly")
        ))
    }

}
