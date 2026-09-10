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

/// Whether a stack containing a package is visible, so selection can tell a card is off screen when
/// the rule hiding it is on a wrapper stack. Only stacks count: a hidden carousel page does not.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct AncestorVisibilityResolver {

    private let componentVisible: Bool?
    private let uiConfigProvider: UIConfigProvider
    private let presentedOverrides: PresentedOverrides<PresentedStackPartial>?

    /// `nil` unless the stack can actually hide something, so a chain skips stacks whose overrides
    /// only carry styling. Checked before converting the overrides, which is the expensive part.
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

    /// Eligibility is read per candidate card here, but once per stack on screen, so the two can
    /// disagree for a stack gated on eligibility.
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
