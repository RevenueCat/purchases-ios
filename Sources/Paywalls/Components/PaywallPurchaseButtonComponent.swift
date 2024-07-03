//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/12/24.
//

import Foundation

public extension PaywallComponent {
    struct PurchaseButtonComponent: PaywallComponentBase {

        let type: String
        let cta: LocaleResources<String>
        let ctaIntroOffer: LocaleResources<String>?
        public let displayPreferences: [DisplayPreference]?

        public init(
            cta: LocaleResources<String>,
            ctaIntroOffer: LocaleResources<String>? = nil,
            displayPreferences: [DisplayPreference]? = nil
        ) {
            self.type = "purchase_button"
            self.cta = cta
            self.ctaIntroOffer = ctaIntroOffer
            self.displayPreferences = displayPreferences
        }

        // TODO: This is random ID because this component is focusable
        public var focusIdentifiers: [FocusIdentifier]? = {
            return [UUID.init().uuidString]
        }()

    }
}
