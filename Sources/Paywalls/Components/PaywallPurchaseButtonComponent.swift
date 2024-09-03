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
        let cta: LocalizationKey
        let ctaIntroOffer: LocalizationKey?

        public init(
            cta: LocalizationKey,
            ctaIntroOffer: LocalizationKey? = nil
        ) {
            self.type = "purchase_button"
            self.cta = cta
            self.ctaIntroOffer = ctaIntroOffer
        }

    }

}

#endif
