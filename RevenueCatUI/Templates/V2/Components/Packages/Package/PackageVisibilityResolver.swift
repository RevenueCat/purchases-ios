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
/// It is built straight from the component, so it carries no dependency on the package's stack. That
/// lets the package be recorded for selection before its subtree is walked, keeping iOS's ordering
/// pre-order like Android's `StyleFactory.recordPackage`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackageVisibilityResolver {

    private let componentVisible: Bool?
    private let uiConfigProvider: UIConfigProvider
    private let presentedOverrides: PresentedOverrides<PresentedPackagePartial>?

    init(
        component: PaywallComponent.PackageComponent,
        uiConfigProvider: UIConfigProvider,
        discardRules: Bool
    ) {
        self.componentVisible = component.visible
        self.uiConfigProvider = uiConfigProvider
        self.presentedOverrides = component.overrides?.toPresentedOverrides(discardRules: discardRules)
    }

    // swiftlint:disable:next function_parameter_count
    func visible(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        selectedPackageId: String?,
        customVariables: [String: CustomVariableValue]
    ) -> Bool {
        let conditionContext = self.uiConfigProvider.conditionContext(
            selectedPackageId: selectedPackageId,
            customVariables: customVariables
        )

        let partial = PresentedPackagePartial.buildPartial(
            state: state,
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
