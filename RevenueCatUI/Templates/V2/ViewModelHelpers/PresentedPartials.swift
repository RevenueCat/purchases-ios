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
import RevenueCat

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

    let conditions: [PaywallComponent.Condition]
    let properties: T?

}

/// Context for evaluating conditions in paywall components.
/// Contains all runtime state needed to determine if a condition should apply.
struct ConditionEvaluationContext {

    /// Current view state (default/selected)
    let state: ComponentViewState

    /// Current screen size condition (compact/medium/expanded)
    let screenCondition: ScreenCondition

    /// Whether the user is eligible for an intro offer
    let isEligibleForIntroOffer: Bool

    /// Whether the user is eligible for a promo offer
    let isEligibleForPromoOffer: Bool

    /// Custom variables provided by the developer
    let customVariables: [String: CustomVariableValue]

    /// The currently selected package ID (from user selection)
    let selectedPackageId: String?

    /// The current package ID in context (e.g., within a PackageComponent)
    let currentPackageId: String?

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

    /// Builds a partial component based on full evaluation context
    /// - Parameters:
    ///   - context: Full evaluation context containing all runtime state
    ///   - presentedOverrides: Override configurations to apply
    /// - Returns: Configured partial component
    static func buildPartial(
        context: ConditionEvaluationContext,
        with presentedOverrides: PresentedOverrides<Self>?
    ) -> Self? {
        guard let presentedOverrides else {
            return nil
        }

        var presentedPartial: Self?

        for presentedOverride in presentedOverrides where self.shouldApply(
            for: presentedOverride.conditions,
            context: context
        ) {
            presentedPartial = Self.combine(presentedPartial, with: presentedOverride.properties)
        }

        return presentedPartial
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func shouldApply(
        for conditions: [PaywallComponent.Condition],
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
            case .introOffer:
                if !isEligibleForIntroOffer {
                    return false
                }
            case .promoOffer:
                if !isEligibleForPromoOffer {
                    return false
                }
            case .selected:
                if state != .selected {
                    return false
                }
            case .introOfferCondition, .promoOfferCondition,
                 .variableCondition, .packageCondition, .selectedPackageCondition:
                // These conditions require the full context - fall back to false in legacy method
                return false
            case .unsupported:
                return false
            }
        }

        return true
    }

    private static func shouldApply(
        for conditions: [PaywallComponent.Condition],
        context: ConditionEvaluationContext
    ) -> Bool {
        // All conditions must be true (AND logic)
        for condition in conditions where !evaluateCondition(condition, context: context) {
            return false
        }
        return true
    }

    private static func evaluateCondition(
        _ condition: PaywallComponent.Condition,
        context: ConditionEvaluationContext
    ) -> Bool {
        switch condition {
        // Screen size conditions
        case .compact, .medium, .expanded:
            return context.screenCondition.applicableConditions.contains(condition)

        // Selection state
        case .selected:
            return context.state == .selected

        // Legacy offer eligibility (no operator - assumes equals true)
        case .introOffer:
            return context.isEligibleForIntroOffer
        case .promoOffer:
            return context.isEligibleForPromoOffer

        // Extended offer eligibility (with operator/value)
        case .introOfferCondition(let condOp, let value):
            return evaluateBoolCondition(
                actual: context.isEligibleForIntroOffer,
                expected: value,
                operator: condOp
            )
        case .promoOfferCondition(let condOp, let value):
            return evaluateBoolCondition(
                actual: context.isEligibleForPromoOffer,
                expected: value,
                operator: condOp
            )

        // Variable condition
        case .variableCondition(let condOp, let variable, let value):
            return evaluateVariableCondition(
                variable: variable,
                expectedValue: value,
                operator: condOp,
                customVariables: context.customVariables
            )

        // Package condition (checks current package in context)
        case .packageCondition(let condOp, let packageId):
            return evaluatePackageCondition(
                packageId: packageId,
                operator: condOp,
                currentPackageId: context.currentPackageId
            )

        // Selected package condition (checks user's selected package)
        case .selectedPackageCondition(let condOp, let packages):
            return evaluateSelectedPackageCondition(
                packages: packages,
                operator: condOp,
                selectedPackageId: context.selectedPackageId
            )

        // Unknown/unsupported conditions never match
        case .unsupported:
            return false
        }
    }

    private static func evaluateBoolCondition(
        actual: Bool,
        expected: Bool,
        operator condOp: PaywallComponent.ConditionOperator
    ) -> Bool {
        switch condOp {
        case .equals:
            return actual == expected
        case .notEquals:
            return actual != expected
        case .in, .notIn:
            // Boolean conditions don't support in/notIn operators
            return false
        }
    }

    private static func evaluateVariableCondition(
        variable: String,
        expectedValue: PaywallComponent.ConditionValue,
        operator condOp: PaywallComponent.ConditionOperator,
        customVariables: [String: CustomVariableValue]
    ) -> Bool {
        guard let actualValue = customVariables[variable] else {
            // Variable not found - condition doesn't match
            return false
        }

        // Convert CustomVariableValue to string for comparison
        let actualString: String
        switch actualValue {
        case .string(let value):
            actualString = value
        case .int(let value):
            actualString = String(value)
        case .double(let value):
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                actualString = String(format: "%.0f", value)
            } else {
                actualString = String(value)
            }
        }

        let expectedString = expectedValue.stringValue

        switch condOp {
        case .equals:
            return actualString == expectedString
        case .notEquals:
            return actualString != expectedString
        case .in, .notIn:
            // Variable conditions with in/notIn are not supported in V0
            return false
        }
    }

    private static func evaluatePackageCondition(
        packageId: String,
        operator condOp: PaywallComponent.ConditionOperator,
        currentPackageId: String?
    ) -> Bool {
        guard let currentPackageId else {
            // No package context - condition doesn't match
            return false
        }

        switch condOp {
        case .equals:
            return currentPackageId == packageId
        case .notEquals:
            return currentPackageId != packageId
        case .in, .notIn:
            // Package condition doesn't support in/notIn operators
            return false
        }
    }

    private static func evaluateSelectedPackageCondition(
        packages: [String],
        operator condOp: PaywallComponent.ConditionOperator,
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
        case .equals, .notEquals:
            // Selected package condition doesn't support equals/notEquals operators
            return false
        }
    }

}

private extension ScreenCondition {

    /// Returns applicable condition types based on current screen condition
    var applicableConditions: [PaywallComponent.Condition] {
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
                conditions: partial.conditions,
                properties: presentedPartial
            )
        }
    }

}

#endif
