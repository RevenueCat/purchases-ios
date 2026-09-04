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
/// signal it gives is a redirect to one of the two return URLs the backend handed it. The host watches
/// for that navigation and cancels it, so the request never leaves the device.
///
/// Both URLs come from the backend rather than being built here, so nothing about their shape is
/// assumed: today they differ only by a `status` query parameter, but a change to distinct paths would
/// work just as well.
struct WebCheckoutReturnURL {

    private let success: Target
    private let cancel: Target

    /// - Parameter successURL: Where the provider sends the customer once checkout succeeds.
    /// - Parameter cancelURL: Where the provider sends the customer once checkout is abandoned.
    ///
    /// Fails when either URL has no resolvable origin, since no navigation could ever match it.
    init?(successURL: URL, cancelURL: URL) {
        guard let success = Target(url: successURL),
              let cancel = Target(url: cancelURL) else {
            return nil
        }

        self.success = success
        self.cancel = cancel
    }

    /// Whether navigating to `url` means checkout has finished.
    ///
    /// Matched on origin and path alone, so a return the outcome of which we cannot read still ends the
    /// checkout rather than leaving the customer on the backend's bare return page.
    func matches(_ url: URL?) -> Bool {
        guard let url else {
            return false
        }

        return self.cancel.matchesEndpoint(url) || self.success.matchesEndpoint(url)
    }

    /// The outcome `url` reports, or `nil` if it matches neither return URL closely enough to tell.
    ///
    /// Cancel is tested first, so that two return URLs we cannot tell apart resolve to a cancellation
    /// rather than to a purchase that may never have happened.
    func status(of url: URL?) -> WebCheckoutReturnStatus? {
        guard let url else {
            return nil
        }

        if self.cancel.matches(url) {
            return .cancel
        } else if self.success.matches(url) {
            return .success
        } else {
            return nil
        }
    }

}

private extension WebCheckoutReturnURL {

    /// One of the two return URLs, prepared for comparison.
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

        /// Whether `url` is this return URL specifically, rather than merely the endpoint the two share.
        ///
        /// Every parameter configured on this URL has to be present, but `url` may carry others beside
        /// them: providers append their own, and the two return URLs are told apart by what they were
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
            guard path.count > 1, path.hasSuffix("/") else {
                return path
            }

            return String(path.dropLast())
        }

    }

}

#endif
