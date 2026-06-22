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

        let type: ComponentType
        public let id: String?
        public let name: String?
        public let visible: Bool?

        /// The Paywalls web component protocol version. Only version `1` is currently supported.
        /// Decoded and preserved; no protocol-version-specific behavior is implemented yet.
        public let protocolVersion: Int

        /// The URL (or URL template) of the web bundle entrypoint to load.
        /// May contain `{{ custom.variable }}` tokens that are resolved at display time.
        /// After variable substitution it must resolve to a valid HTTPS URL with a host.
        public let url: String

        public let size: Size

        /// A standard stack rendered when the web content cannot be displayed
        /// (e.g. the resolved URL is invalid). Preserved verbatim, including children.
        public let fallback: StackComponent?

        /// Declared web view capabilities. When omitted (the default), the web view grants
        /// nothing; each declared capability opts into a specific `WKWebView` affordance.
        public let capabilities: WebViewCapabilities?

        public init(
            id: String? = nil,
            name: String? = nil,
            visible: Bool? = nil,
            protocolVersion: Int = 1,
            url: String,
            size: Size = .init(width: .fill, height: .fit),
            fallback: StackComponent? = nil,
            capabilities: WebViewCapabilities? = nil
        ) {
            self.type = .webView
            self.id = id
            self.name = name
            self.visible = visible
            self.protocolVersion = protocolVersion
            self.url = url
            self.size = size
            self.fallback = fallback
            self.capabilities = capabilities
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case id
            case name
            case visible
            case protocolVersion
            case url
            case size
            case fallback
            case capabilities
        }

        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try container.decode(ComponentType.self, forKey: .type)
            self.id = try container.decodeIfPresent(String.self, forKey: .id)
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
            self.visible = try container.decodeIfPresent(Bool.self, forKey: .visible)
            self.protocolVersion = try container.decodeIfPresent(Int.self, forKey: .protocolVersion) ?? 1
            self.url = try container.decode(String.self, forKey: .url)
            self.size = try container.decodeIfPresent(Size.self, forKey: .size)
                ?? .init(width: .fill, height: .fit)
            self.fallback = try container.decodeIfPresent(StackComponent.self, forKey: .fallback)
            self.capabilities = try container.decodeIfPresent(WebViewCapabilities.self, forKey: .capabilities)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(id, forKey: .id)
            try container.encodeIfPresent(name, forKey: .name)
            try container.encodeIfPresent(visible, forKey: .visible)
            try container.encode(protocolVersion, forKey: .protocolVersion)
            try container.encode(url, forKey: .url)
            try container.encode(size, forKey: .size)
            try container.encodeIfPresent(fallback, forKey: .fallback)
            try container.encodeIfPresent(capabilities, forKey: .capabilities)
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(id)
            hasher.combine(name)
            hasher.combine(visible)
            hasher.combine(protocolVersion)
            hasher.combine(url)
            hasher.combine(size)
            hasher.combine(fallback)
            hasher.combine(capabilities)
        }

        public static func == (lhs: WebViewComponent, rhs: WebViewComponent) -> Bool {
            return lhs.type == rhs.type &&
                lhs.id == rhs.id &&
                lhs.name == rhs.name &&
                lhs.visible == rhs.visible &&
                lhs.protocolVersion == rhs.protocolVersion &&
                lhs.url == rhs.url &&
                lhs.size == rhs.size &&
                lhs.fallback == rhs.fallback &&
                lhs.capabilities == rhs.capabilities
        }

    }

    /// Declared capabilities for a ``WebViewComponent``. Each field opts the web view into a
    /// specific `WKWebView` affordance; omitted fields and an omitted object grant nothing.
    struct WebViewCapabilities: PaywallComponentBase {

        public struct NetworkAccess: PaywallComponentBase {

            public let allowedDomains: [String]?

            public init(allowedDomains: [String]? = nil) {
                self.allowedDomains = allowedDomains
            }

        }

        public let networkAccess: NetworkAccess?
        public let camera: Bool?
        public let microphone: Bool?
        public let clipboardWrite: Bool?
        public let clipboardRead: Bool?
        public let geolocation: Bool?

        public init(
            networkAccess: NetworkAccess? = nil,
            camera: Bool? = nil,
            microphone: Bool? = nil,
            clipboardWrite: Bool? = nil,
            clipboardRead: Bool? = nil,
            geolocation: Bool? = nil
        ) {
            self.networkAccess = networkAccess
            self.camera = camera
            self.microphone = microphone
            self.clipboardWrite = clipboardWrite
            self.clipboardRead = clipboardRead
            self.geolocation = geolocation
        }

    }

}
