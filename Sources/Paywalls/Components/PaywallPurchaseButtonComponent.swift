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

        let type: ComponentType
        public let textComponent: PaywallComponent.TextComponent

        public init(
            textComponent: PaywallComponent.TextComponent
        ) {
            self.type = .purchaseButton
            self.textComponent = textComponent
        }

    }

}

#endif
