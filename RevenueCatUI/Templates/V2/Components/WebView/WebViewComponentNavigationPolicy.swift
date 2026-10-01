//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  WebViewComponentNavigationPolicy.swift
//

#if !os(tvOS) && canImport(WebKit) // For Paywalls V2

import Foundation
import WebKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WebViewComponentNavigationPolicy {

    // Non-https navigation is blocked on any frame. Cross-origin navigation is additionally blocked
    // on the main frame (same-origin different-path navigation stays allowed), which makes
    // cross-origin message races structurally impossible. Cross-origin sub-frame loads are not
    // blocked here; isolation for those is left to the server-provided CSP (`frame-src` falls back
    // to `default-src 'self'`).
    static func policy(for url: URL?, isMainFrame: Bool, expectedOrigin: WebViewOrigin) -> WKNavigationActionPolicy {
        guard let origin = WebViewOrigin(url: url), origin.isHTTPS else {
            return .cancel
        }
        guard isMainFrame else {
            return .allow
        }
        return origin == expectedOrigin ? .allow : .cancel
    }

}

#endif
