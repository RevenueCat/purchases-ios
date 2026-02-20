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
//  Created by RevenueCat on 2/18/26.
//

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PresentedPartialsTests: TestCase {

    // MARK: - Selected Package Condition Tests

    func testSelectedPackageCondition_InOperator_MatchesSelectedPackage() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .selectedPackage(operator: .in, packages: ["monthly", "annual"])
        ]

        let context = ConditionContext(selectedPackageId: "monthly", customVariables: [:])

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).toNot(beNil())
    }

    func testSelectedPackageCondition_InOperator_DoesNotMatchWhenPackageNotInList() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .selectedPackage(operator: .in, packages: ["monthly", "annual"])
        ]

        let context = ConditionContext(selectedPackageId: "weekly", customVariables: [:])

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).to(beNil())
    }

    func testSelectedPackageCondition_NotInOperator_MatchesWhenPackageNotInList() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .selectedPackage(operator: .notIn, packages: ["trial"])
        ]

        let context = ConditionContext(selectedPackageId: "monthly", customVariables: [:])

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).toNot(beNil())
    }

    func testSelectedPackageCondition_NoSelection_DoesNotMatch() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .selectedPackage(operator: .in, packages: ["monthly"])
        ]

        let context = ConditionContext(selectedPackageId: nil, customVariables: [:])

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).to(beNil())
    }

    // MARK: - Variable Condition Tests

    func testVariableCondition_StringEquals_Matches() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .equals, variable: "plan", value: .string("premium"))
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["plan": .string("premium")]
        )

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).toNot(beNil())
    }

    func testVariableCondition_StringNotEquals_Matches() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .notEquals, variable: "plan", value: .string("basic"))
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["plan": .string("premium")]
        )

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).toNot(beNil())
    }

    func testVariableCondition_IntEquals_Matches() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .equals, variable: "level", value: .int(5))
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["level": .number(5)]
        )

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).toNot(beNil())
    }

    func testVariableCondition_VariableNotFound_DoesNotMatch() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .equals, variable: "missing", value: .string("value"))
        ]

        let context = ConditionContext(selectedPackageId: nil, customVariables: [:])

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).to(beNil())
    }

    func testVariableCondition_BooleanEquals_Matches() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .equals, variable: "is_vip", value: .bool(true))
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["is_vip": .bool(true)]
        )

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).toNot(beNil())
    }

    func testVariableCondition_DoubleEquals_Matches() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .equals, variable: "score", value: .double(9.5))
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["score": .number(9.5)]
        )

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).toNot(beNil())
    }

    func testVariableCondition_TypeMismatch_DoesNotMatch() throws {
        // Condition expects int, but variable is a string
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .equals, variable: "level", value: .int(5))
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["level": .string("5")]
        )

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).to(beNil())
    }

    // MARK: - Extended Intro Offer Condition Tests

    func testIntroOfferCondition_EqualsTrue_MatchesWhenEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .introOffer(operator: .equals, value: true)
        ]

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(),
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).toNot(beNil())
    }

    func testIntroOfferCondition_EqualsFalse_MatchesWhenNotEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .introOffer(operator: .equals, value: false)
        ]

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(),
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).toNot(beNil())
    }

    func testIntroOfferCondition_NotEqualsTrue_MatchesWhenNotEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .introOffer(operator: .notEquals, value: true)
        ]

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(),
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).toNot(beNil())
    }

    func testIntroOfferCondition_EqualsFalse_DoesNotMatchWhenEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .introOffer(operator: .equals, value: false)
        ]

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(),
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).to(beNil())
    }

    // MARK: - Extended Promo Offer Condition Tests

    func testPromoOfferCondition_EqualsTrue_MatchesWhenEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .promoOffer(operator: .equals, value: true)
        ]

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: true,
            conditionContext: ConditionContext(),
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).toNot(beNil())
    }

    func testPromoOfferCondition_EqualsFalse_MatchesWhenNotEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .promoOffer(operator: .equals, value: false)
        ]

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(),
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).toNot(beNil())
    }

    func testPromoOfferCondition_NotEqualsFalse_MatchesWhenEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .promoOffer(operator: .notEquals, value: false)
        ]

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: true,
            conditionContext: ConditionContext(),
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).toNot(beNil())
    }

    func testPromoOfferCondition_EqualsTrue_DoesNotMatchWhenNotEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .promoOffer(operator: .equals, value: true)
        ]

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(),
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).to(beNil())
    }

    // MARK: - Multiple Conditions (AND logic) Tests

    func testMultipleConditions_AllMustMatch() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .selectedPackage(operator: .in, packages: ["monthly"]),
            .variable(operator: .equals, variable: "vip", value: .string("true"))
        ]

        let context = ConditionContext(
            selectedPackageId: "monthly",
            customVariables: ["vip": .string("true")]
        )

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).toNot(beNil())
    }

    func testMultipleConditions_OneFailsDoesNotMatch() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .selectedPackage(operator: .in, packages: ["monthly"]),
            .variable(operator: .equals, variable: "vip", value: .string("true"))
        ]

        // Package matches, but variable doesn't
        let context = ConditionContext(
            selectedPackageId: "monthly",
            customVariables: ["vip": .string("false")]
        )

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).to(beNil())
    }

    // MARK: - Unsupported Condition Tests

    func testUnsupportedCondition_DoesNotMatch() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [.unsupported]

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(),
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).to(beNil())
    }

}

// MARK: - Test Helpers

private struct TestPartial: PresentedPartial {
    static func combine(_ base: TestPartial?, with other: TestPartial?) -> TestPartial {
        return other ?? base ?? TestPartial()
    }
}

#endif
