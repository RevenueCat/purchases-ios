//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

#if !os(tvOS) && canImport(WebKit)

import Foundation
import WebKit

/// A validated, canonical web origin (`scheme://host[:port]`).
///
/// Successful construction guarantees the origin could be resolved from its input; a `nil` result
/// signals the input had no usable scheme/host. Canonicalization (lowercasing, default-port
/// elision) happens once, at construction, so comparisons never need to re-normalize.
struct WebViewOrigin: Equatable {

    /// Canonical origin string, e.g. `https://example.com` or `https://example.com:8443`.
    let value: String

    private init(scheme: String, host: String, port: Int?) {
        let suffix: String
        if let port, !Self.isDefaultPort(port, scheme: scheme) {
            suffix = ":\(port)"
        } else {
            suffix = ""
        }
        self.value = "\(scheme)://\(host)\(suffix)"
    }

    /// Canonical origin of `url`, or `nil` if it has no scheme or host.
    init?(url: URL?) {
        guard let url,
              let scheme = url.scheme?.lowercased(),
              let host = url.host?.lowercased(),
              !host.isEmpty else {
            return nil
        }
        self.init(scheme: scheme, host: host, port: url.port)
    }

    /// Canonical origin parsed from a URL or bare-origin string, or `nil` if it cannot be resolved.
    init?(string: String?) {
        guard let string, let url = URL(string: string) else {
            return nil
        }
        self.init(url: url)
    }

    /// Canonical origin of the frame that posted a script message. Uses the frame's security origin
    /// (the authoritative sender) rather than the WebView's top-level URL.
    init?(securityOrigin: WKSecurityOrigin) {
        let scheme = securityOrigin.`protocol`.lowercased()
        let host = securityOrigin.host.lowercased()
        guard !scheme.isEmpty, !host.isEmpty else {
            return nil
        }
        // `WKSecurityOrigin` reports `0` for the scheme's default port.
        self.init(scheme: scheme, host: host, port: securityOrigin.port == 0 ? nil : securityOrigin.port)
    }

    /// Whether this origin uses the `https` scheme.
    var isHTTPS: Bool {
        self.value.hasPrefix("https://")
    }

    /// Whether `url`'s canonical origin equals this origin.
    func matches(url: URL?) -> Bool {
        guard let other = WebViewOrigin(url: url) else {
            return false
        }
        return other == self
    }

    /// Whether `originString` (a full URL or a bare origin) canonicalizes to this origin.
    func matches(originString: String?) -> Bool {
        guard let other = WebViewOrigin(string: originString) else {
            return false
        }
        return other == self
    }

    private static func isDefaultPort(_ port: Int, scheme: String) -> Bool {
        (scheme == "https" && port == 443) || (scheme == "http" && port == 80)
    }

}

#endif
