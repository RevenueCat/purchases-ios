//
//  PurchaseButton.swift
//  
//
//  Created by Nacho Soto on 7/18/23.
//

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

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        self.button
    }

    private var button: some View {
        AsyncButton {
            guard !self.purchaseHandler.actionInProgress else { return }

            let cancelled = try await self.purchaseHandler.purchase(package: self.package.content,
                                                                    with: self.mode).userCancelled

            if !cancelled, case .fullScreen = self.mode {
                self.dismiss()
            }
        } label: {
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
        }
        .font(self.fonts.font(for: self.mode.buttonFont).weight(.semibold))
        .tint(self.colors.callToActionBackgroundColor)
        .buttonBorderShape(self.mode.buttonBorderShape)
        .controlSize(self.mode.buttonSize)
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .dynamicTypeSize(...Constants.maximumDynamicTypeSize)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallViewMode {

    var buttonFont: Font.TextStyle {
        switch self {
        case .fullScreen, .card, .condensedCard: return .title3
        }
    }

    var fullWidthButton: Bool {
        switch self {
        case .fullScreen, .card, .condensedCard: return true
        }
    }

    @available(tvOS, unavailable)
    var buttonSize: ControlSize {
        switch self {
        case .fullScreen, .card, .condensedCard: return .large
        }
    }

    var buttonBorderShape: ButtonBorderShape {
        switch self {
        case .fullScreen, .card, .condensedCard:
            #if os(macOS) || os(tvOS)
            return .roundedRectangle
            #else
            return .capsule
            #endif
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

        var body: some View {
            PurchaseButton(
                package: Self.package,
                colors: TestData.colors,
                fonts: DefaultPaywallFontProvider(),
                introEligibility: self.eligibility,
                mode: self.mode,
                purchaseHandler: PreviewHelpers.purchaseHandler
            )
            .task {
                self.eligibility = await PreviewHelpers.introEligibilityChecker.eligibility(for: Self.package.content)
            }
        }

        private static let package: TemplateViewConfiguration.Package = .init(
            content: TestData.packageWithIntroOffer,
            localization: TestData.localization1.processVariables(with: TestData.packageWithIntroOffer,
                                                                  locale: .current),
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
