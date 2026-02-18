//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalizedPartials.swift
//
//  Created by Josh Holtz on 10/27/24.
//

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) // For Paywalls V2

/// Protocol defining how partial components can be combined
protocol PresentedPartial {

    /// Combines two partial components, allowing for override behavior
    /// - Parameters:
    ///   - base: The base partial component
    ///   - other: The overriding partial component
    /// - Returns: Combined partial component
    static func combine(_ base: Self?, with other: Self?) -> Self

}

/// Array holding override configurations for different presentation states
typealias PresentedOverrides<T: PresentedPartial> = [PresentedOverride<T>]

/// Structure holding override configurations for a presentation state
struct PresentedOverride<T: PresentedPartial> {

    let conditions: [PaywallComponent.ExtendedCondition]
    let properties: T?

}

/// Context needed to evaluate conditions on component overrides.
struct ConditionContext {

    /// The identifier of the currently selected package, or nil if none is selected.
    let selectedPackageId: String?

    /// Custom variables provided by the developer for condition evaluation.
    let customVariables: [String: CustomVariableValue]

    /// Creates a context with the given parameters.
    init(
        selectedPackageId: String? = nil,
        customVariables: [String: CustomVariableValue] = [:]
    ) {
        self.selectedPackageId = selectedPackageId
        self.customVariables = customVariables
    }

}

extension PresentedPartial {

    /// Builds a partial component based on current state and conditions
    /// - Parameters:
    ///   - state: Current view state (selected/unselected)
    ///   - condition: Current screen condition (compact/medium/expanded)
    ///   - presentedOverrides: Override configurations to apply
    /// - Returns: Configured partial component
    static func buildPartial(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        with presentedOverrides: PresentedOverrides<Self>?
    ) -> Self? {
        guard let presentedOverrides else {
            return nil
        }

        var presentedPartial: Self?

        for presentedOverride in presentedOverrides where self.shouldApply(
            for: presentedOverride.conditions,
            state: state,
            activeCondition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer
        ) {
            presentedPartial = Self.combine(presentedPartial, with: presentedOverride.properties)
        }

        return presentedPartial
    }

