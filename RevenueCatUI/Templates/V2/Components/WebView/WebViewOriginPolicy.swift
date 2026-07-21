import Foundation

#if canImport(WebKit)
import WebKit
#endif

#if !os(tvOS) && canImport(WebKit) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WebViewOrigin {

    nonisolated static func origin(of url: URL) -> String? {
        guard let scheme = url.scheme?.lowercased(),
              let host = url.host?.lowercased(),
              !host.isEmpty else {
            return nil
        }

        let port = url.port
        let suffix: String
        if let port, !Self.isDefaultPort(port, scheme: scheme) {
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
              let origin = WebViewOrigin.origin(of: url),
              origin.hasPrefix("https://") else {
            return .cancel
        }
        guard isMainFrame else {
            return .allow
        }
        let expected = URL(string: expectedOrigin).flatMap(WebViewOrigin.origin(of:))
        return origin == expected ? .allow : .cancel
    }

}

#endif
