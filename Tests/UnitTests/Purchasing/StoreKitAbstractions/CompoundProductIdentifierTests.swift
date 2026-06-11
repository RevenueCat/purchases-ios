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
import StoreKit
import XCTest

class CompoundProductIdentifierTests: TestCase {

    func testStoreKitProductIdentifierReturnsProductIdentifierWithoutProductPlanIdentifier() throws {
        let identifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: nil
        ))

        expect(identifier.storeKitProductIdentifier) == "com.revenuecat.subscription"
    }

    func testStoreKitProductIdentifierReturnsProductIdentifierWithProductPlanIdentifier() throws {
        let identifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "monthly"
        ))

        expect(identifier.storeKitProductIdentifier) == "com.revenuecat.subscription"
    }

    func testCompoundProductIdentifierReturnsProductIdentifierWithoutProductPlanIdentifier() throws {
        let identifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: nil
        ))

        expect(identifier.compoundProductIdentifier) == "com.revenuecat.subscription"
    }

    func testCompoundProductIdentifierCombinesProductIdentifierAndProductPlanIdentifier() throws {
        let identifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "monthly"
        ))

        expect(identifier.compoundProductIdentifier) == "com.revenuecat.subscription:monthly"
    }

    func testCompoundProductIdentifierPreservesProductPlanIdentifierCasing() throws {
        let identifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "upFront"
        ))

        expect(identifier.compoundProductIdentifier) == "com.revenuecat.subscription:upFront"
    }

    func testCompoundProductIdentifierIgnoresEmptyProductPlanIdentifier() throws {
        let identifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: ""
        ))

        expect(identifier.productPlanIdentifier).to(beNil())
        expect(identifier.compoundProductIdentifier) == "com.revenuecat.subscription"
    }

    func testEquatableUsesProductIdentifierAndProductPlanIdentifier() throws {
        let monthlyIdentifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "monthly"
        ))
        let sameMonthlyIdentifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "monthly"
        ))
        let upFrontIdentifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "upFront"
        ))
        let productOnlyIdentifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: nil
        ))
        let differentProductIdentifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.other_subscription",
            productPlanIdentifier: "monthly"
        ))

        expect(monthlyIdentifier) == sameMonthlyIdentifier
        expect(monthlyIdentifier) != upFrontIdentifier
        expect(monthlyIdentifier) != productOnlyIdentifier
        expect(monthlyIdentifier) != differentProductIdentifier
    }

    func testHashableKeepsDistinctProductPlanIdentifiers() throws {
        let identifiers: Set<CompoundProductIdentifier> = [
            try XCTUnwrap(.init(productIdentifier: "com.revenuecat.subscription", productPlanIdentifier: "monthly")),
            try XCTUnwrap(.init(productIdentifier: "com.revenuecat.subscription", productPlanIdentifier: "monthly")),
            try XCTUnwrap(.init(productIdentifier: "com.revenuecat.subscription", productPlanIdentifier: "upFront")),
            try XCTUnwrap(.init(productIdentifier: "com.revenuecat.subscription", productPlanIdentifier: nil)),
            try XCTUnwrap(.init(
                productIdentifier: "com.revenuecat.other_subscription",
                productPlanIdentifier: "monthly"
            ))
        ]

        expect(identifiers).to(haveCount(4))
        expect(identifiers).to(contain(
            try XCTUnwrap(.init(productIdentifier: "com.revenuecat.subscription", productPlanIdentifier: "monthly"))
        ))
        expect(identifiers).to(contain(
            try XCTUnwrap(.init(productIdentifier: "com.revenuecat.subscription", productPlanIdentifier: "upFront"))
        ))
        expect(identifiers).to(contain(
            try XCTUnwrap(.init(productIdentifier: "com.revenuecat.subscription", productPlanIdentifier: nil))
        ))
        expect(identifiers).to(contain(
            try XCTUnwrap(.init(
                productIdentifier: "com.revenuecat.other_subscription",
                productPlanIdentifier: "monthly"
            ))
        ))
    }

}

// MARK: - Primary Initializer
extension CompoundProductIdentifierTests {

