//
//  PaywallLinkButtonComponent.swift
//
//
//  Created by James Borthwick on 2024-08-21.
//

import Foundation


#if PAYWALL_COMPONENTS

public extension PaywallComponent {
    
    struct LinkButtonComponent: PaywallComponentBase {

        let type: String
        public let url: URL
        public let textComponent: PaywallComponent.TextComponent

        public init(
            url: URL,
            textComponent: PaywallComponent.TextComponent
        ) {
            self.type = "link_button"
            self.url = url
            self.textComponent = textComponent
        }

    }

}

#endif
