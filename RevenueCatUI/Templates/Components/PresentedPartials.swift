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

#if PAYWALL_COMPONENTS

/// Protocol defining how partial components can be combined
protocol PresentedPartial {

    /// Combines two partial components, allowing for override behavior
    /// - Parameters:
    ///   - base: The base partial component
    ///   - other: The overriding partial component
    /// - Returns: Combined partial component
    static func combine(_ base: Self?, with other: Self?) -> Self

}

/// Structure holding override configurations for different presentation states
struct PresentedOverrides<T: PresentedPartial> {

    /// Override for intro offer state
    public let introOffer: T?
    /// Override for different selection states
    public let states: PresentedStates<T>?
    /// Override for different screen size conditions
    public let conditions: PresentedConditions<T>?

}

/// Structure defining states for selected/unselected components
struct PresentedStates<T: PresentedPartial> {

    /// Override for selected state
    let selected: T?

}

/// Structure defining overrides for different screen size conditions
struct PresentedConditions<T: PresentedPartial> {

    /// Override for compact size
    let compact: T?
    /// Override for medium size
    let medium: T?
    /// Override for expanded size
    let expanded: T?

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
        with presentedOverrides: PresentedOverrides<Self>?
    ) -> Self? {
        var conditionPartial = buildConditionPartial(for: condition, with: presentedOverrides)

        if isEligibleForIntroOffer {
            conditionPartial = Self.combine(conditionPartial, with: presentedOverrides?.introOffer)
        }

        switch state {
        case .default:
            break
        case .selected:
            conditionPartial = Self.combine(conditionPartial, with: presentedOverrides?.states?.selected)
        }

        return conditionPartial
    }

    /// Builds a partial component based on screen conditions
    /// - Parameters:
    ///   - conditionType: Screen size condition
    ///   - presentedOverrides: Override configurations to apply
    /// - Returns: Configured partial component for the given condition
    private static func buildConditionPartial(
        for conditionType: ScreenCondition,
        with presentedOverrides: PresentedOverrides<Self>?
    ) -> Self? {
        let conditions = presentedOverrides?.conditions
        let applicableConditions = conditionType.applicableConditions
            .compactMap { type -> Self? in
                switch type {
                case .compact: return conditions?.compact
                case .medium: return conditions?.medium
                case .expanded: return conditions?.expanded
                }
            }

        return applicableConditions.reduce(nil) { partial, next in
            Self.combine(partial, with: next)
        }
    }

}

private extension ScreenCondition {

    /// Returns applicable condition types based on current screen condition
    var applicableConditions: [PaywallComponent.ComponentConditionsType] {
        switch self {
        case .compact: return [.compact]
        case .medium: return [.compact, .medium]
        case .expanded: return [.compact, .medium, .expanded]
        }
    }

}

extension PaywallComponent.ComponentOverrides {

    /// Maps a partial component using a conversion function
    /// - Parameters:
    ///   - partial: Source partial component
    ///   - convert: Conversion function to apply
    /// - Returns: Converted partial component
    private func mapPartial<P: PresentedPartial>(
        _ partial: T?,
        using convert: (T) throws -> P
    ) throws -> P? {
        try partial.flatMap(convert)
    }

    /// Converts component overrides to presented overrides
    /// - Parameter convert: Conversion function to apply
    /// - Returns: Presented overrides with converted components
    func toPresentedOverrides<P: PresentedPartial>(convert: (T) throws -> P) throws -> PresentedOverrides<P> {
        PresentedOverrides(
            introOffer: try mapPartial(self.introOffer, using: convert),
            states: try self.states.flatMap { states in
                PresentedStates(
                    selected: try mapPartial(states.selected, using: convert)
                )
            },
            conditions: try self.conditions.flatMap { condition in
                PresentedConditions(
                    compact: try mapPartial(condition.compact, using: convert),
                    medium: try mapPartial(condition.medium, using: convert),
                    expanded: try mapPartial(condition.expanded, using: convert)
                )
            }
        )
    }

}

#endif
