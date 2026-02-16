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
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PresentedPartialsTest: TestCase {

    func testNoPresentedPartials() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.compact
        let isEligibleForIntroOffer = false
        let isEligibleForPromoOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = []

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    func testPresentedPartialsCompactAppliedForCompact() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.compact
        let isEligibleForIntroOffer = false
        let isEligibleForPromoOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .compact
            ], properties: .init(
                margin: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            with: presentedOverrides
        )

        let expected: PresentedStackPartial = .init(
            margin: .zero
        )

        expect(result).to(equal(expected))
    }

    func testPresentedPartialsMediumNotAppliedForCompact() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.compact
        let isEligibleForIntroOffer = false
        let isEligibleForPromoOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .medium
            ], properties: .init(
                margin: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    func testPresentedPartialsCompactAndMediumAppliedForMedium() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.medium
        let isEligibleForIntroOffer = false
        let isEligibleForPromoOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .compact
            ], properties: .init(
                padding: .zero,
                margin: .zero
            )),
            .init(conditions: [
                .medium
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
        let condition = ScreenCondition.medium
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
            with: presentedOverrides
        )

        let expected: PresentedStackPartial = .init(
            padding: .zero
        )

        expect(result).to(equal(expected))
    }

    func testPresentedPartialsSelectedNotAppliedWhenNotSelected() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.medium
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
                .introOffer
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
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
                .introOffer
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    // MARK: - Extended Intro Offer Condition Tests

    func testExtendedIntroOfferConditionEqualsTrue_WhenEligible() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: false,
            customVariables: [:],
            selectedPackageId: nil,
            currentPackageId: nil
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .introOfferCondition(operator: .equals, value: true)
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).toNot(beNil())
    }

    func testExtendedIntroOfferConditionEqualsFalse_WhenNotEligible() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            customVariables: [:],
            selectedPackageId: nil,
            currentPackageId: nil
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .introOfferCondition(operator: .equals, value: false)
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).toNot(beNil())
    }

    func testExtendedIntroOfferConditionNotEquals_WhenEligible() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: false,
            customVariables: [:],
            selectedPackageId: nil,
            currentPackageId: nil
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .introOfferCondition(operator: .notEquals, value: false)
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).toNot(beNil())
    }

    // MARK: - Variable Condition Tests

    func testVariableConditionEquals_Match() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            customVariables: ["plan": .string("premium")],
            selectedPackageId: nil,
            currentPackageId: nil
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .variableCondition(operator: .equals, variable: "plan", value: .string("premium"))
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).toNot(beNil())
    }

    func testVariableConditionEquals_NoMatch() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            customVariables: ["plan": .string("basic")],
            selectedPackageId: nil,
            currentPackageId: nil
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .variableCondition(operator: .equals, variable: "plan", value: .string("premium"))
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    func testVariableConditionNotEquals_Match() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            customVariables: ["plan": .string("basic")],
            selectedPackageId: nil,
            currentPackageId: nil
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .variableCondition(operator: .notEquals, variable: "plan", value: .string("premium"))
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).toNot(beNil())
    }

    func testVariableConditionMissingVariable_ReturnsFalse() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            customVariables: [:],
            selectedPackageId: nil,
            currentPackageId: nil
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .variableCondition(operator: .equals, variable: "missing", value: .string("value"))
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    // MARK: - Package Condition Tests

    func testPackageConditionEquals_Match() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            customVariables: [:],
            selectedPackageId: nil,
            currentPackageId: "monthly"
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .packageCondition(operator: .equals, packageId: "monthly")
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).toNot(beNil())
    }

    func testPackageConditionEquals_NoMatch() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            customVariables: [:],
            selectedPackageId: nil,
            currentPackageId: "annual"
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .packageCondition(operator: .equals, packageId: "monthly")
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    func testPackageConditionNotEquals_Match() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            customVariables: [:],
            selectedPackageId: nil,
            currentPackageId: "annual"
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .packageCondition(operator: .notEquals, packageId: "monthly")
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).toNot(beNil())
    }

    func testPackageConditionNoPackageContext_ReturnsFalse() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            customVariables: [:],
            selectedPackageId: nil,
            currentPackageId: nil
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .packageCondition(operator: .equals, packageId: "monthly")
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    // MARK: - Selected Package Condition Tests

    func testSelectedPackageConditionIn_Match() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            customVariables: [:],
            selectedPackageId: "monthly",
            currentPackageId: nil
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .selectedPackageCondition(operator: .in, packages: ["monthly", "annual"])
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).toNot(beNil())
    }

    func testSelectedPackageConditionIn_NoMatch() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            customVariables: [:],
            selectedPackageId: "weekly",
            currentPackageId: nil
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .selectedPackageCondition(operator: .in, packages: ["monthly", "annual"])
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    func testSelectedPackageConditionNotIn_Match() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            customVariables: [:],
            selectedPackageId: "weekly",
            currentPackageId: nil
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .selectedPackageCondition(operator: .notIn, packages: ["monthly", "annual"])
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).toNot(beNil())
    }

    func testSelectedPackageConditionNoSelection_ReturnsFalse() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            customVariables: [:],
            selectedPackageId: nil,
            currentPackageId: nil
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .selectedPackageCondition(operator: .in, packages: ["monthly"])
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    // MARK: - Multiple Conditions (AND logic) Tests

    func testMultipleConditions_AllMatch() {
        let context = ConditionEvaluationContext(
            state: .selected,
            screenCondition: .compact,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: false,
            customVariables: ["plan": .string("premium")],
            selectedPackageId: "monthly",
            currentPackageId: "monthly"
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .selected,
                .introOfferCondition(operator: .equals, value: true),
                .variableCondition(operator: .equals, variable: "plan", value: .string("premium"))
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).toNot(beNil())
    }

    func testMultipleConditions_OneFails() {
        let context = ConditionEvaluationContext(
            state: .selected,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,  // This will cause intro offer condition to fail
            isEligibleForPromoOffer: false,
            customVariables: ["plan": .string("premium")],
            selectedPackageId: "monthly",
            currentPackageId: "monthly"
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .selected,
                .introOfferCondition(operator: .equals, value: true),  // This fails
                .variableCondition(operator: .equals, variable: "plan", value: .string("premium"))
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    // MARK: - Unsupported Condition Tests

    func testUnsupportedCondition_NeverApplies() {
        let context = ConditionEvaluationContext(
            state: .default,
            screenCondition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            customVariables: [:],
            selectedPackageId: nil,
            currentPackageId: nil
        )

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .unsupported
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            context: context,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

}

#endif
