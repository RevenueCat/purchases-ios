//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewOrigin.swift

import Foundation

#if !os(tvOS) // For Paywalls V2

/// Origin comparison helpers for `web_view` messaging (`scheme://host[:port]`).
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WebViewOrigin {

    /// Returns the origin of `url` as `scheme://host[:port]`, or `nil` when the URL has no host.
    static func origin(of url: URL) -> String? {
        guard let host = url.host?.lowercased(), !host.isEmpty else {
            return nil
        }

        let scheme = (url.scheme ?? "").lowercased()
        let port = Self.effectivePort(for: url)
        let portSuffix: String
        if let port, !Self.isDefaultPort(port, scheme: scheme) {
            portSuffix = ":\(port)"
        } else {
            portSuffix = ""
        }

        return "\(scheme)://\(host)\(portSuffix)"
    }

    /// Whether `currentURL` shares the same origin as `expectedURL`.
    static func matches(currentURL: URL?, expectedURL: URL?, allowBeforeNavigation: Bool) -> Bool {
        guard let expectedOrigin = expectedURL.flatMap({ Self.origin(of: $0) }) else {
            return false
        }

        guard let currentURL else {
            return allowBeforeNavigation
        }

        guard let currentOrigin = Self.origin(of: currentURL) else {
            return allowBeforeNavigation
        }

        return currentOrigin == expectedOrigin
    }

    private static func effectivePort(for url: URL) -> Int? {
        if let port = url.port {
            return port
        }

        switch url.scheme?.lowercased() {
        case "https":
            return 443
        case "http":
            return 80
        default:
            return nil
        }
    }

    private static func isDefaultPort(_ port: Int, scheme: String) -> Bool {
        switch scheme {
        case "https":
            return port == 443
        case "http":
            return port == 80
        default:
            return false
        }
    }

}

#endif