    func testInitWithProductIdentifierAndProductPlanIdentifier() throws {
        let productIdentifier = "com.revenuecat.subscription"
        let productPlanIdentifier = "monthly"

        let compoundIdentifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: productIdentifier,
            productPlanIdentifier: productPlanIdentifier
        ))

        expect(compoundIdentifier.productIdentifier) == productIdentifier
        expect(compoundIdentifier.productPlanIdentifier) == productPlanIdentifier
    }

    func testInitWithProductIdentifierAndNilProductPlanIdentifier() throws {
        let productIdentifier = "com.revenuecat.subscription"

        let compoundIdentifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: productIdentifier,
            productPlanIdentifier: nil
        ))

        expect(compoundIdentifier.productIdentifier) == productIdentifier
        expect(compoundIdentifier.productPlanIdentifier).to(beNil())
    }

    func testInitWithEmptyProductIdentifierAndProductPlanIdentifierReturnsNil() {
        expect(CompoundProductIdentifier(
            productIdentifier: "",
            productPlanIdentifier: "monthly"
        )).to(beNil())
    }

    func testInitWithEmptyProductIdentifierAndNilProductPlanIdentifierReturnsNil() {
        expect(CompoundProductIdentifier(
            productIdentifier: "",
            productPlanIdentifier: nil
        )).to(beNil())
    }
}

// MARK: - String Initializer
extension CompoundProductIdentifierTests {
    func testInitWithStringWithoutColonUsesWholeStringAsProductIdentifier() throws {
        let compoundIdentifier = try XCTUnwrap(CompoundProductIdentifier(
            compoundProductIdentifier: "com.revenuecat.subscription"
        ))

        expect(compoundIdentifier.productIdentifier) == "com.revenuecat.subscription"
        expect(compoundIdentifier.productPlanIdentifier).to(beNil())
        expect(compoundIdentifier.storeKitProductIdentifier) == "com.revenuecat.subscription"
        expect(compoundIdentifier.compoundProductIdentifier) == "com.revenuecat.subscription"
    }

    func testInitWithStringWithOneColonSplitsProductIdentifierAndProductPlanIdentifierWithCasing() throws {
        let compoundIdentifier = try XCTUnwrap(CompoundProductIdentifier(
            compoundProductIdentifier: "com.revenuecat.subscription:upFront"
        ))

        expect(compoundIdentifier.productIdentifier) == "com.revenuecat.subscription"
        expect(compoundIdentifier.productPlanIdentifier) == "upFront"
        expect(compoundIdentifier.storeKitProductIdentifier) == "com.revenuecat.subscription"
        expect(compoundIdentifier.compoundProductIdentifier) == "com.revenuecat.subscription:upFront"
    }

    func testInitWithStringWithOneColonAndEmptyProductPlanIdentifier() throws {
        let compoundIdentifier = try XCTUnwrap(CompoundProductIdentifier(
            compoundProductIdentifier: "com.revenuecat.subscription:"
        ))

        expect(compoundIdentifier.productIdentifier) == "com.revenuecat.subscription"
        expect(compoundIdentifier.productPlanIdentifier).to(beNil())
        expect(compoundIdentifier.compoundProductIdentifier) == "com.revenuecat.subscription"
    }

    func testInitWithStringWithOneColonAndEmptyProductIdentifierReturnsNil() {
        expect(CompoundProductIdentifier(
            compoundProductIdentifier: ":monthly"
        )).to(beNil())
    }

    func testInitWithEmptyStringReturnsNil() {
        expect(CompoundProductIdentifier(compoundProductIdentifier: "")).to(beNil())
    }

    func testInitWithMoreThanOneColonReturnsNil() {
        expect(CompoundProductIdentifier(
            compoundProductIdentifier: "com.revenuecat.subscription:monthly:extra"
        )).to(beNil())
    }

    func testInitWithAdjacentColonsReturnsNil() {
        expect(CompoundProductIdentifier(
            compoundProductIdentifier: "com.revenuecat.subscription::monthly"
        )).to(beNil())
    }

    func testInitWithOnlyColonsReturnsNil() {
        expect(CompoundProductIdentifier(compoundProductIdentifier: "::")).to(beNil())
    }

    func testInitWithStringWithMoreThanOneColonLogsWarning() {
        let productIdentifierWithMoreThanOneColon = "com.revenuecat.subscription:monthly:extra"
        let expectedMessage = StoreKitStrings.cannot_request_product_with_more_than_one_colon(
            productIdentifier: productIdentifierWithMoreThanOneColon
        )

        expect(CompoundProductIdentifier(
            compoundProductIdentifier: productIdentifierWithMoreThanOneColon
        )).to(beNil())
        self.logger.verifyMessageWasLogged(expectedMessage, level: .warn, expectedCount: 1)
    }

