//
//  PaywallViewConfiguration.swift
//
//
//  Created by Nacho Soto on 1/19/24.
//

import Foundation

import RevenueCat

/// Parameters needed to configure a ``PaywallView``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// @PublicForExternalTesting
struct PaywallViewConfiguration {

    var content: Content
    var customerInfo: CustomerInfo?
    var mode: PaywallViewMode
    var fonts: PaywallFontProvider
    var displayCloseButton: Bool
    var introEligibility: TrialOrIntroEligibilityChecker?
    var purchaseHandler: PurchaseHandler
    var locale: Locale

    init(
        content: Content,
        customerInfo: CustomerInfo? = nil,
        mode: PaywallViewMode = .default,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false,
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        purchaseHandler: PurchaseHandler,
        locale: Locale = .current
    ) {
        self.content = content
        self.customerInfo = customerInfo
        self.mode = mode
        self.fonts = fonts
        self.displayCloseButton = displayCloseButton
        self.introEligibility = introEligibility
        self.purchaseHandler = purchaseHandler
        self.locale = locale
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallViewConfiguration {

    /// Offering selection for the paywall.
    // @PublicForExternalTesting
    enum Content {

        case defaultOffering
        case offering(Offering)
        case offeringIdentifier(String)

    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallViewConfiguration {

    // @PublicForExternalTesting
    init(
        offering: Offering? = nil,
        customerInfo: CustomerInfo? = nil,
        mode: PaywallViewMode = .default,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false,
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        purchaseHandler: PurchaseHandler = PurchaseHandler.default(),
        locale: Locale = .current
    ) {
        let handler = purchaseHandler

        self.init(
            content: .optionalOffering(offering),
            customerInfo: customerInfo,
            mode: mode,
            fonts: fonts,
            displayCloseButton: displayCloseButton,
            introEligibility: introEligibility,
            purchaseHandler: handler,
            locale: locale
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallViewConfiguration.Content {

    /// - Returns: `Content.offering` or `Content.defaultOffering` if `nil`.
    static func optionalOffering(_ offering: Offering?) -> Self {
        return offering.map(Self.offering) ?? .defaultOffering
    }

}
