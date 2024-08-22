//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/12/24.
//

import Foundation
// swiftlint:disable all

#if PAYWALL_COMPONENTS

public extension PaywallComponent {
    struct PurchaseButtonComponent: PaywallComponentBase {

        let type: String
        let cta: LocaleResources<String>
        let ctaIntroOffer: LocaleResources<String>?

        public init(
            cta: LocaleResources<String>,
            ctaIntroOffer: LocaleResources<String>? = nil
        ) {
            self.type = "purchase_button"
            self.cta = cta
            self.ctaIntroOffer = ctaIntroOffer
        }

    }
}

#endif
