//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallWebViewComponent.swift
//
// swiftlint:disable missing_docs nesting

import Foundation

@_spi(Internal) public extension PaywallComponent {

    final class WebViewComponent: PaywallComponentBase {

        /// Wire `type` value. `ComponentType.webView` is registered in the activation PR.
        let type: String
        public let id: String?
        public let name: String?
        public let visible: Bool?

        /// The declared Paywalls web component protocol version.
        /// Decoded and preserved; native host capability is fixed by the SDK build.
        public let protocolVersion: Int

        /// The static HTTPS URL of the web bundle entry point.
        public let url: String

        public let size: Size

        public init(
            id: String? = nil,
            name: String? = nil,
            visible: Bool? = nil,
            protocolVersion: Int = 1,
            url: String,
            size: Size = .init(width: .fill, height: .fit(nil))
        ) {
            self.type = "web_view"
            self.id = id
            self.name = name
            self.visible = visible
            self.protocolVersion = protocolVersion
            self.url = url
            self.size = size
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case id
            case name
            case visible
            case protocolVersion
            case url
            case size
        }

        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try container.decode(String.self, forKey: .type)
            self.id = try container.decodeIfPresent(String.self, forKey: .id)
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
            self.visible = try container.decodeIfPresent(Bool.self, forKey: .visible)
            self.protocolVersion = try container.decodeIfPresent(Int.self, forKey: .protocolVersion) ?? 1
            self.url = try container.decode(String.self, forKey: .url)
            self.size = try container.decodeIfPresent(Size.self, forKey: .size)
                ?? .init(width: .fill, height: .fit(nil))
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(id)
            hasher.combine(name)
            hasher.combine(visible)
            hasher.combine(protocolVersion)
            hasher.combine(url)
            hasher.combine(size)
        }

        public static func == (lhs: WebViewComponent, rhs: WebViewComponent) -> Bool {
            return lhs.type == rhs.type &&
                lhs.id == rhs.id &&
                lhs.name == rhs.name &&
                lhs.visible == rhs.visible &&
                lhs.protocolVersion == rhs.protocolVersion &&
                lhs.url == rhs.url &&
                lhs.size == rhs.size
        }

    }

}
