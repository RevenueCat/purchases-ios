//
//  PaywallFooterView.swift
//  
//
//  Created by Josh Holtz on 8/21/23.
//

import RevenueCat
import SwiftUI

/// A SwiftUI view for displaying a `PaywallData` for an `Offering`.
///
/// ### Related Articles
/// [Documentation](https://rev.cat/paywalls)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(watchOS, unavailable, message: "RevenueCatUI does not support watchOS yet")
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
@available(macCatalyst, unavailable, message: "RevenueCatUI does not support Catalyst yet")
internal struct PaywallFooterView: View {

    private let condensed: Bool
    private let fonts: PaywallFontProvider
    private let introEligibility: TrialOrIntroEligibilityChecker?
    private let purchaseHandler: PurchaseHandler?

    private var offering: Offering?

    /// Create a view that loads the `Offerings.current`.
    /// - Note: If loading the current `Offering` fails (if the user is offline, for example),
    /// an error will be displayed.
    /// - Warning: `Purchases` must have been configured prior to displaying it.
    /// If you want to handle that, you can use ``init(offering:mode:)`` instead.
    init(
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider()
    ) {
        self.init(
            offering: nil,
            condensed: condensed,
            fonts: fonts,
            introEligibility: .default(),
            purchaseHandler: .default()
        )
    }

    /// Create a view for the given `Offering`.
    /// - Note: if `offering` does not have a current paywall, or it fails to load due to invalid data,
    /// a default paywall will be displayed.
    /// - Warning: `Purchases` must have been configured prior to displaying it.
    init(
        offering: Offering,
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider()
    ) {
        self.init(
            offering: offering,
            condensed: condensed,
            fonts: fonts,
            introEligibility: .default(),
            purchaseHandler: .default()
        )
    }

    internal init(
        offering: Offering?,
        condensed: Bool,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        introEligibility: TrialOrIntroEligibilityChecker?,
        purchaseHandler: PurchaseHandler?
    ) {
        self.offering = offering
        self.introEligibility = introEligibility
        self.purchaseHandler = purchaseHandler
        self.condensed = condensed
        self.fonts = fonts
    }

    var body: some View {
        PaywallView(
            offering: self.offering,
            mode: self.condensed ? .condensedFooter : .footer,
            fonts: self.fonts,
            introEligibility: self.introEligibility,
            purchaseHandler: self.purchaseHandler
        )
    }

}
