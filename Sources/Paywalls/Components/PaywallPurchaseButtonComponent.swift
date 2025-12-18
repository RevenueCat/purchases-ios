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
        public let method: Method?

        // swiftlint:disable nesting
        public enum Action: String, Codable, Sendable, Hashable, Equatable {
            case inAppCheckout = "in_app_checkout"
            case webCheckout = "web_checkout"
            case webProductSelection = "web_product_selection"
        }

        public enum Method: Codable, Sendable, Hashable, Equatable {
            case inAppCheckout
            case webCheckout(WebCheckout)
            case webProductSelection(WebCheckout)
            case customWebCheckout(CustomWebCheckout)

            case unknown

            private enum CodingKeys: String, CodingKey {
                case type

                case webCheckout
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)

                switch self {
                case .inAppCheckout:
                    try container.encode("in_app_checkout", forKey: .type)
                case .webCheckout(let webCheckout):
                    try container.encode("web_checkout", forKey: .type)
                    try webCheckout.encode(to: encoder)
                case .webProductSelection(let webCheckout):
                    try container.encode("web_product_selection", forKey: .type)
                    try webCheckout.encode(to: encoder)
                case .customWebCheckout(let customWebCheckout):
                    try container.encode("custom_web_checkout", forKey: .type)
                    try customWebCheckout.encode(to: encoder)
                case .unknown:
                    try container.encode("unknown", forKey: .type)
                }
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let type = try container.decode(String.self, forKey: .type)

                switch type {
                case "in_app_checkout":
                    self = .inAppCheckout
                case "web_checkout":
                    let webCheckout = try WebCheckout(from: decoder)
                    self = .webCheckout(webCheckout)
                case "web_product_selection":
                    let webCheckout = try WebCheckout(from: decoder)
                    self = .webProductSelection(webCheckout)
                case "custom_web_checkout":
                    let customCheckout = try CustomWebCheckout(from: decoder)
                    self = .customWebCheckout(customCheckout)
                case "unknown":
                    self = .unknown
                default:
                    self = .unknown
                }
            }
        }

        public struct WebCheckout: Codable, Sendable, Hashable, Equatable {

            public let autoDismiss: Bool?
            public let openMethod: ButtonComponent.URLMethod?

            public init(autoDismiss: Bool? = nil, openMethod: PaywallComponent.ButtonComponent.URLMethod? = nil) {
                self.autoDismiss = autoDismiss
                self.openMethod = openMethod
            }

        }

        public struct CustomWebCheckout: Codable, Sendable, Hashable, Equatable {

            public struct CustomURL: Codable, Sendable, Hashable, Equatable {

                public let url: LocalizationKey
                public let packageParam: String?

                public init(url: PaywallComponent.LocalizationKey, packageParam: String? = nil) {
                    self.url = url
                    self.packageParam = packageParam
                }

                private enum CodingKeys: String, CodingKey {
                    case url = "urlLid"
                    case packageParam
                }

            }

            public init(
                customUrl: PaywallComponent.PurchaseButtonComponent.CustomWebCheckout.CustomURL,
                autoDismiss: Bool? = nil,
                openMethod: PaywallComponent.ButtonComponent.URLMethod? = nil
            ) {
                self.customUrl = customUrl
                self.autoDismiss = autoDismiss
                self.openMethod = openMethod
            }

            public let customUrl: CustomURL
            public let autoDismiss: Bool?
            public let openMethod: ButtonComponent.URLMethod?

        }

        public init(
            stack: PaywallComponent.StackComponent,
            action: Action?,
            method: Method?
        ) {
            self.type = .purchaseButton
            self.stack = stack
            self.action = action
            self.method = method
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(stack)
            hasher.combine(action)
            hasher.combine(method)
        }

        public static func == (lhs: PurchaseButtonComponent, rhs: PurchaseButtonComponent) -> Bool {
            return lhs.type == rhs.type &&
                lhs.stack == rhs.stack &&
                lhs.action == rhs.action &&
                lhs.method == rhs.method
        }
    }

}
