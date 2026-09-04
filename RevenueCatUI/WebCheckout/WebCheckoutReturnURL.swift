//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebCheckoutReturnURL.swift
//
//  Created by Antonio Pallares on 4/9/26.
//

#if os(iOS) && canImport(WebKit)

import Foundation

/// How the checkout page says it ended.
///
/// Only a hint about which way the flow went: the backend stays the source of truth for whether a
/// purchase actually happened.
enum WebCheckoutReturnStatus: String {

    case success
    case cancel

}

/// Recognises the navigation that ends a checkout.
///
/// The checkout page belongs to a payment provider and exposes no JavaScript bridge, so the single
/// signal it gives is a redirect to the return URL the backend handed it. The host watches for that
/// navigation and cancels it, so the request never leaves the device.
struct WebCheckoutReturnURL {

    private static let statusQueryItemName = "status"

    private let origin: WebViewOrigin
    private let path: String

    /// - Parameter url: The return URL configured on the checkout session.
    ///
    /// Fails when `url` has no resolvable origin, since no navigation could ever match it.
    init?(url: URL) {
        guard let origin = WebViewOrigin(url: url) else {
            return nil
        }

        self.origin = origin
        self.path = Self.normalizedPath(of: url)
    }

    /// Whether navigating to `url` means checkout has finished.
    ///
    /// Compared on origin and path alone. The query is deliberately excluded: it is where the outcome
    /// is reported, and providers append parameters of their own next to it.
    func matches(_ url: URL?) -> Bool {
        guard let url, self.origin.matches(url: url) else {
            return false
        }

        return Self.normalizedPath(of: url) == self.path
    }

    /// The outcome `url` reports, or `nil` if it carries none we recognise.
    func status(of url: URL?) -> WebCheckoutReturnStatus? {
        guard let url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let value = components.queryItems?.first(where: { $0.name == Self.statusQueryItemName })?.value else {
            return nil
        }

        return WebCheckoutReturnStatus(rawValue: value)
    }

    /// A trailing slash does not name a different endpoint, so `/a/` and `/a` compare equal.
    private static func normalizedPath(of url: URL) -> String {
        let path = url.path
        guard path.count > 1, path.hasSuffix("/") else {
            return path
        }

        return String(path.dropLast())
    }

}

#endif
