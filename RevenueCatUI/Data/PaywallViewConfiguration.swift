//
//  PaywallViewConfiguration.swift
//
//
//  Created by Nacho Soto on 1/19/24.
//

import Foundation

@_spi(Internal) import RevenueCat

/// Parameters needed to configure a ``PaywallView``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallViewConfiguration {

    var content: Content
    var customerInfo: CustomerInfo?
    var mode: PaywallViewMode
    var fonts: PaywallFontProvider

    /// This is a configuration value that is for V1 paywalls and the fallback paywall. V2 paywalls
    /// can have their own close buttons configured via the dashboard, so it's not used by the
    /// PaywallsV2View success path.
    var displayCloseButton: Bool
    let useDraftPaywall: Bool
    var introEligibility: TrialOrIntroEligibilityChecker?
    var purchaseHandler: PurchaseHandler
    var promoOfferCache: PaywallPromoOfferCache?

    init(
        content: Content,
        customerInfo: CustomerInfo? = nil,
        mode: PaywallViewMode = .default,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false,
        useDraftPaywall: Bool = false,
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        purchaseHandler: PurchaseHandler,
        promoOfferCache: PaywallPromoOfferCache? = nil
    ) {
        self.content = content
        self.customerInfo = customerInfo
        self.mode = mode
        self.fonts = fonts
        self.displayCloseButton = displayCloseButton
        self.useDraftPaywall = useDraftPaywall
        self.introEligibility = introEligibility
        self.purchaseHandler = purchaseHandler
        self.promoOfferCache = promoOfferCache
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallViewConfiguration {

    /// Offering selection for the paywall.
    enum Content {

        case defaultOffering
        case offering(Offering)
        case offeringIdentifier(String, presentedOfferingContext: PresentedOfferingContext?)

    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallViewConfiguration {

    init(
        offering: Offering? = nil,
        customerInfo: CustomerInfo? = nil,
        mode: PaywallViewMode = .default,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false,
        useDraftPaywall: Bool = false,
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        purchaseHandler: PurchaseHandler = PurchaseHandler.default(),
        promoOfferCache: PaywallPromoOfferCache? = nil
    ) {
        let handler = purchaseHandler

        self.init(
            content: .optionalOffering(offering),
            customerInfo: customerInfo,
            mode: mode,
            fonts: fonts,
            displayCloseButton: displayCloseButton,
            useDraftPaywall: useDraftPaywall,
            introEligibility: introEligibility,
            purchaseHandler: handler,
            promoOfferCache: promoOfferCache
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
