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
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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

    private static func shouldApply(
        for conditions: [PaywallComponent.ExtendedCondition],
        state: ComponentViewState,
        activeCondition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool
    ) -> Bool {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return shouldApply(
                for: conditions,
                state: state,
                activeCondition: activeCondition,
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                conditionContext: ConditionContext()
            )
        } else {
            return false
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    // swiftlint:disable:next function_parameter_count
    private static func shouldApply(
        for conditions: [PaywallComponent.ExtendedCondition],
        state: ComponentViewState,
        activeCondition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        conditionContext: ConditionContext
    ) -> Bool {
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

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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

        // Offer eligibility (with operator/value)
        case .introOffer(let condOp, let value):
            return evaluateBoolCondition(
                actual: isEligibleForIntroOffer,
                expected: value,
                operator: condOp
            )
        case .promoOffer(let condOp, let value):
            return evaluateBoolCondition(
                actual: isEligibleForPromoOffer,
                expected: value,
                operator: condOp
            )

        // Variable condition
        case .variable(let condOp, let variable, let value):
            return evaluateVariableCondition(
                variable: variable,
                expectedValue: value,
                operator: condOp,
                customVariables: conditionContext.customVariables
            )

        // Selected package condition
        case .selectedPackage(let condOp, let packages):
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

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private static func evaluateVariableCondition(
        variable: String,
        expectedValue: PaywallComponent.ConditionValue,
        operator condOp: PaywallComponent.EqualityOperator,
        customVariables: [String: CustomVariableValue]
    ) -> Bool {
        guard let actualValue = customVariables[variable] else {
            return condOp == .notEquals
        }

        let matches = matchesValue(actualValue: actualValue, expectedValue: expectedValue)

        switch condOp {
        case .equals:
            return matches
        case .notEquals:
            return !matches
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private static func matchesValue(
        actualValue: CustomVariableValue,
        expectedValue: PaywallComponent.ConditionValue
    ) -> Bool {
        switch (expectedValue, actualValue.storage) {
        case (.string(let expected), .string(let actual)):
            return actual == expected
        case (.bool(let expected), .bool(let actual)):
            return actual == expected
        case (.int(let expected), .number(let actual)):
            return actual == Double(expected)
        case (.double(let expected), .number(let actual)):
            return actual == expected
        default:
            return false
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
    /// - Throws: `PaywallError.unsupportedCondition` if any override contains unsupported conditions
    func toPresentedOverrides<
        T: PaywallPartialComponent,
        P: PresentedPartial
    >(
        convert: (T) throws -> P
    ) throws -> PresentedOverrides<P>
    where Element == PaywallComponent.ComponentOverride<T> {
        // Check for unsupported conditions first - triggers fallback to default paywall
        if self.containsUnsupportedConditions() {
            throw PaywallError.unsupportedCondition
        }

        return try self.compactMap { partial in
            let presentedPartial = try convert(partial.properties)

            return PresentedOverride(
                conditions: partial.extendedConditions,
                properties: presentedPartial
            )
        }
    }

    func hasUnsupportedCondition<T: PaywallPartialComponent>() -> Bool
    where Element == PaywallComponent.ComponentOverride<T> {
        contains { $0.extendedConditions.contains(.unsupported) }
    }

}

// MARK: - Unsupported Condition Validation

extension PaywallComponent {

    func containsUnsupportedConditions() -> Bool {
        switch self {
        case .text(let c):
            return c.overrides?.hasUnsupportedCondition() == true
        case .image(let c):
            return c.overrides?.hasUnsupportedCondition() == true
        case .icon(let c):
            return c.overrides?.hasUnsupportedCondition() == true
        case .video(let c):
            return c.overrides?.hasUnsupportedCondition() == true
        case .stack(let c):
            return c.containsUnsupportedConditions()
        case .button(let c):
            return c.stack.containsUnsupportedConditions()
        case .package(let c):
            return c.stack.containsUnsupportedConditions()
        case .purchaseButton(let c):
            return c.stack.containsUnsupportedConditions()
        case .stickyFooter(let c):
            return c.stack.containsUnsupportedConditions()
        case .timeline(let c):
            return c.containsUnsupportedConditions()
        case .tabs(let c):
            return c.containsUnsupportedConditions()
        case .tabControl:
            return false
        case .tabControlButton(let c):
            return c.stack.containsUnsupportedConditions()
        case .tabControlToggle:
            return false
        case .carousel(let c):
            return c.containsUnsupportedConditions()
        case .countdown(let c):
            return c.containsUnsupportedConditions()
        }
    }

}

extension PaywallComponent.StackComponent {

    func containsUnsupportedConditions() -> Bool {
        (overrides?.hasUnsupportedCondition() == true) ||
        components.contains(where: { $0.containsUnsupportedConditions() })
    }

}

extension PaywallComponent.TimelineComponent {

    func containsUnsupportedConditions() -> Bool {
        (overrides?.hasUnsupportedCondition() == true) ||
        items.contains(where: { $0.overrides?.hasUnsupportedCondition() == true })
    }

}

extension PaywallComponent.TabsComponent {

    func containsUnsupportedConditions() -> Bool {
        (overrides?.hasUnsupportedCondition() == true) ||
        tabs.contains(where: { $0.stack.containsUnsupportedConditions() }) ||
        control.stack.containsUnsupportedConditions()
    }

}

extension PaywallComponent.CarouselComponent {

    func containsUnsupportedConditions() -> Bool {
        (overrides?.hasUnsupportedCondition() == true) ||
        pages.contains(where: { $0.containsUnsupportedConditions() })
    }

}

extension PaywallComponent.CountdownComponent {

    func containsUnsupportedConditions() -> Bool {
        (overrides?.hasUnsupportedCondition() == true) ||
        countdownStack.containsUnsupportedConditions() ||
        (endStack?.containsUnsupportedConditions() == true) ||
        (fallback?.containsUnsupportedConditions() == true)
    }

}

#endif
