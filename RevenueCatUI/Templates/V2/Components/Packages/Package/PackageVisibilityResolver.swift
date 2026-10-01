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

    /// The enclosing components that can hide this package. The rule hiding a package is usually on a
    /// container, not on the card. Empty for the renderer, which only draws a card its parents show.
    private let ancestors: [VisibilityGate]

    init(
        component: PaywallComponent.PackageComponent,
        uiConfigProvider: UIConfigProvider,
        discardRules: Bool,
        ancestors: [VisibilityGate] = []
    ) {
        self.componentVisible = component.visible
        self.uiConfigProvider = uiConfigProvider
        self.presentedOverrides = component.overrides?.toPresentedOverrides(discardRules: discardRules)
        self.ancestors = ancestors
    }

    // swiftlint:disable:next function_parameter_count
    func visible(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        selectedPackageId: String?,
        customVariables: [String: CustomVariableValue],
        windowSize: CGSize? = nil,
        stateValues: [String: PaywallComponent.ConditionValue] = [:],
        stateDefaults: [String: PaywallComponent.ConditionValue] = [:]
    ) -> Bool {
        let conditionContext = self.uiConfigProvider.conditionContext(
            selectedPackageId: selectedPackageId,
            customVariables: customVariables,
            stateValues: stateValues,
            stateDefaults: stateDefaults,
            windowSize: windowSize
        )

        let ancestorsVisible = self.ancestors.allSatisfy {
            $0.isVisible(
                condition: condition,
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                conditionContext: conditionContext
            )
        }

        guard ancestorsVisible else {
            return false
        }

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

/// One enclosing component's own visibility, type-erased so a package can hold the whole chain.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct VisibilityGate {

    private let resolve: (ScreenCondition, Bool, Bool, ConditionContext) -> Bool

    /// Nil when the component cannot hide anything, so a chain only holds real gates.
    init?<Partial: PaywallPartialComponent & PresentedPartial>(
        visible: Bool?,
        overrides: PaywallComponent.ComponentOverrides<Partial>?,
        visibleKeyPath: KeyPath<Partial, Bool?>,
        discardRules: Bool
    ) {
        guard visible != nil || overrides?.contains(where: { $0.properties[keyPath: visibleKeyPath] != nil }) == true
        else {
            return nil
        }

        let presentedOverrides = overrides?.toPresentedOverrides(discardRules: discardRules)

        self.resolve = { condition, isEligibleForIntroOffer, isEligibleForPromoOffer, conditionContext in
            let partial = Partial.buildPartial(
                // A container is never selected; only the package is.
                state: .default,
                condition: condition,
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                conditionContext: conditionContext,
                with: presentedOverrides
            )

            return partial?[keyPath: visibleKeyPath] ?? visible ?? true
        }
    }

    func isVisible(
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        conditionContext: ConditionContext
    ) -> Bool {
        return self.resolve(condition, isEligibleForIntroOffer, isEligibleForPromoOffer, conditionContext)
    }

}

#endif