    func testInitWithStringWithOneOrNoColonsDoesNotLogWarning() {
        for productIdentifier in [
            "com.revenuecat.subscription",
            "com.revenuecat.subscription:monthly",
            "com.revenuecat.subscription:",
            ":monthly"
        ] {
            let expectedMessage = StoreKitStrings.cannot_request_product_with_more_than_one_colon(
                productIdentifier: productIdentifier
            )
            self.logger.clearMessages()

            _ = CompoundProductIdentifier(compoundProductIdentifier: productIdentifier)

            self.logger.verifyMessageWasNotLogged(expectedMessage, level: .warn, allowNoMessages: true)
        }
    }
}

// MARK: - StoreKit 2 Billing Plan Type
#if compiler(>=6.3.2)   // Billing plans were introduced in Xcode 26.5
extension CompoundProductIdentifierTests {

    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func testSK2BillingPlanTypeReturnsNilWithoutProductPlanIdentifier() throws {
        try AvailabilityChecks.iOS264APIAvailableOrSkipTest()

        let identifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: nil
        ))

        expect(identifier.sk2BillingPlanType).to(beNil())
    }

    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func testSK2BillingPlanTypeReturnsNilWithEmptyProductPlanIdentifier() throws {
        try AvailabilityChecks.iOS264APIAvailableOrSkipTest()

        let identifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: ""
        ))

        expect(identifier.sk2BillingPlanType).to(beNil())
    }

    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func testSK2BillingPlanTypeReturnsMonthlyForMonthlyProductPlanIdentifier() throws {
        try AvailabilityChecks.iOS264APIAvailableOrSkipTest()

        let identifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "monthly"
        ))

        expect(identifier.sk2BillingPlanType) == StoreKit.Product.SubscriptionInfo.BillingPlanType.monthly
    }

    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func testSK2BillingPlanTypeReturnsNilWithIncorrectCase() throws {
        try AvailabilityChecks.iOS264APIAvailableOrSkipTest()

        let identifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "MoNtHlY"
        ))

        expect(identifier.sk2BillingPlanType) == nil
    }

    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func testSK2BillingPlanTypeReturnsNilForUpfrontProductPlanIdentifier() throws {
        try AvailabilityChecks.iOS264APIAvailableOrSkipTest()

        let identifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "upFront"
        ))

        expect(identifier.sk2BillingPlanType).to(beNil())
    }

    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func testSK2BillingPlanTypeReturnsNilForUnknownProductPlanIdentifier() throws {
        try AvailabilityChecks.iOS264APIAvailableOrSkipTest()

        let identifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: "annual"
        ))

        expect(identifier.sk2BillingPlanType).to(beNil())
    }

    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func testSK2BillingPlanTypeReturnsNilForProductPlanIdentifierWithWhitespace() throws {
        try AvailabilityChecks.iOS264APIAvailableOrSkipTest()

        let identifier = try XCTUnwrap(CompoundProductIdentifier(
            productIdentifier: "com.revenuecat.subscription",
            productPlanIdentifier: " monthly "
        ))

        expect(identifier.sk2BillingPlanType).to(beNil())
    }

    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func testSK2BillingPlanTypeUsesSupportedProductPlanIdentifierFromStringInitializer() throws {
        try AvailabilityChecks.iOS264APIAvailableOrSkipTest()

        let monthlyIdentifier = try XCTUnwrap(CompoundProductIdentifier(
            compoundProductIdentifier: "com.revenuecat.subscription:monthly"
        ))

        expect(monthlyIdentifier.sk2BillingPlanType) == StoreKit.Product.SubscriptionInfo.BillingPlanType.monthly
    }

    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func testSK2BillingPlanTypeReturnsNilForUpfrontProductPlanIdentifierFromStringInitializer() throws {
        try AvailabilityChecks.iOS264APIAvailableOrSkipTest()

        let upFrontIdentifier = try XCTUnwrap(CompoundProductIdentifier(
            compoundProductIdentifier: "com.revenuecat.subscription:upFront"
        ))

        expect(upFrontIdentifier.sk2BillingPlanType).to(beNil())
    }
}
#endif
