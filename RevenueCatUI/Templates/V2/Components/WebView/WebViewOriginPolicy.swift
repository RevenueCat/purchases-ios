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

    // The origin check is enforced on every frame, including sub-frames, so cross-origin iframes
    // cannot navigate freely.
    static func policy(for url: URL?, expectedOrigin: String) -> WKNavigationActionPolicy {
        guard let url,
              let origin = WebViewOrigin.origin(of: url),
              let expected = URL(string: expectedOrigin).flatMap(WebViewOrigin.origin(of:)),
              origin == expected else {
            return .cancel
        }
        return .allow
    }

}

#endif
