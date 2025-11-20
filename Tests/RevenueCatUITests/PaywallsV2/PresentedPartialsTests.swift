//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PresentedPartialsTests.swift
//
//  Created by Josh Holtz on 1/25/25.

import Nimble
@testable import RevenueCat
@testable import RevenueCatUI
import StoreKit
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PresentedPartialsTest: TestCase {

    private func createPackageWithIdentifier(_ identifier: String) -> Package {
        // Create a minimal package for testing
        // The buildPartial only needs package.identifier for selectedPackage conditions
        let product = TestSK1Product(identifier: identifier)
        let storeProduct = StoreProduct(sk1Product: product)

        return Package(
            identifier: identifier,
            packageType: .unknown,
            storeProduct: storeProduct,
            offeringIdentifier: "test",
            webCheckoutUrl: nil
        )
    }

    func testNoPresentedPartials() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.default
        let isEligibleForIntroOffer = false
        let isEligibleForPromoOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = []

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            selectedPackage: nil,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    func testPresentedPartialsSelectedPackageAppliedWhenMatches() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.default
        let isEligibleForIntroOffer = false
        let isEligibleForPromoOffer = false
        let selectedPackage = createPackageWithIdentifier("rc_annual")

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .selectedPackage(.in, ["rc_annual"])
            ], properties: .init(
                margin: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            selectedPackage: selectedPackage,
            with: presentedOverrides
        )

        let expected: PresentedStackPartial = .init(
            margin: .zero
        )

        expect(result).to(equal(expected))
    }

    func testPresentedPartialsSelectedPackageNotAppliedWhenDoesNotMatch() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.default
        let isEligibleForIntroOffer = false
        let isEligibleForPromoOffer = false
        let selectedPackage = createPackageWithIdentifier("rc_monthly")

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .selectedPackage(.in, ["rc_annual"])
            ], properties: .init(
                margin: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            selectedPackage: selectedPackage,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    func testPresentedPartialsMultipleConditionsAppliedInOrder() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.default
        let isEligibleForIntroOffer = false
        let isEligibleForPromoOffer = false
        let selectedPackage = createPackageWithIdentifier("rc_annual")

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .selectedPackage(.in, ["rc_monthly", "rc_annual"])
            ], properties: .init(
                padding: .zero,
                margin: .zero
            )),
            .init(conditions: [
                .selectedPackage(.in, ["rc_annual"])
            ], properties: .init(
                spacing: 8,
                margin: .init(top: 2, bottom: 2, leading: 2, trailing: 2)
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            selectedPackage: selectedPackage,
            with: presentedOverrides
        )

        let expected: PresentedStackPartial = .init(
            spacing: 8,
            padding: .zero,
            margin: .init(top: 2, bottom: 2, leading: 2, trailing: 2)
        )

        expect(result).to(equal(expected))
    }

    func testPresentedPartialsSelectedAppliedWhenSelected() {
        let state = ComponentViewState.selected
        let condition = ScreenCondition.default
        let isEligibleForIntroOffer = false
        let isEligibleForPromoOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .selected
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            selectedPackage: nil,
            with: presentedOverrides
        )

        let expected: PresentedStackPartial = .init(
            padding: .zero
        )

        expect(result).to(equal(expected))
    }

    func testPresentedPartialsSelectedNotAppliedWhenNotSelected() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.default
        let isEligibleForIntroOffer = false
        let isEligibleForPromoOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .selected
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            selectedPackage: nil,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    func testPresentedPartialsIntroOfferAppliedWhenIntroOffer() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.medium
        let isEligibleForIntroOffer = true
        let isEligibleForPromoOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .introOffer(.equals, true)
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            selectedPackage: nil,
            with: presentedOverrides
        )

        let expected: PresentedStackPartial = .init(
            padding: .zero
        )

        expect(result).to(equal(expected))
    }

    func testPresentedPartialsIntroOfferNotAppliedWhenNotIntroOffer() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.medium
        let isEligibleForIntroOffer = false
        let isEligibleForPromoOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .introOffer(.equals, true)
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            selectedPackage: nil,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

}

#endif

// Simple mock product for testing - only used to satisfy Package init requirements
private class TestSK1Product: SK1Product, @unchecked Sendable {
    let testIdentifier: String

    init(identifier: String) {
        self.testIdentifier = identifier
        super.init()
    }

    override var productIdentifier: String {
        return testIdentifier
    }

    override var price: NSDecimalNumber {
        return NSDecimalNumber(string: "9.99")
    }

    override var priceLocale: Locale {
        return Locale(identifier: "en_US")
    }
}
