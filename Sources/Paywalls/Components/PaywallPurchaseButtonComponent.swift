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

        // swiftlint:disable:next swiftlint
        public struct CustomURL: PaywallComponentBase {
            public let url: URL
            public let packageParam: String
        }

        let type: ComponentType
        public let stack: PaywallComponent.StackComponent

        public let action: Action?

        public let customUrl: CustomURL?
        public let webAutoDismiss: Bool

        // swiftlint:disable nesting
        public enum Action: String, Codable, Sendable, Hashable, Equatable {
            case inAppCheckout = "in_app_checkout"
            case webCheckout = "web_checkout"
            case webProductSelection = "web_product_selection"
        }

        public init(
            stack: PaywallComponent.StackComponent,
            action: Action?,
            customUrl: CustomURL? = nil,
            webAutoDismiss: Bool = true
        ) {
            self.type = .button
            self.stack = stack
            self.action = action
            self.customUrl = customUrl
            self.webAutoDismiss = webAutoDismiss
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(stack)
            hasher.combine(action)
            hasher.combine(customUrl)
            hasher.combine(webAutoDismiss)
        }

        public static func == (lhs: PurchaseButtonComponent, rhs: PurchaseButtonComponent) -> Bool {
            return lhs.type == rhs.type &&
                lhs.stack == rhs.stack &&
                lhs.action == rhs.action &&
                lhs.customUrl == rhs.customUrl &&
                lhs.webAutoDismiss == rhs.webAutoDismiss
        }
    }

}
