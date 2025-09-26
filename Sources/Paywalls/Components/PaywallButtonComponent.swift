//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallButtonComponent.swift
//
//  Created by Jay Shortway on 02/10/2024.
//
// swiftlint:disable missing_docs nesting

import Foundation

public extension PaywallComponent {

    final class ButtonComponent: PaywallComponentBase {

        let type: ComponentType
        public let action: Action
        public let stack: PaywallComponent.StackComponent
        public let transition: PaywallComponent.Transition?

        public init(
            action: Action,
            stack: PaywallComponent.StackComponent,
            transition: PaywallComponent.Transition? = nil
        ) {
            self.type = .button
            self.action = action
            self.stack = stack
            self.transition = transition
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case action
            case stack
            case transition
        }

        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try container.decode(ComponentType.self, forKey: .type)
            self.action = try container.decode(Action.self, forKey: .action)
            self.stack = try container.decode(PaywallComponent.StackComponent.self, forKey: .stack)
            self.transition = try container.decodeIfPresent(PaywallComponent.Transition.self, forKey: .transition)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encode(action, forKey: .action)
            try container.encode(stack, forKey: .stack)
            try container.encode(transition, forKey: .transition)
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(action)
            hasher.combine(stack)
            hasher.combine(transition)
        }

        public static func == (lhs: ButtonComponent, rhs: ButtonComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.action == rhs.action &&
                   lhs.stack == rhs.stack &&
                   lhs.transition == rhs.transition

        }

        public enum Action: Codable, Sendable, Hashable, Equatable {
            case restorePurchases
            case navigateBack
            case navigateTo(destination: Destination)

            case unknown

            private enum CodingKeys: String, CodingKey {
                case type
                case destination
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)

                switch self {
                case .restorePurchases:
                    try container.encode("restore_purchases", forKey: .type)
                case .navigateBack:
                    try container.encode("navigate_back", forKey: .type)
                case .navigateTo(let destination):
                    try container.encode("navigate_to", forKey: .type)
                    try destination.encode(to: encoder)
                case .unknown:
                    try container.encode("unknown", forKey: .type)
                }
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let type = try container.decode(String.self, forKey: .type)

                switch type {
                case "restore_purchases":
                    self = .restorePurchases
                case "navigate_back":
                    self = .navigateBack
                case "navigate_to":
                    let destination = try Destination(from: decoder)
                    self = .navigateTo(destination: destination)
                case "unknown":
                    self = .unknown
                default:
                    self = .unknown
                }
            }
        }

        public enum Destination: Codable, Sendable, Hashable, Equatable {
            case customerCenter
            case offerCode
            case privacyPolicy(urlLid: String, method: URLMethod)
            case sheet(sheet: Sheet)
            case terms(urlLid: String, method: URLMethod)
            case webPaywallLink(urlLid: String, method: URLMethod)
            case url(urlLid: String, method: URLMethod)

            case unknown

            private enum CodingKeys: String, CodingKey {
                case destination
                case url
                case sheet
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)

                switch self {
                case .customerCenter:
                    try container.encode("customer_center", forKey: .destination)
                case .offerCode:
                    try container.encode("offer_code", forKey: .destination)
                case .terms(let urlLid, let method):
                    try container.encode("terms", forKey: .destination)
                    try container.encode(URLPayload(urlLid: urlLid, method: method), forKey: .url)
                case .privacyPolicy(let urlLid, let method):
                    try container.encode("privacy_policy", forKey: .destination)
                    try container.encode(URLPayload(urlLid: urlLid, method: method), forKey: .url)
                case .webPaywallLink(let urlLid, let method):
                    try container.encode("web_paywall_link", forKey: .destination)
                    try container.encode(URLPayload(urlLid: urlLid, method: method), forKey: .url)
                case .url(let urlLid, let method):
                    try container.encode("url", forKey: .destination)
                    try container.encode(URLPayload(urlLid: urlLid, method: method), forKey: .url)
                case .sheet:
                    try container.encode("sheet", forKey: .destination)
                case .unknown:
                    try container.encode("unknown", forKey: .destination)
                }
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let destination = try container.decode(String.self, forKey: .destination)

                switch destination {
                case "customer_center":
                    self = .customerCenter
                case "offer_code":
                    self = .offerCode
                case "sheet":
                    let sheet = try container.decode(Sheet.self, forKey: .sheet)
                    self = .sheet(sheet: sheet)
                case "terms":
                    let urlPayload = try container.decode(URLPayload.self, forKey: .url)
                    self = .terms(urlLid: urlPayload.urlLid, method: urlPayload.method)
                case "privacy_policy":
                    let urlPayload = try container.decode(URLPayload.self, forKey: .url)
                    self = .privacyPolicy(urlLid: urlPayload.urlLid, method: urlPayload.method)
                case "url":
                    let urlPayload = try container.decode(URLPayload.self, forKey: .url)
                    self = .url(urlLid: urlPayload.urlLid, method: urlPayload.method)
                case "web_paywall_link":
                    let urlPayload = try container.decode(URLPayload.self, forKey: .url)
                    self = .webPaywallLink(urlLid: urlPayload.urlLid, method: urlPayload.method)
                case "unknown":
                    self = .unknown
                default:
                    self = .unknown
                }
            }
        }

        public enum URLMethod: String, Codable, Sendable, Hashable, Equatable {
            case inAppBrowser = "in_app_browser"
            case externalBrowser = "external_browser"
            case deepLink = "deep_link"

            case unknown = "unknown"

            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)
                self = URLMethod(rawValue: rawValue) ?? .unknown
            }
        }

        private struct URLPayload: Codable, Hashable, Sendable {
            let urlLid: String
            let method: URLMethod
        }

        public struct Sheet: Codable, Hashable, Sendable {
            public let id: String
            public let name: String?
            public let stack: StackComponent
            public let backgroundBlur: Bool
            public let size: Size?

            public init(
                id: String,
                name: String?,
                stack: StackComponent,
                backgroundBlur: Bool,
                size: Size?
            ) {
                self.id = id
                self.name = name
                self.stack = stack
                self.backgroundBlur = backgroundBlur
                self.size = size
            }
        }
    }
}
