//
//  PaywallLinkButtonComponent.swift
//
//
//  Created by James Borthwick on 2024-08-21.
//
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct LinkButtonComponent: PaywallComponentBase {

        let type: ComponentType
        public let url: URL
        public let textComponent: PaywallComponent.TextComponent

        public init(
            url: URL,
            textComponent: PaywallComponent.TextComponent
        ) {
            self.type = .linkButton
            self.url = url
            self.textComponent = textComponent
        }

    }

}

#endif
