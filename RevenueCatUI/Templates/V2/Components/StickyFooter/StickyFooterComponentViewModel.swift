//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StickyFooterComponentViewModel.swift
//
//  Created by Jay Shortway on 24/10/2024.

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class StickyFooterComponentViewModel {

    let component: PaywallComponent.StickyFooterComponent
    let stackViewModel: StackComponentViewModel
    let overrides: PresentedOverrides<PaywallComponent.PartialStickyFooterComponent>?

    init(
        component: PaywallComponent.StickyFooterComponent,
        stackViewModel: StackComponentViewModel,
        discardRules: Bool = false
    ) {
        self.component = component
        self.stackViewModel = stackViewModel
        self.overrides = component.overrides?.toPresentedOverrides(discardRules: discardRules)
    }

}

extension PaywallComponent.PartialStickyFooterComponent: PresentedPartial {
    static func combine(_ base: PaywallComponent.PartialStickyFooterComponent?,
                        with other: PaywallComponent.PartialStickyFooterComponent?)
    -> PaywallComponent.PartialStickyFooterComponent {
        .init(layout: other?.layout ?? base?.layout)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct FooterLayoutReader<Content: View>: View {
    @EnvironmentObject private var packageContext: PackageContext
    @EnvironmentObject private var introOfferEligibilityContext: IntroOfferEligibilityContext
    @EnvironmentObject private var paywallPromoOfferCache: PaywallPromoOfferCache
    @Environment(\.componentViewState) private var componentViewState
    @Environment(\.screenCondition) private var screenCondition
    @Environment(\.paywallWindowSize) private var windowSize
    @Environment(\.customPaywallVariables) private var customVariables
    @Environment(\.selectedPackageId) private var selectedPackageId
    @Environment(\.paywallStateValues) private var stateValues
    @Environment(\.paywallStateDefaults) private var stateDefaults

    let viewModel: StickyFooterComponentViewModel?
    @ViewBuilder var content: (PaywallComponent.StickyFooterComponent.Layout) -> Content

    var body: some View {
        let partial = PaywallComponent.PartialStickyFooterComponent.buildPartial(
            state: componentViewState,
            condition: screenCondition,
            isEligibleForIntroOffer: introOfferEligibilityContext.isEligible(package: packageContext.package),
            isEligibleForPromoOffer: paywallPromoOfferCache.isMostLikelyEligible(for: packageContext.package),
            conditionContext: viewModel?.stackViewModel.uiConfigProvider.conditionContext(
                selectedPackageId: selectedPackageId,
                customVariables: customVariables,
                stateValues: stateValues,
                stateDefaults: stateDefaults,
                windowSize: windowSize
            ) ?? ConditionContext(windowSize: windowSize),
            with: viewModel?.overrides
        )
        content(partial?.layout ?? viewModel?.component.layout ?? .normal)
    }
}

#endif
