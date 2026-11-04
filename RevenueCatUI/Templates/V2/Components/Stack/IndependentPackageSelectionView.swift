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
    @Environment(\.offerEligibilityLoading) private var offerEligibilityLoading
    @Environment(\.offerEligibilityAvailability) private var offerEligibilityAvailability
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
            variableContext: .init(packages: validator.pagePackages)
        ))
    }

    private var selectionContext: PackageSelectionContext {
        .init(
            condition: self.screenCondition,
            customVariables: self.customVariables,
            windowSize: self.windowSize,
            isEligibleForIntroOffer: { self.introOfferEligibilityContext.isEligible(package: $0) },
            isEligibleForPromoOffer: { self.paywallPromoOfferCache.isMostLikelyEligible(for: $0) }
        )
    }

    var body: some View {
        let visibleIds = self.validator.visiblePackages(in: self.selectionContext).map(\.identifier)
        let defaultPackage = self.validator.defaultSelectedPackage(in: self.selectionContext)
        self.content()
            .environmentObject(self.selection)
            .environment(\.selectedPackageId, self.selection.package?.identifier)
            .environment(\.selectedPackageIsVisible, self.selection.package.map {
                self.validator.couldBeRendering(
                    $0,
                    in: self.selectionContext,
                    offerEligibilityLoading: self.offerEligibilityLoading,
                    offerEligibilityAvailability: self.offerEligibilityAvailability
                )
            } ?? false)
            .environment(\.planSelectionDefaultPackage, defaultPackage)
            .environment(\.independentPurchaseContext, true)
            .environment(\.workflowPackageContext, nil)
            .onAppear { self.reconcileSelectedPackage() }
            .onChangeOf(visibleIds) { _ in self.reconcileSelectedPackage() }
            .onChangeOf(self.offerEligibilityLoading) { _ in self.reconcileSelectedPackage() }
    }

    private func reconcileSelectedPackage() {
        let initializePageSelection = !self.didInitializeSelection && self.validator.hasPageScopedPackages
        self.didInitializeSelection = true
        let variableContext = PackageContext.VariableContext(
            packages: self.validator.pagePackages,
            showZeroDecimalPlacePrices: self.parentContext.variableContext.showZeroDecimalPlacePrices
        )
        guard initializePageSelection ||
                self.selection.package.map({
                    self.validator.couldBeRendering(
                        $0,
                        in: self.selectionContext,
                        offerEligibilityLoading: self.offerEligibilityLoading,
                        offerEligibilityAvailability: self.offerEligibilityAvailability
                    )
                }) != true else {
            self.selection.variableContext = variableContext
            return
        }
        self.selection.update(
            package: self.validator.defaultSelectedPackage(in: self.selectionContext),
            variableContext: variableContext,
            isReconcile: true
        )
    }

}

#endif
