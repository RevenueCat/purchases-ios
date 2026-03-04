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

    func testVariableCondition_DoubleNearlyEqual_MatchesWithinEpsilon() throws {
        // 0.1 + 0.2 != 0.3 in IEEE 754, but should match via epsilon comparison
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .equals, variable: "score", value: .double(0.3))
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["score": .number(0.1 + 0.2)]
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

    func testVariableCondition_DoubleClearlyDifferent_DoesNotMatch() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .equals, variable: "score", value: .double(3.14))
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["score": .number(3.15)]
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

    func testVariableCondition_IntFromDoubleRoundTrip_Matches() throws {
        // Int condition value compared against number variable that holds the same value
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .equals, variable: "count", value: .int(42))
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["count": .number(42.0)]
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

    // MARK: - Legacy Intro/Promo Offer Condition Tests

    func testLegacyIntroOffer_MatchesWhenEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [.introOffer]

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

    func testLegacyIntroOffer_DoesNotMatchWhenNotEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [.introOffer]

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

    func testLegacyPromoOffer_MatchesWhenEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [.promoOffer]

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

    func testLegacyPromoOffer_DoesNotMatchWhenNotEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [.promoOffer]

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

    // MARK: - Extended Intro Offer Condition Tests

    func testIntroOfferCondition_EqualsTrue_MatchesWhenEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .introOfferCondition(operator: .equals, value: true)
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
            .introOfferCondition(operator: .equals, value: false)
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
            .introOfferCondition(operator: .notEquals, value: true)
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
            .introOfferCondition(operator: .equals, value: false)
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

    func testIntroOfferCondition_NotEqualsTrue_DoesNotMatchWhenEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .introOfferCondition(operator: .notEquals, value: true)
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

    func testIntroOfferCondition_NotEqualsFalse_MatchesWhenEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .introOfferCondition(operator: .notEquals, value: false)
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

    func testIntroOfferCondition_NotEqualsFalse_DoesNotMatchWhenNotEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .introOfferCondition(operator: .notEquals, value: false)
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

    func testIntroOfferCondition_EqualsTrue_DoesNotMatchWhenNotEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .introOfferCondition(operator: .equals, value: true)
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

    // MARK: - Extended Promo Offer Condition Tests

    func testPromoOfferCondition_EqualsTrue_MatchesWhenEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .promoOfferCondition(operator: .equals, value: true)
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
            .promoOfferCondition(operator: .equals, value: false)
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
            .promoOfferCondition(operator: .notEquals, value: false)
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
            .promoOfferCondition(operator: .equals, value: true)
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

    func testPromoOfferCondition_EqualsFalse_DoesNotMatchWhenEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .promoOfferCondition(operator: .equals, value: false)
        ]

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: true,
            conditionContext: ConditionContext(),
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).to(beNil())
    }

    func testPromoOfferCondition_NotEqualsTrue_DoesNotMatchWhenEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .promoOfferCondition(operator: .notEquals, value: true)
        ]

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: true,
            conditionContext: ConditionContext(),
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).to(beNil())
    }

    func testPromoOfferCondition_NotEqualsTrue_MatchesWhenNotEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .promoOfferCondition(operator: .notEquals, value: true)
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

    func testPromoOfferCondition_NotEqualsFalse_DoesNotMatchWhenNotEligible() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .promoOfferCondition(operator: .notEquals, value: false)
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

    // MARK: - Cross-Offer Independence Tests

    func testIntroOfferCondition_IgnoresPromoEligibility() throws {
        // intro_offer equals true, only promo eligible → should NOT match
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .introOfferCondition(operator: .equals, value: true)
        ]

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: true,
            conditionContext: ConditionContext(),
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )

        expect(result).to(beNil())
    }

    func testPromoOfferCondition_IgnoresIntroEligibility() throws {
        // promo_offer equals true, only intro eligible → should NOT match
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .promoOfferCondition(operator: .equals, value: true)
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

    // MARK: - Type Safety Tests

    func testVariableCondition_BoolTrueDoesNotMatchStringTrue() throws {
        // Condition expects bool(true), variable is string("true") — should NOT match
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .equals, variable: "flag", value: .bool(true))
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["flag": .string("true")]
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

    func testVariableCondition_StringTrueDoesNotMatchBoolTrue() throws {
        // Condition expects string("true"), variable is bool(true) — should NOT match
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .equals, variable: "flag", value: .string("true"))
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["flag": .bool(true)]
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

    func testVariableCondition_NotEquals_TypeMismatch_Matches() throws {
        // NOT_EQUALS with mismatched types should APPLY (values are genuinely not equal)
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .notEquals, variable: "level", value: .int(5))
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

        expect(result).toNot(beNil())
    }

    // MARK: - Override Precedence Tests

    func testMultipleMatchingOverrides_LaterPropertiesWin() throws {
        // Two matching overrides, verify last value wins
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .introOfferCondition(operator: .equals, value: true)
        ]

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(),
            with: [
                PresentedOverride(conditions: conditions, properties: TestPartial(value: "first")),
                PresentedOverride(conditions: conditions, properties: TestPartial(value: "second"))
            ]
        )

        expect(result).toNot(beNil())
        expect(result?.value).to(equal("second"))
    }

    func testThreeOverridesCascading_OnlyMatchingOnesCombine() throws {
        // Three overrides: first matches, second doesn't, third matches
        // Verify first + third combine (skipping second)
        let matchingConditions: [PaywallComponent.ExtendedCondition] = [
            .introOfferCondition(operator: .equals, value: true)
        ]
        let nonMatchingConditions: [PaywallComponent.ExtendedCondition] = [
            .introOfferCondition(operator: .equals, value: false)
        ]

        let result = TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(),
            with: [
                PresentedOverride(conditions: matchingConditions, properties: TestPartial(value: "first")),
                PresentedOverride(conditions: nonMatchingConditions, properties: TestPartial(value: "second")),
                PresentedOverride(conditions: matchingConditions, properties: TestPartial(value: "third"))
            ]
        )

        expect(result).toNot(beNil())
        expect(result?.value).to(equal("third"))
    }

    // MARK: - Multiple Intro Offers Compatibility (iOS)

    func testMultipleIntroOffersCondition_AlwaysEvaluatesToFalse() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [.multipleIntroOffers]

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

    // MARK: - Visibility Override Precedence Tests (Bug Bash Section 6)

    func testTwoOverrides_HideThenShow_LastMatchingWins() throws {
        // Override #1: hide when plan = "free"
        // Override #2: show when selected_package in ["annual"]
        // Both match → last matching override's visible wins (visible = true)
        let overrides: PresentedOverrides<VisibilityPartial> = [
            PresentedOverride(
                conditions: [.variable(operator: .equals, variable: "plan", value: .string("free"))],
                properties: VisibilityPartial(visible: false)
            ),
            PresentedOverride(
                conditions: [.selectedPackage(operator: .in, packages: ["annual"])],
                properties: VisibilityPartial(visible: true)
            )
        ]

        let context = ConditionContext(
            selectedPackageId: "annual",
            customVariables: ["plan": .string("free")]
        )

        let result = VisibilityPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: overrides
        )

        expect(result).toNot(beNil())
        expect(result?.visible).to(equal(true))
    }

    func testTwoOverrides_OnlyFirstMatches_HidesComponent() throws {
        // Override #1: hide when plan = "free" → matches
        // Override #2: show when selected_package in ["annual"] → doesn't match (monthly selected)
        // Only override #1 matches → visible = false
        let overrides: PresentedOverrides<VisibilityPartial> = [
            PresentedOverride(
                conditions: [.variable(operator: .equals, variable: "plan", value: .string("free"))],
                properties: VisibilityPartial(visible: false)
            ),
            PresentedOverride(
                conditions: [.selectedPackage(operator: .in, packages: ["annual"])],
                properties: VisibilityPartial(visible: true)
            )
        ]

        let context = ConditionContext(
            selectedPackageId: "monthly",
            customVariables: ["plan": .string("free")]
        )

        let result = VisibilityPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: overrides
        )

        expect(result).toNot(beNil())
        expect(result?.visible).to(equal(false))
    }

    func testThreeOverrides_FirstAndThirdMatch_LastWins() throws {
        // Override #1: hide when country = "US" → matches
        // Override #2: show when selected_package in ["annual"] → matches
        // Override #3: hide when intro_offer = true → matches
        // All match → last override's visible wins (false)
        let overrides: PresentedOverrides<VisibilityPartial> = [
            PresentedOverride(
                conditions: [.variable(operator: .equals, variable: "country", value: .string("US"))],
                properties: VisibilityPartial(visible: false)
            ),
            PresentedOverride(
                conditions: [.selectedPackage(operator: .in, packages: ["annual"])],
                properties: VisibilityPartial(visible: true)
            ),
            PresentedOverride(
                conditions: [.introOfferCondition(operator: .equals, value: true)],
                properties: VisibilityPartial(visible: false)
            )
        ]

        let context = ConditionContext(
            selectedPackageId: "annual",
            customVariables: ["country": .string("US")]
        )

        let result = VisibilityPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: overrides
        )

        expect(result).toNot(beNil())
        expect(result?.visible).to(equal(false))
    }

    func testThreeOverrides_ThirdDoesNotMatch_SecondWins() throws {
        // Override #1: hide when country = "US" → matches
        // Override #2: show when selected_package in ["annual"] → matches
        // Override #3: hide when intro_offer = true → does NOT match (not eligible)
        // Overrides 1 and 2 match → override #2 wins (visible = true)
        let overrides: PresentedOverrides<VisibilityPartial> = [
            PresentedOverride(
                conditions: [.variable(operator: .equals, variable: "country", value: .string("US"))],
                properties: VisibilityPartial(visible: false)
            ),
            PresentedOverride(
                conditions: [.selectedPackage(operator: .in, packages: ["annual"])],
                properties: VisibilityPartial(visible: true)
            ),
            PresentedOverride(
                conditions: [.introOfferCondition(operator: .equals, value: true)],
                properties: VisibilityPartial(visible: false)
            )
        ]

        let context = ConditionContext(
            selectedPackageId: "annual",
            customVariables: ["country": .string("US")]
        )

        let result = VisibilityPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: overrides
        )

        expect(result).toNot(beNil())
        expect(result?.visible).to(equal(true))
    }

    // MARK: - Same Condition Hides Multiple Components (Bug Bash Section 6)

    func testSameConditionEvaluatesIndependentlyPerComponent() throws {
        // Two separate components each have the same condition
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .equals, variable: "promo", value: .string("false"))
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["promo": .string("false")]
        )

        // Component 1
        let result1 = VisibilityPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: VisibilityPartial(visible: false))]
        )

        // Component 2 (same condition, independently evaluated)
        let result2 = VisibilityPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: VisibilityPartial(visible: false))]
        )

        expect(result1?.visible).to(equal(false))
        expect(result2?.visible).to(equal(false))
    }

    // MARK: - Condition + Selected State (Bug Bash Section 11)

    func testConditionAndSelectedState_BothApply() throws {
        // Override #1: selected state styling (value = "selected_style")
        // Override #2: hide when variable "highlight" = "false"
        // When both match, the last override's properties win
        let overrides: PresentedOverrides<VisibilityPartial> = [
            PresentedOverride(
                conditions: [.selected],
                properties: VisibilityPartial(visible: true, value: "selected_style")
            ),
            PresentedOverride(
                conditions: [.variable(operator: .equals, variable: "highlight", value: .string("false"))],
                properties: VisibilityPartial(visible: false)
            )
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["highlight": .string("false")]
        )

        // Selected + highlight=false → both match, last visible (false) wins
        let result = VisibilityPartial.buildPartial(
            state: .selected,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: overrides
        )

        expect(result?.visible).to(equal(false))
    }

    func testConditionAndSelectedState_OnlySelectedMatches() throws {
        // Override #1: selected state styling
        // Override #2: hide when variable "highlight" = "false" → doesn't match (highlight = "true")
        // Only override #1 matches → visible = true
        let overrides: PresentedOverrides<VisibilityPartial> = [
            PresentedOverride(
                conditions: [.selected],
                properties: VisibilityPartial(visible: true, value: "selected_style")
            ),
            PresentedOverride(
                conditions: [.variable(operator: .equals, variable: "highlight", value: .string("false"))],
                properties: VisibilityPartial(visible: false)
            )
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["highlight": .string("true")]
        )

        let result = VisibilityPartial.buildPartial(
            state: .selected,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: overrides
        )

        expect(result?.visible).to(equal(true))
        expect(result?.value).to(equal("selected_style"))
    }

    // MARK: - Same Variable for Text Replacement AND Visibility (Bug Bash Section 11)

    func testVariableConditionMatchesExactValue() throws {
        // Override: hide when "user_name" = "John"
        // user_name = "John" → hidden
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .equals, variable: "user_name", value: .string("John"))
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["user_name": .string("John")]
        )

        let result = VisibilityPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: VisibilityPartial(visible: false))]
        )

        expect(result?.visible).to(equal(false))
    }

    func testVariableConditionDoesNotMatchDifferentValue() throws {
        // Override: hide when "user_name" = "John"
        // user_name = "Jane" → not hidden (override doesn't match)
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .variable(operator: .equals, variable: "user_name", value: .string("John"))
        ]

        let context = ConditionContext(
            selectedPackageId: nil,
            customVariables: ["user_name": .string("Jane")]
        )

        let result = VisibilityPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: context,
            with: [PresentedOverride(conditions: conditions, properties: VisibilityPartial(visible: false))]
        )

        expect(result).to(beNil())
    }

    // MARK: - Intro Offer with Different Eligibility per Evaluation (Bug Bash Section 4)

    func testIntroOfferCondition_DifferentEligibilityProducesDifferentResults() throws {
        // Same condition evaluated with different eligibility states
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .introOfferCondition(operator: .equals, value: true)
        ]

        let overrides = [PresentedOverride(
            conditions: conditions,
            properties: VisibilityPartial(visible: false)
        )]

        // Eligible user → condition matches → visible = false
        let eligibleResult = VisibilityPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(),
            with: overrides
        )

        // Ineligible user → condition doesn't match → nil (no override applied)
        let ineligibleResult = VisibilityPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(),
            with: overrides
        )

        expect(eligibleResult?.visible).to(equal(false))
        expect(ineligibleResult).to(beNil())
    }

    // MARK: - Different Condition Types on Sibling Components (Bug Bash Section 6)

    func testDifferentConditionTypes_EvaluateIndependently() throws {
        // Component 1: hide when user_tier = "premium"
        let component1Overrides = [PresentedOverride(
            conditions: [PaywallComponent.ExtendedCondition.variable(
                operator: .equals, variable: "user_tier", value: .string("premium")
            )],
            properties: VisibilityPartial(visible: false)
        )]

        // Component 2: hide when selected_package in ["annual"]
        let component2Overrides = [PresentedOverride(
            conditions: [PaywallComponent.ExtendedCondition.selectedPackage(
                operator: .in, packages: ["annual"]
            )],
            properties: VisibilityPartial(visible: false)
        )]

        let context = ConditionContext(
            selectedPackageId: "annual",
            customVariables: ["user_tier": .string("premium")]
        )

        // Both hidden
        let result1 = VisibilityPartial.buildPartial(
            state: .default, condition: .compact,
            isEligibleForIntroOffer: false, isEligibleForPromoOffer: false,
            conditionContext: context, with: component1Overrides
        )
        let result2 = VisibilityPartial.buildPartial(
            state: .default, condition: .compact,
            isEligibleForIntroOffer: false, isEligibleForPromoOffer: false,
            conditionContext: context, with: component2Overrides
        )

        expect(result1?.visible).to(equal(false))
        expect(result2?.visible).to(equal(false))

        // Change user_tier → component 1 reappears, component 2 stays hidden
        let context2 = ConditionContext(
            selectedPackageId: "annual",
            customVariables: ["user_tier": .string("free")]
        )

        let result1After = VisibilityPartial.buildPartial(
            state: .default, condition: .compact,
            isEligibleForIntroOffer: false, isEligibleForPromoOffer: false,
            conditionContext: context2, with: component1Overrides
        )
        let result2After = VisibilityPartial.buildPartial(
            state: .default, condition: .compact,
            isEligibleForIntroOffer: false, isEligibleForPromoOffer: false,
            conditionContext: context2, with: component2Overrides
        )

        expect(result1After).to(beNil())
        expect(result2After?.visible).to(equal(false))
    }

}

// MARK: - Test Helpers

private struct TestPartial: PresentedPartial {

    var value: String?

    static func combine(_ base: TestPartial?, with other: TestPartial?) -> TestPartial {
        return TestPartial(value: other?.value ?? base?.value)
    }

}

private struct VisibilityPartial: PresentedPartial {

    var visible: Bool?
    var value: String?

    static func combine(_ base: VisibilityPartial?, with other: VisibilityPartial?) -> VisibilityPartial {
        return VisibilityPartial(
            visible: other?.visible ?? base?.visible,
            value: other?.value ?? base?.value
        )
    }

}

#endif
