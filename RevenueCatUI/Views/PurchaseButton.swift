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

    let package: TemplateViewConfiguration.Package
    let colors: PaywallData.Configuration.Colors
    let fonts: PaywallFontProvider
    let introEligibility: IntroEligibilityStatus?
    let mode: PaywallViewMode

    @ObservedObject
    var purchaseHandler: PurchaseHandler

    init(
        package: TemplateViewConfiguration.Package,
        configuration: TemplateViewConfiguration,
        introEligibility: IntroEligibilityStatus?,
        purchaseHandler: PurchaseHandler
    ) {
        self.init(
            package: package,
            colors: configuration.colors,
            fonts: configuration.fonts,
            introEligibility: introEligibility,
            mode: configuration.mode,
            purchaseHandler: purchaseHandler
        )
    }

    init(
        package: TemplateViewConfiguration.Package,
        colors: PaywallData.Configuration.Colors,
        fonts: PaywallFontProvider,
        introEligibility: IntroEligibilityStatus?,
        mode: PaywallViewMode,
        purchaseHandler: PurchaseHandler
    ) {
        self.package = package
        self.colors = colors
        self.fonts = fonts
        self.introEligibility = introEligibility
        self.mode = mode
        self.purchaseHandler = purchaseHandler
    }

    var body: some View {
        self.button
    }

    private var button: some View {
        AsyncButton {
            guard !self.purchaseHandler.actionInProgress else { return }
            guard !self.package.currentlySubscribed else { return }

            _ = try await self.purchaseHandler.purchase(package: self.package.content)
        } label: {
            PurchaseButtonLabel(
                package: self.package,
                colors: self.colors,
                introEligibility: self.introEligibility,
                mode: self.mode
            )
        }
        .font(self.fonts.font(for: self.mode.buttonFont).weight(.semibold))
        .background(self.backgroundView)
        .tint(.clear)
        .frame(maxWidth: .infinity)
        .dynamicTypeSize(...Constants.maximumDynamicTypeSize)
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
private struct PurchaseButtonLabel: View {

    let package: TemplateViewConfiguration.Package
    let colors: PaywallData.Configuration.Colors
    let introEligibility: IntroEligibilityStatus?
    let mode: PaywallViewMode

    @Environment(\.userInterfaceIdiom)
    private var userInterfaceIdiom

    @Environment(\.isEnabled)
    private var isEnabled

    @Environment(\.redactionReasons.isEmpty)
    private var isNotRedacted

    var body: some View {
        IntroEligibilityStateView(
            textWithNoIntroOffer: self.package.localization.callToAction,
            textWithIntroOffer: self.package.localization.callToActionWithIntroOffer,
            introEligibility: self.introEligibility,
            foregroundColor: self.colors.callToActionForegroundColor
        )
            .frame(
                maxWidth: self.mode.fullWidthButton
                   ? .infinity
                    : nil
            )
            .padding()
            .padding(.vertical, self.userInterfaceIdiom == .pad ? 10 : 0)
            .hidden(if: !self.isEnabled)
            .overlay {
                if !self.isEnabled && self.isNotRedacted {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(self.colors.callToActionForegroundColor)
                }
            }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallViewMode {

    var buttonFont: Font.TextStyle {
        switch self {
        case .fullScreen, .footer, .condensedFooter: return .title3
        }
    }

    var fullWidthButton: Bool {
        switch self {
        case .fullScreen, .footer, .condensedFooter: return true
        }
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

        @State
        private var eligibility: IntroEligibilityStatus?

        @StateObject
        private var purchaseHandler = PreviewHelpers.purchaseHandler

        var body: some View {
            PurchaseButton(
                package: Self.package,
                colors: TestData.colors,
                fonts: DefaultPaywallFontProvider(),
                introEligibility: self.eligibility,
                mode: self.mode,
                purchaseHandler: self.purchaseHandler
            )
            // This is done by PaywallView
            .disabled(self.purchaseHandler.actionInProgress)
            .task {
                self.eligibility = await PreviewHelpers.introEligibilityChecker.eligibility(for: Self.package.content)
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
    }

    static var previews: some View {
        ForEach(PaywallViewMode.allCases, id: \.self) { mode in
            Preview(mode: mode)
                .previewLayout(.sizeThatFits)
        }
    }

}

#endif
