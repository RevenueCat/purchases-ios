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

}

/// Recognises the navigation that ends a checkout.
///
/// The checkout page belongs to a payment provider and exposes no JavaScript bridge, so the single
/// signal it gives is a redirect to the return URL the backend handed it. The host watches for that
/// navigation and cancels it, so the request never leaves the device.
///
/// There is no return URL for an abandoned checkout: the customer leaves one by closing the sheet.
struct WebCheckoutReturnURL {

    private let success: Target

    /// - Parameter successURL: Where the provider sends the customer once checkout succeeds.
    ///
    /// Fails when the URL has no resolvable origin, since no navigation could ever match it.
    init?(successURL: URL) {
        guard let success = Target(url: successURL) else {
            return nil
        }

        self.success = success
    }

    /// Whether navigating to `url` means checkout has finished.
    ///
    /// Matched on origin and path alone, so a return the outcome of which we cannot read still ends the
    /// checkout rather than leaving the customer on the backend's bare return page.
    func matches(_ url: URL?) -> Bool {
        guard let url else {
            return false
        }

        return self.success.matchesEndpoint(url)
    }

    /// The outcome `url` reports, or `nil` if it does not match the return URL closely enough to tell.
    func status(of url: URL?) -> WebCheckoutReturnStatus? {
        guard let url, self.success.matches(url) else {
            return nil
        }

        return .success
    }

}

private extension WebCheckoutReturnURL {

    /// The return URL, prepared for comparison.
    struct Target {

        private let origin: WebViewOrigin
        private let path: String
        private let queryItems: [URLQueryItem]

        init?(url: URL) {
            guard let origin = WebViewOrigin(url: url) else {
                return nil
            }

            self.origin = origin
            self.path = Self.normalizedPath(of: url)
            self.queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        }

        /// Whether `url` addresses the same endpoint, ignoring what it carries in its query.
        func matchesEndpoint(_ url: URL) -> Bool {
            guard self.origin.matches(url: url) else {
                return false
            }

            return Self.normalizedPath(of: url) == self.path
        }

        /// Whether `url` is this return URL specifically, rather than merely its endpoint.
        ///
        /// Every parameter configured on this URL has to be present, but `url` may carry others beside
        /// them: providers may append their own, so the return URL is recognised by what it was
        /// configured with, not by an exact match.
        func matches(_ url: URL) -> Bool {
            guard self.matchesEndpoint(url) else {
                return false
            }

            let actual = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

            return self.queryItems.allSatisfy(actual.contains)
        }

        /// A trailing slash does not name a different endpoint, so `/a/` and `/a` compare equal.
        private static func normalizedPath(of url: URL) -> String {
            let path = url.path
            guard path.hasSuffix("/") else {
                return path
            }

            return String(path.dropLast())
        }

    }

}

#endif
