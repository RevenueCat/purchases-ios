//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageDefaultScopeView.swift
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

/// Resolves defaults within this container and applies them to the shared package context.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackageDefaultScopeView<Content: View>: View {
    @EnvironmentObject private var packageContext: PackageContext
    @EnvironmentObject private var introOfferEligibilityContext: IntroOfferEligibilityContext
    @EnvironmentObject private var paywallPromoOfferCache: PaywallPromoOfferCache
    @Environment(\.screenCondition) private var screenCondition
    @Environment(\.paywallWindowSize) private var windowSize
    @Environment(\.customPaywallVariables) private var customVariables
    @State private var didInitializeSelection = false
    let validator: PackageValidator
    let content: () -> Content

    private var selectionContext: PackageSelectionContext {
        .init(
            condition: screenCondition,
            customVariables: customVariables,
            windowSize: windowSize,
            isEligibleForIntroOffer: { introOfferEligibilityContext.isEligible(package: $0) },
            isEligibleForPromoOffer: { paywallPromoOfferCache.isMostLikelyEligible(for: $0) }
        )
    }

    var body: some View {
        let visibleIds = validator.visiblePackages(in: selectionContext).map(\.identifier)
        let defaultPackage = validator.defaultSelectedPackage(in: selectionContext)
        content()
            .environment(\.selectedPackageId, packageContext.package?.identifier)
            .environment(\.planSelectionDefaultPackage, defaultPackage)
            .onAppear {
                guard !didInitializeSelection else { return }
                didInitializeSelection = true
                validator.applyDefault(to: packageContext, in: selectionContext)
            }
            .onChangeOf(visibleIds) { _ in reconcileSelectedPackage() }
    }

    private func reconcileSelectedPackage() {
        guard packageContext.package.map({ validator.isRendering($0, in: selectionContext) }) != true else { return }
        validator.applyDefault(to: packageContext, in: selectionContext)
    }
}

#endif
