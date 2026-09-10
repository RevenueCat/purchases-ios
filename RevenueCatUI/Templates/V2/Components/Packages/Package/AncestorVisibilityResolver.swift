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

/// Resolves whether a stack containing a package is visible, so selection can tell that a card is
/// off screen when the rule that hides it lives on a wrapper stack rather than on the card.
///
/// Known gap: only stacks join a chain, so a package inside a hidden carousel page, button stack or
/// countdown stack still counts as selectable.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct AncestorVisibilityResolver {

    private let componentVisible: Bool?
    private let uiConfigProvider: UIConfigProvider
    private let presentedOverrides: PresentedOverrides<PresentedStackPartial>?

    /// `nil` unless the stack can actually hide something, so a chain skips the many stacks whose
    /// overrides only carry styling. Checked before converting the overrides, which is the expensive
    /// part.
    init?(
        component: PaywallComponent.StackComponent,
        uiConfigProvider: UIConfigProvider,
        discardRules: Bool
    ) {
        let decidesVisibility = component.visible != nil
            || component.overrides?.contains { $0.properties.visible != nil } == true

        guard decidesVisibility else {
            return nil
        }

        self.componentVisible = component.visible
        self.uiConfigProvider = uiConfigProvider
        self.presentedOverrides = component.overrides?.toPresentedOverrides(discardRules: discardRules)
    }

    /// Offer eligibility is read for the candidate card, while the renderer resolves the stack once
    /// against whichever package is selected, so a stack gated on eligibility around a mix of
    /// eligible and ineligible cards is read per card here and as one unit on screen.
    func visible(package: Package, in context: PackageSelectionContext) -> Bool {
        let conditionContext = self.uiConfigProvider.conditionContext(
            selectedPackageId: nil,
            customVariables: context.customVariables,
            stateValues: context.stateValues,
            stateDefaults: context.stateDefaults,
            windowSize: context.windowSize
        )

        let partial = PresentedStackPartial.buildPartial(
            state: .default,
            condition: context.condition,
            isEligibleForIntroOffer: context.isEligibleForIntroOffer(package),
            isEligibleForPromoOffer: context.isEligibleForPromoOffer(package),
            conditionContext: conditionContext,
            with: self.presentedOverrides
        )

        return partial?.visible ?? self.componentVisible ?? true
    }

}

#endif
