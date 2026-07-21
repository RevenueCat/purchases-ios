#if !os(tvOS) && canImport(WebKit) // For Paywalls V2

import Foundation
import WebKit

extension URL {

    /// Canonical origin (`scheme://host[:port]`) of the URL, or `nil` if it has no scheme or host.
    nonisolated var webViewOrigin: String? {
        guard let scheme = self.scheme?.lowercased(),
              let host = self.host?.lowercased(),
              !host.isEmpty else {
            return nil
        }
        return WebViewOrigin.canonicalOrigin(scheme: scheme, host: host, port: self.port)
    }

}

extension WKSecurityOrigin {

    /// Canonical origin of the frame that posted a script message. Uses the frame's security origin
    /// (the authoritative sender) rather than the WebView's top-level URL.
    var webViewOrigin: String? {
        let scheme = self.`protocol`.lowercased()
        let host = self.host.lowercased()
        guard !scheme.isEmpty, !host.isEmpty else {
            return nil
        }
        // `WKSecurityOrigin` reports `0` for the scheme's default port.
        return WebViewOrigin.canonicalOrigin(scheme: scheme, host: host, port: self.port == 0 ? nil : self.port)
    }

}

private enum WebViewOrigin {

    nonisolated static func canonicalOrigin(scheme: String, host: String, port: Int?) -> String {
        let suffix: String
        if let port, !isDefaultPort(port, scheme: scheme) {
            suffix = ":\(port)"
        } else {
            suffix = ""
        }
        return "\(scheme)://\(host)\(suffix)"
    }

    nonisolated private static func isDefaultPort(_ port: Int, scheme: String) -> Bool {
        (scheme == "https" && port == 443) || (scheme == "http" && port == 80)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WebViewNavigationPolicy {

    // Non-https navigation is blocked on any frame. Cross-origin navigation is additionally blocked
    // on the main frame (same-origin different-path navigation stays allowed), which makes
    // cross-origin message races structurally impossible. Cross-origin sub-frame loads are not
    // blocked here; isolation for those is left to the server-provided CSP (`frame-src` falls back
    // to `default-src 'self'`).
    static func policy(for url: URL?, isMainFrame: Bool, expectedOrigin: String) -> WKNavigationActionPolicy {
        guard let url,
              let origin = url.webViewOrigin,
              origin.hasPrefix("https://") else {
            return .cancel
        }
        guard isMainFrame else {
            return .allow
        }
        let expected = URL(string: expectedOrigin)?.webViewOrigin
        return origin == expected ? .allow : .cancel
    }

}

#endif
