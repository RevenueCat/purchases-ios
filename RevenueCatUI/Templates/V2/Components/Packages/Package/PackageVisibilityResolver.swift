//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageVisibilityResolver.swift
//
//  Created by Facundo Menzella on 8/6/26.

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) // For Paywalls V2

/// Resolves whether a package component is visible, running the same override pipeline for both the
/// renderer (`PackageComponentView`) and default-package selection (`PackageValidator`).
///
/// The factory adds containing stacks as their walks finish, so selection also excludes packages in
/// hidden containers. The package can still be recorded before its subtree is walked, preserving
/// document order without retaining the stack view models.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackageVisibilityResolver {

    private let componentVisible: Bool?
    private let uiConfigProvider: UIConfigProvider
    private let presentedOverrides: PresentedOverrides<PresentedPackagePartial>?
    private var ancestorStacks: [(visible: Bool?, overrides: PresentedOverrides<PresentedStackPartial>?)] = []
    private(set) var dependsOnOfferEligibility: Bool

    init(
        component: PaywallComponent.PackageComponent,
        uiConfigProvider: UIConfigProvider,
        discardRules: Bool
    ) {
        self.componentVisible = component.visible
        self.uiConfigProvider = uiConfigProvider
        let presentedOverrides = component.overrides?.toPresentedOverrides(discardRules: discardRules)
        self.presentedOverrides = presentedOverrides
        self.dependsOnOfferEligibility = presentedOverrides?.contains(where: \.dependsOnOfferEligibility) ?? false
    }

    mutating func addAncestorStack(_ component: PaywallComponent.StackComponent, discardRules: Bool) {
        let overrides = component.overrides?.toPresentedOverrides(discardRules: discardRules)
        self.ancestorStacks.append((component.visible, overrides))
        self.dependsOnOfferEligibility = self.dependsOnOfferEligibility
            || overrides?.contains(where: \.dependsOnOfferEligibility) == true
    }

    // swiftlint:disable:next function_parameter_count
    func visible(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        selectedPackageId: String?,
        customVariables: [String: CustomVariableValue],
        windowSize: CGSize? = nil
    ) -> Bool {
        let conditionContext = self.uiConfigProvider.conditionContext(
            selectedPackageId: selectedPackageId,
            customVariables: customVariables,
            windowSize: windowSize
        )

        let partial = PresentedPackagePartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            conditionContext: conditionContext,
            with: self.presentedOverrides
        )

        guard partial?.visible ?? self.componentVisible ?? true else { return false }
        return self.ancestorStacks.allSatisfy { ancestor in
            let partial = PresentedStackPartial.buildPartial(
                state: state,
                condition: condition,
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                conditionContext: conditionContext,
                with: ancestor.overrides
            )
            return partial?.visible ?? ancestor.visible ?? true
        }
    }

}

#endif
