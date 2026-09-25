//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IndependentPackageSelectionView.swift
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

/// Owns selection for one independent stack while inheriting the surrounding paywall environment.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct IndependentPackageSelectionView<Content: View>: View {
    @EnvironmentObject private var parentContext: PackageContext
    @EnvironmentObject private var introOfferEligibilityContext: IntroOfferEligibilityContext
    @EnvironmentObject private var paywallPromoOfferCache: PaywallPromoOfferCache
    @Environment(\.screenCondition) private var screenCondition
    @Environment(\.paywallWindowSize) private var windowSize
    @Environment(\.customPaywallVariables) private var customVariables
    @StateObject private var selection: PackageContext
    @State private var didInitializeSelection = false
    let validator: PackageValidator
    let content: () -> Content

    init(
        validator: PackageValidator,
        selection: PackageContext?,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.validator = validator
        self.content = content
        self._selection = StateObject(wrappedValue: selection ?? PackageContext(
            package: validator.defaultSelectedPackage(in: .provisional),
            variableContext: .init(packages: validator.packageInfos.map(\.package))
        ))
    }

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
            .environmentObject(selection)
            .environment(\.selectedPackageId, selection.package?.identifier)
            .environment(\.planSelectionDefaultPackage, defaultPackage)
            .environment(\.workflowPackageContext, nil)
            .onAppear { reconcileSelectedPackage() }
            .onChangeOf(visibleIds) { _ in reconcileSelectedPackage() }
    }

    private func reconcileSelectedPackage() {
        let initializePageSelection = !didInitializeSelection && validator.hasPageScopedPackages
        didInitializeSelection = true
        let variableContext = PackageContext.VariableContext(
            packages: validator.packageInfos.map(\.package),
            showZeroDecimalPlacePrices: parentContext.variableContext.showZeroDecimalPlacePrices
        )
        guard initializePageSelection ||
                selection.package.map({ validator.isRendering($0, in: selectionContext) }) != true else {
            selection.variableContext = variableContext
            return
        }
        selection.update(
            package: validator.defaultSelectedPackage(in: selectionContext),
            variableContext: variableContext,
            isReconcile: true
        )
    }
}

#endif
