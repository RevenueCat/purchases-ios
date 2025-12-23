//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  View+PresentPaywallFooter.swift
//
//  Created by Josh Holtz on 8/18/23.
//
// swiftlint:disable file_length

import RevenueCat
import SwiftUI

#if !os(watchOS) && !os(tvOS)

/// A closure used for notifying of changes to the current tier.
/// Useful when creating custom paywalls using `.paywallFooter`.
public typealias PaywallTierChangeHandler = @MainActor @Sendable (
    _ tier: PaywallData.Tier,
    _ localizedName: String
) -> Void

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension View {

    // swiftlint:disable line_length
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
    @available(iOS, deprecated: 1, renamed: "paywallFooter(condensed:fonts:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    @available(tvOS, deprecated: 1, renamed: "paywallFooter(condensed:fonts:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    @available(watchOS, deprecated: 1, renamed: "paywallFooter(condensed:fonts:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    @available(macOS, unavailable, message: "Legacy paywalls are unavailable in macOS")
    @available(macCatalyst, deprecated: 1, renamed: "paywallFooter(condensed:fonts:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    // swiftlint:enable line_length
    public func paywallFooter(
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        purchaseStarted: @escaping PurchaseStartedHandler,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseCancelled: PurchaseCancelledHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseFailure: PurchaseFailureHandler? = nil,
        restoreFailure: PurchaseFailureHandler? = nil
    ) -> some View {
        return self.paywallFooter(
            condensed: condensed,
            fonts: fonts,
            purchaseStarted: { _ in
                purchaseStarted()
            },
            purchaseCompleted: purchaseCompleted,
            purchaseCancelled: purchaseCancelled,
            restoreStarted: nil,
            restoreCompleted: restoreCompleted,
            purchaseFailure: purchaseFailure,
            restoreFailure: restoreFailure
        )
    }

    // swiftlint:disable line_length
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
    @available(iOS, deprecated: 1, renamed: "originalTemplatePaywallFooter(condensed:fonts:myAppPurchaseLogic:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    @available(tvOS, deprecated: 1, renamed: "originalTemplatePaywallFooter(condensed:fonts:myAppPurchaseLogic:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    @available(watchOS, deprecated: 1, renamed: "originalTemplatePaywallFooter(condensed:fonts:myAppPurchaseLogic:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    @available(macOS, unavailable, message: "Legacy paywalls are unavailable in macOS")
    @available(macCatalyst, deprecated: 1, renamed: "originalTemplatePaywallFooter(condensed:fonts:myAppPurchaseLogic:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    // swiftlint:enable line_length
    public func paywallFooter(
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        myAppPurchaseLogic: MyAppPurchaseLogic? = nil,
        purchaseStarted: PurchaseOfPackageStartedHandler? = nil,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseCancelled: PurchaseCancelledHandler? = nil,
        restoreStarted: RestoreStartedHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseFailure: PurchaseFailureHandler? = nil,
        restoreFailure: PurchaseFailureHandler? = nil
    ) -> some View {
        return self.originalTemplatePaywallFooter(
            condensed: condensed,
            fonts: fonts,
            myAppPurchaseLogic: myAppPurchaseLogic,
            purchaseStarted: purchaseStarted,
            purchaseCompleted: purchaseCompleted,
            purchaseCancelled: purchaseCancelled,
            restoreStarted: restoreStarted,
            restoreCompleted: restoreCompleted,
            purchaseFailure: purchaseFailure,
            restoreFailure: restoreFailure
        )
    }

    /// Presents a ``PaywallFooterView`` at the bottom of a view that loads the `Offerings.current`.
    /// If you are presenting a V1 paywall, this will show the footer of the template you selected.
    /// If you are presenting a V2 paywall, this will show a default footer since V2 paywalls
    /// don't have a footer representation.
    /// ```swift
    /// var body: some View {
    ///    YourPaywall()
    ///      .originalTemplatePaywallFooter()
    /// }
    /// ```
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    @available(macOS, unavailable, message: "Legacy paywalls are unavailable in macOS")
    public func originalTemplatePaywallFooter(
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        myAppPurchaseLogic: MyAppPurchaseLogic? = nil,
        purchaseStarted: PurchaseOfPackageStartedHandler? = nil,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseCancelled: PurchaseCancelledHandler? = nil,
        restoreStarted: RestoreStartedHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseFailure: PurchaseFailureHandler? = nil,
        restoreFailure: PurchaseFailureHandler? = nil
    ) -> some View {
        let purchaseHandler = PurchaseHandler.default(performPurchase: myAppPurchaseLogic?.performPurchase,
                                                      performRestore: myAppPurchaseLogic?.performRestore)
        return self.originalTemplatePaywallFooter(
            offering: nil,
            customerInfo: nil,
            condensed: condensed,
            fonts: fonts,
            introEligibility: nil,
            purchaseHandler: purchaseHandler,
            purchaseStarted: purchaseStarted,
            purchaseCompleted: purchaseCompleted,
            purchaseCancelled: purchaseCancelled,
            restoreStarted: restoreStarted,
            restoreCompleted: restoreCompleted,
            purchaseFailure: purchaseFailure,
            restoreFailure: restoreFailure
        )
    }

    // swiftlint:disable line_length
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
    @available(iOS, deprecated: 1, renamed: "paywallFooter(offering:condensed:fonts:myAppPurchaseLogic:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    @available(tvOS, deprecated: 1, renamed: "paywallFooter(offering:condensed:fonts:myAppPurchaseLogic:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    @available(watchOS, deprecated: 1, renamed: "paywallFooter(offering:condensed:fonts:myAppPurchaseLogic:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    @available(macOS, unavailable, message: "Legacy paywalls are unavailable in macOS")
    @available(macCatalyst, deprecated: 1, renamed: "paywallFooter(offering:condensed:fonts:myAppPurchaseLogic:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    // swiftlint:enable line_length
    @_disfavoredOverload
    public func paywallFooter(
        offering: Offering,
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        purchaseStarted: @escaping PurchaseStartedHandler,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseCancelled: PurchaseCancelledHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseFailure: PurchaseFailureHandler? = nil,
        restoreFailure: PurchaseFailureHandler? = nil
    ) -> some View {
        let purchaseHandler = PurchaseHandler.default()
        return self.originalTemplatePaywallFooter(
            offering: offering,
            customerInfo: nil,
            condensed: condensed,
            fonts: fonts,
            introEligibility: nil,
            purchaseHandler: purchaseHandler,
            purchaseStarted: { _ in
                purchaseStarted()
            },
            purchaseCompleted: purchaseCompleted,
            purchaseCancelled: purchaseCancelled,
            restoreStarted: nil,
            restoreCompleted: restoreCompleted,
            purchaseFailure: purchaseFailure,
            restoreFailure: restoreFailure
        )
    }

    // swiftlint:disable line_length
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
    @available(iOS, deprecated: 1, renamed: "originalTemplatePaywallFooter(offering:condensed:fonts:myAppPurchaseLogic:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    @available(tvOS, deprecated: 1, renamed: "originalTemplatePaywallFooter(offering:condensed:fonts:myAppPurchaseLogic:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    @available(watchOS, deprecated: 1, renamed: "originalTemplatePaywallFooter(offering:condensed:fonts:myAppPurchaseLogic:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    @available(macOS, unavailable, message: "Legacy paywalls are unavailable in macOS")
    @available(macCatalyst, deprecated: 1, renamed: "originalTemplatePaywallFooter(offering:condensed:fonts:myAppPurchaseLogic:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:)")
    // swiftlint:enable line_length
    public func paywallFooter(
        offering: Offering,
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        myAppPurchaseLogic: MyAppPurchaseLogic? = nil,
        purchaseStarted: PurchaseOfPackageStartedHandler? = nil,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseCancelled: PurchaseCancelledHandler? = nil,
        restoreStarted: RestoreStartedHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseFailure: PurchaseFailureHandler? = nil,
        restoreFailure: PurchaseFailureHandler? = nil
    ) -> some View {
        return self.originalTemplatePaywallFooter(
            offering: offering,
            condensed: condensed,
            fonts: fonts,
            myAppPurchaseLogic: myAppPurchaseLogic,
            purchaseStarted: purchaseStarted,
            purchaseCompleted: purchaseCompleted,
            purchaseCancelled: purchaseCancelled,
            restoreStarted: restoreStarted,
            restoreCompleted: restoreCompleted,
            purchaseFailure: purchaseFailure,
            restoreFailure: restoreFailure
        )
    }

    /// Presents a ``PaywallFooterView`` at the bottom of a view with the given offering.
    /// If you are presenting a V1 paywall, this will show the footer of the template you selected.
    /// If you are presenting a V2 paywall, this will show a default footer since V2 paywalls
    /// don't have a footer representation.
    /// ```swift
    /// var body: some View {
    ///    YourPaywall()
    ///      .originalTemplatePaywallFooter(offering: offering)
    /// }
    /// ```
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    @available(macOS, unavailable, message: "Legacy paywalls are unavailable in macOS")
    public func originalTemplatePaywallFooter(
        offering: Offering,
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        myAppPurchaseLogic: MyAppPurchaseLogic? = nil,
        purchaseStarted: PurchaseOfPackageStartedHandler? = nil,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseCancelled: PurchaseCancelledHandler? = nil,
        restoreStarted: RestoreStartedHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseFailure: PurchaseFailureHandler? = nil,
        restoreFailure: PurchaseFailureHandler? = nil
    ) -> some View {
        let purchaseHandler = PurchaseHandler.default(performPurchase: myAppPurchaseLogic?.performPurchase,
                                                      performRestore: myAppPurchaseLogic?.performRestore)
        return self.originalTemplatePaywallFooter(
            offering: offering,
            customerInfo: nil,
            condensed: condensed,
            fonts: fonts,
            introEligibility: nil,
            purchaseHandler: purchaseHandler,
            purchaseStarted: purchaseStarted,
            purchaseCompleted: purchaseCompleted,
            purchaseCancelled: purchaseCancelled,
            restoreStarted: restoreStarted,
            restoreCompleted: restoreCompleted,
            purchaseFailure: purchaseFailure,
            restoreFailure: restoreFailure
        )
    }

    @available(macOS, unavailable, message: "Legacy paywalls are unavailable in macOS")
    func originalTemplatePaywallFooter(
        offering: Offering?,
        customerInfo: CustomerInfo?,
        condensed: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        purchaseHandler: PurchaseHandler,
        purchaseStarted: PurchaseOfPackageStartedHandler? = nil,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseCancelled: PurchaseCancelledHandler? = nil,
        restoreStarted: RestoreStartedHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseFailure: PurchaseFailureHandler? = nil,
        restoreFailure: PurchaseFailureHandler? = nil
    ) -> some View {
        return self
            .modifier(
                PresentingPaywallFooterModifier(
                    configuration: .init(
                        content: .optionalOffering(offering),
                        customerInfo: customerInfo,
                        mode: condensed ? .condensedFooter : .footer,
                        fonts: fonts,
                        displayCloseButton: false,
                        introEligibility: introEligibility,
                        purchaseHandler: purchaseHandler
                    ),
                    purchaseStarted: purchaseStarted,
                    purchaseCompleted: purchaseCompleted,
                    purchaseCancelled: purchaseCancelled,
                    purchaseFailure: purchaseFailure,
                    restoreStarted: restoreStarted,
                    restoreCompleted: restoreCompleted,
                    restoreFailure: restoreFailure
                )
            )
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension View {

    /// Invokes the given closure when the user selects a `PaywallData.Tier` in a multi-tier paywall.
    public func onPaywallTierChange(_ handler: @escaping PaywallTierChangeHandler) -> some View {
        self
            .modifier(PaywallTierChangeModifier(handler: handler))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct PresentingPaywallFooterModifier: ViewModifier {

    let configuration: PaywallViewConfiguration

    let purchaseStarted: PurchaseOfPackageStartedHandler?
    let purchaseCompleted: PurchaseOrRestoreCompletedHandler?
    let purchaseCancelled: PurchaseCancelledHandler?
    let purchaseFailure: PurchaseFailureHandler?

    let restoreStarted: RestoreStartedHandler?
    let restoreCompleted: PurchaseOrRestoreCompletedHandler?
    let restoreFailure: PurchaseFailureHandler?

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                PaywallView(configuration: self.configuration)
                    .onPurchaseStarted {
                        self.purchaseStarted?($0)
                    }
                    .onPurchaseCompleted {
                        self.purchaseCompleted?($0)
                    }
                    .onPurchaseCancelled {
                        self.purchaseCancelled?()
                    }
                    .onRestoreCompleted {
                        self.restoreCompleted?($0)
                    }
                    .onPurchaseFailure {
                        self.purchaseFailure?($0)
                    }
                    .onRestoreStarted {
                        self.restoreStarted?()
                    }
                    .onRestoreFailure {
                        self.restoreFailure?($0)
                    }
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallTierChangeModifier: ViewModifier {

    let handler: PaywallTierChangeHandler

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(PaywallCurrentTierPreferenceKey.self) { data in
                if let data {
                    self.handler(data.tier, data.localizedName)
                }
            }
    }

}

#endif
