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

    final class LinkButtonComponent: PaywallComponentBase {

        let type: ComponentType
        public let url: URL
        public let textComponent: PaywallComponent.TextComponent
        public let selectedComponent: LinkButtonComponent?

        public init(
            url: URL,
            textComponent: PaywallComponent.TextComponent,
            selectedComponent: LinkButtonComponent? = nil
        ) {
            self.type = .linkButton
            self.url = url
            self.textComponent = textComponent
            self.selectedComponent = selectedComponent
        }

    }

}

extension PaywallComponent.LinkButtonComponent: Equatable, Hashable {

    public static func == (lhs: PaywallComponent.LinkButtonComponent, 
                           rhs: PaywallComponent.LinkButtonComponent
    ) -> Bool {
        return lhs.type == rhs.type &&
               lhs.url == rhs.url &&
               lhs.textComponent == rhs.textComponent &&
               lhs.selectedComponent == rhs.selectedComponent
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(url)
        hasher.combine(textComponent)
        hasher.combine(selectedComponent)
    }

}

#endif
