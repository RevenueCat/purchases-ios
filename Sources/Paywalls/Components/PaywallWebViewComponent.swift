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

        let type: ComponentType
        public let url: URL

        public init(url: URL) {
            self.type = .webView
            self.url = url
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(url)
        }

        public static func == (lhs: WebViewComponent, rhs: WebViewComponent) -> Bool {
            return lhs.url == rhs.url
        }

    }

}
