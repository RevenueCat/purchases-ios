//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseButton.swift
//  
//  Created by Nacho Soto on 7/18/23.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(tvOS, unavailable)
struct PurchaseButton: View {

    let packages: TemplateViewConfiguration.PackageConfiguration
    let selectedPackage: TemplateViewConfiguration.Package
    let colors: PaywallData.Configuration.Colors
    let fonts: PaywallFontProvider
    let mode: PaywallViewMode

    @EnvironmentObject
    private var introEligibilityViewModel: IntroEligibilityViewModel
    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler
    @Environment(\.isEnabled)
    private var isEnabled

    init(
        packages: TemplateViewConfiguration.PackageConfiguration,
        selectedPackage: TemplateViewConfiguration.Package,
        configuration: TemplateViewConfiguration
    ) {
        self.init(
            packages: packages,
            selectedPackage: selectedPackage,
            colors: configuration.colors,
            fonts: configuration.fonts,
            mode: configuration.mode
        )
    }

    init(
        packages: TemplateViewConfiguration.PackageConfiguration,
        selectedPackage: TemplateViewConfiguration.Package,
        colors: PaywallData.Configuration.Colors,
        fonts: PaywallFontProvider,
        mode: PaywallViewMode
    ) {
        self.packages = packages
        self.selectedPackage = selectedPackage
        self.colors = colors
        self.fonts = fonts
        self.mode = mode
    }

    var body: some View {
        self.button
    }

    private var button: some View {
        AsyncButton {
            guard !self.purchaseHandler.actionInProgress else { return }
            guard !self.selectedPackage.currentlySubscribed else { return }

            _ = try await self.purchaseHandler.purchase(package: self.selectedPackage.content)
        } label: {
            ConsistentPackageContentView(
                packages: self.packages.all,
                selected: self.selectedPackage
            ) { package in
                PurchaseButtonLabel(
                    package: package,
                    colors: self.colors,
                    introEligibility: self.introEligibilityViewModel.allEligibility[package.content]
                )
            }
            .frame(maxWidth: .infinity)
            .padding()
            .hidden(if: !self.isEnabled)
            .overlay {
                if !self.isEnabled {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(self.colors.callToActionForegroundColor)
                }
            }
        }
        .font(self.fonts.font(for: .title3).weight(.semibold))
        .background(self.backgroundView)
        .tint(.clear)
        .frame(maxWidth: .infinity)
        .dynamicTypeSize(...Constants.maximumDynamicTypeSize)
        .transaction { transaction in
            if !self.packagesProduceDifferentLabels {
                transaction.animation = nil
            }
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        Capsule(style: .continuous)
            .foregroundStyle(self.backgroundColor)
    }

    private var backgroundColor: some ShapeStyle {
        let primary = self.colors.callToActionBackgroundColor

        if let secondary = self.colors.callToActionSecondaryBackgroundColor {
            return AnyShapeStyle(
                LinearGradient(colors: [primary, secondary],
                               startPoint: .top,
                               endPoint: .bottom)
            )
        } else {
            return AnyShapeStyle(primary)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(tvOS, unavailable)
private extension PurchaseButton {

    var packagesProduceDifferentLabels: Bool {
        return Set(
            self.packages.all
                .lazy
                .map {
                    IntroEligibilityStateView.text(
                        for: .callToAction,
                        localization: $0.localization,
                        introEligibility: self.introEligibilityViewModel.allEligibility[$0.content]
                    )
                }
        )
        .count > 1
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct PurchaseButtonLabel: View {

    let package: TemplateViewConfiguration.Package
    let colors: PaywallData.Configuration.Colors
    let introEligibility: IntroEligibilityStatus?

    var body: some View {
        IntroEligibilityStateView(
            display: .callToAction,
            localization: self.package.localization,
            introEligibility: self.introEligibility,
            foregroundColor: self.colors.callToActionForegroundColor
        )
    }

}

// MARK: - Previews

#if DEBUG && canImport(SwiftUI) && canImport(UIKit)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
struct PurchaseButton_Previews: PreviewProvider {

    @MainActor
    private struct Preview: View {

        var mode: PaywallViewMode

        @StateObject
        private var purchaseHandler = PreviewHelpers.purchaseHandler

        @StateObject
        private var eligibility = IntroEligibilityViewModel(
            introEligibilityChecker: PreviewHelpers.introEligibilityChecker
        )

        var body: some View {
            PurchaseButton(
                packages: Self.packages,
                selectedPackage: Self.package,
                colors: TestData.colors,
                fonts: DefaultPaywallFontProvider(),
                mode: self.mode
            )
            .environmentObject(self.purchaseHandler)
            .environmentObject(self.eligibility)
            // This is done by PaywallView
            .disabled(self.purchaseHandler.actionInProgress)
            .task {
                await self.eligibility.computeEligibility(for: Self.packages)
            }
        }

        private static let package: TemplateViewConfiguration.Package = .init(
            content: TestData.packageWithIntroOffer,
            localization: TestData.localization1.processVariables(
                with: TestData.packageWithIntroOffer,
                context: .init(discountRelativeToMostExpensivePerMonth: nil),
                locale: .current
            ),
            currentlySubscribed: false,
            discountRelativeToMostExpensivePerMonth: nil
        )
        private static let packages: TemplateViewConfiguration.PackageConfiguration = .single(Self.package)
    }

    static var previews: some View {
        ForEach(PaywallViewMode.allCases, id: \.self) { mode in
            Preview(mode: mode)
                .previewLayout(.sizeThatFits)
        }
    }

}

#endif
