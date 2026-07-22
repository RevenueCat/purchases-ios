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
// swiftlint:disable missing_docs

import Foundation

@_spi(Internal) public extension PaywallComponent {

    final class WebViewComponent: PaywallComponentBase {

        /// The host<->component bridge protocol version this SDK implements. A config declaring any
        /// other version is treated as an unrecognized component and rendered via its `fallback`.
        public static let supportedProtocolVersion: Int = 1

        let type: ComponentType
        public let id: String
        public let name: String?
        public let visible: Bool?

        public let protocolVersion: Int

        /// The static HTTPS URL of the web bundle entry point.
        public let url: String

        public let size: Size

        /// Whether this SDK can create a functional web view from the decoded static configuration.
        var hasRenderableConfiguration: Bool {
            guard self.protocolVersion == Self.supportedProtocolVersion,
                  !self.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !self.url.contains("{{"),
                  let url = URL(string: self.url),
                  url.scheme?.lowercased() == "https",
                  url.host?.isEmpty == false else {
                return false
            }

            return true
        }

        public init(
            id: String,
            name: String? = nil,
            visible: Bool? = nil,
            protocolVersion: Int,
            url: String,
            size: Size = .init(width: .fill, height: .fit(nil))
        ) {
            self.type = .webView
            self.id = id
            self.name = name
            self.visible = visible
            self.protocolVersion = protocolVersion
            self.url = url
            self.size = size
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
