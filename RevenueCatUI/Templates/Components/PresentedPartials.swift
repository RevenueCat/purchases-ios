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
// swiftlint:disable missing_docs

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS

protocol PresentedPartial {

    static func combine(_ base: Self?, with other: Self?) -> Self

}

struct PresentedOverrides<T: PresentedPartial> {

    public let introOffer: T?
    public let states: PresentedStates<T>?
    public let conditions: PresentedConditions<T>?

}

struct PresentedStates<T: PresentedPartial> {

    let selected: T?

}

struct PresentedConditions<T: PresentedPartial> {

    let compact: T?
    let medium: T?
    let expanded: T?

}

extension PresentedPartial {

    static func buildPartial(
        state: ComponentViewState,
        condition: ScreenCondition,
        with presentedOverrides: PresentedOverrides<Self>?
    ) -> Self? {
        var partial = Self.buildConditionPartial(for: condition, with: presentedOverrides)

        switch state {
        case .default:
            break
        case .selected:
            partial = Self.combine(partial, with: presentedOverrides?.states?.selected)
        }

        // WIP: Get partial for intro offer
        return partial
    }

    private static func buildConditionPartial(
        for conditionType: ScreenCondition,
        with presentedOverrides: PresentedOverrides<Self>?
    ) -> Self? {

        // Get all conditions to include
        let conditionTypesToApply: [PaywallComponent.ComponentConditionsType]
        switch conditionType {
        case .compact:
            conditionTypesToApply = [.compact]
        case .medium:
            conditionTypesToApply = [.compact, .medium]
        case .expanded:
            conditionTypesToApply = [.compact, .medium, .expanded]
        }

        var combinedPartial: Self?

        // Apply compact on top of existing partial
        if let compact = presentedOverrides?.conditions?.compact,
           conditionTypesToApply.contains(.compact) {
            combinedPartial = Self.combine(combinedPartial, with: compact)
        }

        // Apply medium on top of existing partial
        if let medium = presentedOverrides?.conditions?.medium,
           conditionTypesToApply.contains(.medium) {
            combinedPartial = Self.combine(combinedPartial, with: medium)
        }

        // Apply expanded on top of existing partial
        if let expanded = presentedOverrides?.conditions?.expanded,
           conditionTypesToApply.contains(.expanded) {
            combinedPartial = Self.combine(combinedPartial, with: expanded)
        }

        // Return the combined partial if it's not empty, otherwise return nil
        return combinedPartial
    }

}

extension PaywallComponent.ComponentOverrides {

    func toPresentedOverrides<P: PresentedPartial>(convert: (T) -> P) -> PresentedOverrides<P> {
        PresentedOverrides(
            introOffer: self.introOffer.flatMap({ partial in
                convert(partial)
            }),
            states: self.states.flatMap({ states in
                PresentedStates(
                    selected: states.selected.flatMap({ partial in
                        convert(partial)
                    })
                )
            }),
            conditions: self.conditions.flatMap({ condition in
                PresentedConditions(
                    compact: condition.compact.flatMap({ partial in
                        convert(partial)
                    }),
                    medium: condition.medium.flatMap({ partial in
                        convert(partial)
                    }),
                    expanded: condition.expanded.flatMap({ partial in
                        convert(partial)
                    })
                )
            })
        )
    }

    func toPresentedOverrides<P: PresentedPartial>(convert: (T) throws -> P) throws -> PresentedOverrides<P> {
        PresentedOverrides(
            introOffer: try self.introOffer.flatMap({ partial in
                try convert(partial)
            }),
            states: try self.states.flatMap({ states in
                PresentedStates(
                    selected: try states.selected.flatMap({ partial in
                        try convert(partial)
                    })
                )
            }),
            conditions: try self.conditions.flatMap({ condition in
                PresentedConditions(
                    compact: try condition.compact.flatMap({ partial in
                        try convert(partial)
                    }),
                    medium: try condition.medium.flatMap({ partial in
                        try convert(partial)
                    }),
                    expanded: try condition.expanded.flatMap({ partial in
                        try convert(partial)
                    })
                )
            })
        )
    }

}

#endif
