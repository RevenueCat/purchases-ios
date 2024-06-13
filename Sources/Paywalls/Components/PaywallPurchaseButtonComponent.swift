//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/12/24.
//

import Foundation

public extension PaywallComponent {
    struct PurchaseButtonComponent: Decodable, Sendable, Hashable, Equatable {

        let type: String
        let cta: LocaleResources<String>
        let ctaIntroOffer: LocaleResources<String>?

        public init(cta: LocaleResources<String>, ctaIntroOffer: LocaleResources<String>? = nil) {
            self.type = "purchase_button"
            self.cta = cta
            self.ctaIntroOffer = ctaIntroOffer
        }

    }
}
