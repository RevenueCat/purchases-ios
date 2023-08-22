//
//  View+PresentPaywallFooter.swift
//  
//
//  Created by Josh Holtz on 8/18/23.
//

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
extension View {

    public func paywallFooter(
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        purchaseCompleted: PurchaseCompletedHandler? = nil
    ) -> some View {
        return self.paywallFooter(
            offering: nil,
            condensed: condensed,
            fonts: fonts,
            introEligibility: nil,
            purchaseCompleted: purchaseCompleted
        )
    }

    public func paywallFooter(
        offering: Offering,
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        purchaseCompleted: PurchaseCompletedHandler? = nil
    ) -> some View {
        return self.paywallFooter(
            offering: offering,
            condensed: condensed,
            fonts: fonts,
            introEligibility: nil,
            purchaseCompleted: purchaseCompleted
        )
    }

    func paywallFooter(
        offering: Offering?,
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        purchaseHandler: PurchaseHandler? = nil,
        purchaseCompleted: PurchaseCompletedHandler? = nil
    ) -> some View {
        return self
            .modifier(PresentingPaywallFooterModifier(
                offering: offering,
                condensed: condensed,
                purchaseCompleted: purchaseCompleted,
                fontProvider: fonts,
                introEligibility: introEligibility,
                purchaseHandler: purchaseHandler
            ))
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct PresentingPaywallFooterModifier: ViewModifier {

    let offering: Offering?
    let condensed: Bool

    let purchaseCompleted: PurchaseCompletedHandler?
    let fontProvider: PaywallFontProvider

    let introEligibility: TrialOrIntroEligibilityChecker?
    let purchaseHandler: PurchaseHandler?

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            PaywallFooterView(
                offering: self.offering,
                condensed: self.condensed,
                fonts: self.fontProvider,
                introEligibility: self.introEligibility ?? .default(),
                purchaseHandler: self.purchaseHandler ?? .default()
            )
            .onPurchaseCompleted {
                self.purchaseCompleted?($0)
            }
        }
    }
}
