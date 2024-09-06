//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/12/24.
//
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct PurchaseButtonComponent: PaywallComponentBase {

        let type: String
        let cta: PaywallComponent.LocalizationKey
        let ctaIntroOffer: PaywallComponent.LocalizationKey?

        public init(
            cta: PaywallComponent.LocalizationKey,
            ctaIntroOffer: PaywallComponent.LocalizationKey? = nil
        ) {
            self.type = "purchase_button"
            self.cta = cta
            self.ctaIntroOffer = ctaIntroOffer
        }

    }

}

#endif
