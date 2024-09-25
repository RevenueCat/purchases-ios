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

    final class PurchaseButtonComponent: PaywallComponentBase {

        let type: ComponentType
        public let textComponent: PaywallComponent.TextComponent
        public let selectedComponent: PaywallComponent.PurchaseButtonComponent?

        public init(
            textComponent: PaywallComponent.TextComponent,
            selectedComponent: PaywallComponent.PurchaseButtonComponent? = nil
        ) {
            self.type = .purchaseButton
            self.textComponent = textComponent
            self.selectedComponent = selectedComponent
        }

    }

}

extension PaywallComponent.PurchaseButtonComponent: Equatable, Hashable {

    public static func == (lhs: PaywallComponent.PurchaseButtonComponent,
                           rhs: PaywallComponent.PurchaseButtonComponent) -> Bool {
        return lhs.type == rhs.type &&
               lhs.textComponent == rhs.textComponent &&
               lhs.selectedComponent == rhs.selectedComponent
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(textComponent)
        hasher.combine(selectedComponent)
    }
}

#endif
