//
//  PurchaseButton.swift
//  
//
//  Created by Nacho Soto on 7/18/23.
//

import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct PurchaseButton: View {

    let package: Package
    let purchaseHandler: PurchaseHandler
    let colors: PaywallData.Configuration.Colors
    let localization: ProcessedLocalizedConfiguration
    let introEligibility: IntroEligibilityStatus?
    let mode: PaywallViewMode

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        self.button
    }

    private var button: some View {
        AsyncButton {
            let cancelled = try await self.purchaseHandler.purchase(package: self.package).userCancelled

            if !cancelled, case .fullScreen = self.mode {
                self.dismiss()
            }
        } label: {
            IntroEligibilityStateView(
                textWithNoIntroOffer: self.localization.callToAction,
                textWithIntroOffer: self.localization.callToActionWithIntroOffer,
                introEligibility: self.introEligibility,
                foregroundColor: self.colors.callToActionForegroundColor
            )
                .frame(
                    maxWidth: self.mode.fullWidthButton
                       ? .infinity
                        : nil
                )
        }
        .font(self.mode.buttonFont.weight(.semibold))
        .tint(self.colors.callToActionBackgroundColor.gradient)
        .buttonBorderShape(self.mode.buttonBorderShape)
        .controlSize(self.mode.buttonSize)
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension PaywallViewMode {

    var buttonFont: Font {
        switch self {
        case .fullScreen, .card: return .title2
        case .banner: return .footnote
        }
    }

    var fullWidthButton: Bool {
        switch self {
        case .fullScreen, .card: return true
        case .banner: return false
        }
    }

    var buttonSize: ControlSize {
        switch self {
        case .fullScreen: return .large
        case .card: return .regular
        case .banner: return .small
        }
    }

    var buttonBorderShape: ButtonBorderShape {
        switch self {
        case .fullScreen:
            #if os(macOS)
            return .roundedRectangle
            #else
            return .capsule
            #endif
        case .card, .banner:
            return .roundedRectangle
        }
    }

}

// MARK: - Previews

#if DEBUG && canImport(SwiftUI) && canImport(UIKit)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct PurchaseButton_Previews: PreviewProvider {

    private struct Preview: View {

        var mode: PaywallViewMode

        @State
        private var eligibility: IntroEligibilityStatus?

        var body: some View {
            PurchaseButton(
                package: Self.package,
                purchaseHandler: Self.purchaseHandler,
                colors: TestData.colors,
                localization: TestData.localization1.processVariables(with: Self.package, locale: .current),
                introEligibility: self.eligibility,
                mode: self.mode
            )
            .task {
                self.eligibility = await Self.eligibilityChecker.eligibility(for: Self.package)
            }
        }

        private static let package: Package = TestData.packageWithIntroOffer
        private static let eligibilityChecker: TrialOrIntroEligibilityChecker = .producing(eligibility: .eligible)
            .with(delay: .seconds(0.3))
        private static let purchaseHandler: PurchaseHandler = .mock()
            .with(delay: .seconds(0.5))

    }

    static var previews: some View {
        ForEach(Self.modes, id: \.self) { mode in
            Preview(mode: mode)
                .previewLayout(.sizeThatFits)
        }
    }

    private static let modes: [PaywallViewMode] = [
        .fullScreen
    ]

}

#endif
