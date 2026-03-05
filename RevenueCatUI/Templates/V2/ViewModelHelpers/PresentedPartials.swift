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

    /// Custom variables for condition evaluation (developer-provided merged with dashboard defaults).
    let customVariables: [String: CustomVariableValue]

    /// Creates a context with the given parameters.
    /// Developer-provided `customVariables` take priority over `defaultCustomVariables` from the dashboard.
    init(
        selectedPackageId: String? = nil,
        customVariables: [String: CustomVariableValue] = [:],
        defaultCustomVariables: [String: CustomVariableValue] = [:]
    ) {
        self.selectedPackageId = selectedPackageId
        self.customVariables = defaultCustomVariables.merging(customVariables) { _, developer in developer }
    }

}

extension PresentedPartial {

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

        // Offer eligibility (legacy simple boolean check)
        case .introOffer:
            return isEligibleForIntroOffer
        case .promoOffer:
            return isEligibleForPromoOffer

        // Offer eligibility (with operator/value)
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

        // Multiple intro offers - supported in Android, always evaluates to false on iOS
        case .multipleIntroOffers:
            return false

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
        // Type-strict comparison: the actual value must be of the same type as expected.
        switch expectedValue {
        case .string(let expected):
            guard actualValue.isString else { return false }
            return actualValue.stringValue == expected
        case .bool(let expected):
            guard actualValue.isBool else { return false }
            return actualValue.boolValue == expected
        case .int(let expected):
            guard actualValue.isNumber else { return false }
            return doublesMatch(actualValue.doubleValue, Double(expected))
        case .double(let expected):
            guard actualValue.isNumber else { return false }
            return doublesMatch(actualValue.doubleValue, expected)
        }
    }

    /// Compares two doubles using epsilon-based equality to handle floating point
    /// representation differences that can arise from JSON round-trips.
    private static func doublesMatch(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 1e-10
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

    /// Converts component overrides to presented overrides.
    ///
    /// When `discardRules` is true (because unsupported conditions were found anywhere in the paywall),
    /// all conditional configurability (rule-based) overrides are discarded globally and only legacy
    /// overrides are kept. This renders the "default paywall" — the same paywall template with only
    /// legacy overrides applied.
    func toPresentedOverrides<
        T: PaywallPartialComponent,
        P: PresentedPartial
    >(
        discardRules: Bool = false,
        convert: (T) throws -> P
    ) throws -> PresentedOverrides<P>
    where Element == PaywallComponent.ComponentOverride<T> {
        let overridesToProcess: Self
        if discardRules || self.hasUnsupportedCondition() {
            overridesToProcess = self.filter { override in
                override.extendedConditions.allSatisfy { !$0.isRule }
            }
        } else {
            overridesToProcess = self
        }

        return try overridesToProcess.compactMap { partial in
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

    // swiftlint:disable:next cyclomatic_complexity
    func containsUnsupportedConditions() -> Bool {
        switch self {
        case .text(let component):
            return component.overrides?.hasUnsupportedCondition() == true
        case .image(let component):
            return component.overrides?.hasUnsupportedCondition() == true
        case .icon(let component):
            return component.overrides?.hasUnsupportedCondition() == true
        case .video(let component):
            return component.overrides?.hasUnsupportedCondition() == true
        case .stack(let component):
            return component.containsUnsupportedConditions()
        case .button(let component):
            return component.stack.containsUnsupportedConditions()
        case .package(let component):
            return component.stack.containsUnsupportedConditions()
        case .purchaseButton(let component):
            return component.stack.containsUnsupportedConditions()
        case .stickyFooter(let component):
            return component.stack.containsUnsupportedConditions()
        case .timeline(let component):
            return component.containsUnsupportedConditions()
        case .tabs(let component):
            return component.containsUnsupportedConditions()
        case .tabControl:
            return false
        case .tabControlButton(let component):
            return component.stack.containsUnsupportedConditions()
        case .tabControlToggle:
            return false
        case .carousel(let component):
            return component.containsUnsupportedConditions()
        case .countdown(let component):
            return component.containsUnsupportedConditions()
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
