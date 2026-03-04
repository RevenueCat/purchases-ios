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

}

// MARK: - Test Helpers

private struct TestPartial: PresentedPartial {

    var value: String?

    static func combine(_ base: TestPartial?, with other: TestPartial?) -> TestPartial {
        return TestPartial(value: other?.value ?? base?.value)
    }

}

#endif