    /// Builds a partial component based on current state, conditions, and condition context.
    /// - Parameters:
    ///   - state: Current view state (selected/unselected)
    ///   - condition: Current screen condition (compact/medium/expanded)
    ///   - isEligibleForIntroOffer: Whether the user is eligible for an intro offer
    ///   - isEligibleForPromoOffer: Whether the user is eligible for a promo offer
    ///   - conditionContext: Additional context for evaluating new condition types
    ///   - presentedOverrides: Override configurations to apply
    /// - Returns: Configured partial component
    // swiftlint:disable:next function_parameter_count
    static func buildPartial(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        conditionContext: ConditionContext,
        with presentedOverrides: PresentedOverrides<Self>?
    ) -> Self? {
        guard let presentedOverrides else {
            return nil
        }

        var presentedPartial: Self?

        for presentedOverride in presentedOverrides where self.shouldApply(
            for: presentedOverride.conditions,
            state: state,
            activeCondition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            conditionContext: conditionContext
        ) {
            presentedPartial = Self.combine(presentedPartial, with: presentedOverride.properties)
        }

        return presentedPartial
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func shouldApply(
        for conditions: [PaywallComponent.ExtendedCondition],
        state: ComponentViewState,
        activeCondition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool
    ) -> Bool {
        // Early return when any condition evaluates to false
        for condition in conditions {
            switch condition {
            case .compact, .medium, .expanded:
                if !activeCondition.applicableConditions.contains(condition) {
                    return false
                }
            case .selected:
                if state != .selected {
                    return false
                }
            case .introOffer(let condOp, let value):
                let matches = (condOp == .equals) == (isEligibleForIntroOffer == value)
                if !matches {
                    return false
                }
            case .promoOffer(let condOp, let value):
                let matches = (condOp == .equals) == (isEligibleForPromoOffer == value)
                if !matches {
                    return false
                }
            case .variable, .selectedPackage:
                // These conditions require the full context - fall back to false in legacy method
                return false
            case .unsupported:
                return false
            }
        }

        return true
    }

    // swiftlint:disable:next function_parameter_count
    private static func shouldApply(
        for conditions: [PaywallComponent.ExtendedCondition],
        state: ComponentViewState,
        activeCondition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        conditionContext: ConditionContext
    ) -> Bool {
        // All conditions must be true (AND logic)
        for condition in conditions where !evaluateCondition(
            condition,
            state: state,
            activeCondition: activeCondition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            conditionContext: conditionContext
        ) {
            return false
        }
        return true
    }

    // swiftlint:disable:next function_parameter_count
    private static func evaluateCondition(
        _ condition: PaywallComponent.ExtendedCondition,
        state: ComponentViewState,
        activeCondition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        conditionContext: ConditionContext
    ) -> Bool {
        switch condition {
        // Screen size conditions
        case .compact, .medium, .expanded:
            return activeCondition.applicableConditions.contains(condition)

        // Selection state
        case .selected:
            return state == .selected

        // Legacy offer eligibility (no operator - assumes equals true)
        case .introOffer:
            return isEligibleForIntroOffer
        case .promoOffer:
            return isEligibleForPromoOffer

        // Extended offer eligibility (with operator/value)
        case .introOfferCondition(let condOp, let value):
            return evaluateBoolCondition(
                actual: isEligibleForIntroOffer,
                expected: value,
                operator: condOp
            )
        case .promoOfferCondition(let condOp, let value):
            return evaluateBoolCondition(
                actual: isEligibleForPromoOffer,
                expected: value,
                operator: condOp
            )

        // Variable condition
        case .variableCondition(let condOp, let variable, let value):
            return evaluateVariableCondition(
                variable: variable,
                expectedValue: value,
                operator: condOp,
                customVariables: conditionContext.customVariables
            )

        // Selected package condition
        case .selectedPackageCondition(let condOp, let packages):
            return evaluateSelectedPackageCondition(
                packages: packages,
                operator: condOp,
                selectedPackageId: conditionContext.selectedPackageId
            )

        // Unknown/unsupported conditions never match
        case .unsupported:
            return false
        }
    }

    private static func evaluateSelectedPackageCondition(
        packages: [String],
        operator condOp: PaywallComponent.ArrayOperator,
        selectedPackageId: String?
    ) -> Bool {
        guard let selectedPackageId else {
            // No selection - condition doesn't match
            return false
        }

        switch condOp {
        case .in:
            return packages.contains(selectedPackageId)
        case .notIn:
            return !packages.contains(selectedPackageId)
        }
    }

    private static func evaluateBoolCondition(
        actual: Bool,
        expected: Bool,
        operator condOp: PaywallComponent.EqualityOperator
    ) -> Bool {
        switch condOp {
        case .equals:
            return actual == expected
        case .notEquals:
            return actual != expected
        }
    }

    private static func evaluateVariableCondition(
        variable: String,
        expectedValue: PaywallComponent.ConditionValue,
        operator condOp: PaywallComponent.EqualityOperator,
        customVariables: [String: CustomVariableValue]
    ) -> Bool {
        guard let actualValue = customVariables[variable] else {
            // Variable not found - condition doesn't match
            return false
        }

        let matches = matchesValue(actualValue: actualValue, expectedValue: expectedValue)

        switch condOp {
        case .equals:
            return matches
        case .notEquals:
            return !matches
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func matchesValue(
        actualValue: CustomVariableValue,
        expectedValue: PaywallComponent.ConditionValue
    ) -> Bool {
        switch expectedValue {
        case .string(let expected):
            if case .string(let actual) = actualValue {
                return actual == expected
            }
            return false
        case .bool(let expected):
            // Note: CustomVariableValue doesn't have a bool case, so we check string representation
            if case .string(let actual) = actualValue {
                return (actual.lowercased() == "true") == expected
            }
            return false
        case .int(let expected):
            switch actualValue {
            case .int(let actual):
                return actual == expected
            case .double(let actual):
                return actual == Double(expected)
            default:
                return false
            }
        case .double(let expected):
            switch actualValue {
            case .int(let actual):
                return Double(actual) == expected
            case .double(let actual):
                return actual == expected
            default:
                return false
            }
        }
    }

}

private extension ScreenCondition {

    /// Returns applicable condition types based on current screen condition
    var applicableConditions: [PaywallComponent.ExtendedCondition] {
        switch self {
        case .compact: return [.compact]
        case .medium: return [.compact, .medium]
        case .expanded: return [.compact, .medium, .expanded]
        }
    }

}

extension Array {

    /// Converts component overrides to presented overrides
    /// - Parameter convert: Conversion function to apply
    /// - Returns: Presented overrides with converted components
    func toPresentedOverrides<
        T: PaywallPartialComponent,
        P: PresentedPartial
    >(
        convert: (T) throws -> P
    ) rethrows -> PresentedOverrides<P>
    where Element == PaywallComponent.ComponentOverride<T> {
        return try self.compactMap { partial in
            let presentedPartial = try convert(partial.properties)

            return PresentedOverride(
                conditions: partial.extendedConditions,
                properties: presentedPartial
            )
        }
    }

}

#endif
