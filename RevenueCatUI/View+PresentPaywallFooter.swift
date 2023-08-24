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

    /// Presents a ``PaywallFooterView`` at the bottom of a view that loads the `Offerings.current`.
    /// ```swift
    /// var body: some View {
    ///    YourPaywall()
    ///      .paywallFooter()
    /// }
    /// ```
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    public func paywallFooter(
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        purchaseCompleted: PurchaseCompletedHandler? = nil
    ) -> some View {
        return self.paywallFooter(
            offering: nil,
            customerInfo: nil,
            condensed: condensed,
            fonts: fonts,
            introEligibility: nil,
            purchaseCompleted: purchaseCompleted
        )
    }

    /// Presents a ``PaywallFooterView`` at the bottom of a view with the given offering.
    /// ```swift
    /// var body: some View {
    ///    YourPaywall()
    ///      .paywallFooter(offering: offering)
    /// }
    /// ```
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    public func paywallFooter(
        offering: Offering,
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        purchaseCompleted: PurchaseCompletedHandler? = nil
    ) -> some View {
        return self.paywallFooter(
            offering: offering,
            customerInfo: nil,
            condensed: condensed,
            fonts: fonts,
            introEligibility: nil,
            purchaseCompleted: purchaseCompleted
        )
    }

    func paywallFooter(
        offering: Offering?,
        customerInfo: CustomerInfo?,
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        purchaseHandler: PurchaseHandler? = nil,
        purchaseCompleted: PurchaseCompletedHandler? = nil
    ) -> some View {
        return self
            .modifier(PresentingPaywallFooterModifier(
                offering: offering,
                customerInfo: customerInfo,
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
private struct PresentingPaywallFooterModifier: ViewModifier {

    let offering: Offering?
    let customerInfo: CustomerInfo?
    let condensed: Bool

    let purchaseCompleted: PurchaseCompletedHandler?
    let fontProvider: PaywallFontProvider
    let introEligibility: TrialOrIntroEligibilityChecker?
    let purchaseHandler: PurchaseHandler?

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                PaywallView(
                    offering: self.offering,
                    customerInfo: self.customerInfo,
                    mode: self.condensed ? .condensedFooter : .footer,
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
