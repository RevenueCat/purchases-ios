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
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct ButtonComponent: PaywallComponentBase {

        let type: ComponentType
        public let action: Action
        public let stack: PaywallComponent.StackComponent

        public init(
            action: Action,
            stack: PaywallComponent.StackComponent
        ) {
            self.type = .button
            self.action = action
            self.stack = stack
        }

    }

}

public extension PaywallComponent.ButtonComponent {

    enum Action: Codable, Sendable, Hashable, Equatable {
        case restorePurchases
        case navigateBack
        case navigateTo(destination: Destination)

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case type
            case destination
            case url
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
                try destination.encode(to: encoder) // Encode destination directly under action
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
                let destination = try Destination(from: decoder) // Decode destination directly under action
                self = .navigateTo(destination: destination)
            default:
                throw DecodingError.dataCorruptedError(forKey: .type,
                                                       in: container, debugDescription: "Invalid action type")
            }
        }
    }

    enum Destination: Codable, Sendable, Hashable, Equatable {
        case customerCenter
        case privacyPolicy(urlLid: String, method: URLMethod)
        case terms(urlLid: String, method: URLMethod)
        case url(urlLid: String, method: URLMethod)

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case destination
            case url
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .customerCenter:
                try container.encode("customer_center", forKey: .destination)
            case .terms(let urlLid, let method):
                try container.encode("terms", forKey: .destination)
                try container.encode(URLPayload(urlLid: urlLid, method: method), forKey: .url)
            case .privacyPolicy(let urlLid, let method):
                try container.encode("privacy_policy", forKey: .destination)
                try container.encode(URLPayload(urlLid: urlLid, method: method), forKey: .url)
            case .url(let urlLid, let method):
                try container.encode("url", forKey: .destination)
                try container.encode(URLPayload(urlLid: urlLid, method: method), forKey: .url)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let destination = try container.decode(String.self, forKey: .destination)

            switch destination {
            case "customer_center":
                self = .customerCenter
            case "terms":
                let urlPayload = try container.decode(URLPayload.self, forKey: .url)
                self = .terms(urlLid: urlPayload.urlLid, method: urlPayload.method)
            case "privacy_policy":
                let urlPayload = try container.decode(URLPayload.self, forKey: .url)
                self = .privacyPolicy(urlLid: urlPayload.urlLid, method: urlPayload.method)
            case "url":
                let urlPayload = try container.decode(URLPayload.self, forKey: .url)
                self = .url(urlLid: urlPayload.urlLid, method: urlPayload.method)
            default:
                throw DecodingError.dataCorruptedError(forKey: .destination,
                                                       in: container, debugDescription: "Invalid destination type")
            }
        }
    }

    enum URLMethod: String, Codable, Sendable, Hashable, Equatable {
        case inAppBrowser = "in_app_browser"
        case externalBrowser = "external_browser"
        case deepLink = "deep_link"
    }

    private struct URLPayload: Codable, Hashable, Sendable {
        let urlLid: String
        let method: URLMethod
    }

}

#endif
