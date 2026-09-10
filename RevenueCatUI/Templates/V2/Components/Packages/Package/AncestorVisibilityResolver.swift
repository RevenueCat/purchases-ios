//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AncestorVisibilityResolver.swift
//
//  Created by Facundo Menzella on 9/10/26.

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) // For Paywalls V2

/// Resolves whether a stack containing a package is visible.
///
/// A package card is often not the thing a rule hides. Grouping each tier's cards in a stack and
/// showing one stack at a time with a "Selected tab" rule puts the rule on the stack, and the cards
/// below it carry none of their own. Selection has to see that stack, or it picks a package the
/// paywall never renders.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct AncestorVisibilityResolver {

    private let componentVisible: Bool?
    private let uiConfigProvider: UIConfigProvider
    private let presentedOverrides: PresentedOverrides<PresentedStackPartial>?

    /// `nil` when the stack can never hide anything, so an ancestor chain only carries the stacks
    /// that actually decide something.
    init?(
        component: PaywallComponent.StackComponent,
        uiConfigProvider: UIConfigProvider,
        discardRules: Bool
    ) {
        let overrides = component.overrides?.toPresentedOverrides(discardRules: discardRules)

        guard component.visible != nil || !(overrides?.isEmpty ?? true) else {
            return nil
        }

        self.componentVisible = component.visible
        self.uiConfigProvider = uiConfigProvider
        self.presentedOverrides = overrides
    }

    /// Resolved with nothing selected, because this runs while the selection is still being worked
    /// out. An ancestor rule keyed on the selected package therefore reads as "not matching" here,
    /// which is the same pin the card's own resolution uses and carries the same limitation: such a
    /// stack is treated as hidden for selection even when the rendered paywall shows it.
    // swiftlint:disable:next function_parameter_count
    func visible(
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        customVariables: [String: CustomVariableValue],
        windowSize: CGSize?,
        stateValues: [String: PaywallComponent.ConditionValue],
        stateDefaults: [String: PaywallComponent.ConditionValue]
    ) -> Bool {
        let conditionContext = self.uiConfigProvider.conditionContext(
            selectedPackageId: nil,
            customVariables: customVariables,
            stateValues: stateValues,
            stateDefaults: stateDefaults,
            windowSize: windowSize
        )

        let partial = PresentedStackPartial.buildPartial(
            state: .default,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            conditionContext: conditionContext,
            with: self.presentedOverrides
        )

        return partial?.visible ?? self.componentVisible ?? true
    }

}

#endif
