//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/12/24.
//
// swiftlint:disable missing_docs

import Foundation

public extension PaywallComponent {

    final class PurchaseButtonComponent: PaywallComponentBase {

        let type: ComponentType
        public let stack: PaywallComponent.StackComponent

        public let action: Action?
        public let url: URL?

        // swiftlint:disable nesting
        public enum Action: String, Codable, Sendable, Hashable, Equatable {
            case inAppCheckout = "in_app_checkout"
            case webCheckout = "web_checkout"
            case webProductSelection = "web_product_selection"
        }

        public init(
            stack: PaywallComponent.StackComponent,
            action: Action?,
            url: URL?
        ) {
            self.type = .button
            self.stack = stack
            self.action = action
            self.url = url
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(stack)
            hasher.combine(action)
            hasher.combine(url)
        }

        public static func == (lhs: PurchaseButtonComponent, rhs: PurchaseButtonComponent) -> Bool {
            return lhs.type == rhs.type && lhs.stack == rhs.stack && lhs.action == rhs.action && lhs.url == rhs.url
        }
    }

}
