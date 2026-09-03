//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebCheckoutNavigationPolicy.swift
//
//  Created by Antonio Pallares on 3/9/26.
//

#if !os(tvOS) && canImport(WebKit)

import Foundation
import WebKit

/// Decides which navigations the checkout web view may perform.
///
/// Distinct from `WebViewComponentNavigationPolicy`, which pins the main frame to a single origin.
/// A checkout legitimately hands its main frame to other origins, such as a payment provider's hosted
/// pages, so this policy gates the main frame on an allowlist instead.
struct WebCheckoutNavigationPolicy {

    private let allowedOrigins: [WebViewOrigin]

    /// - Parameter checkoutURL: The checkout entry point. Its own origin is always allowed.
    /// - Parameter additionalAllowedOrigins: Further origins the checkout flow is expected to reach.
    init(checkoutURL: URL?, additionalAllowedOrigins: [WebViewOrigin]) {
        self.allowedOrigins = [WebViewOrigin(url: checkoutURL)].compactMap { $0 } + additionalAllowedOrigins
    }

    /// Whether the navigation to `url` may proceed.
    ///
    /// Sub-frames are always allowed. A payment flow relies on frames this policy cannot enumerate:
    /// provider-hosted card fields, 3-D Secure challenges served from the card issuer's own domain, and
    /// `about:blank` frames created before a source is assigned. Restricting the main frame is what
    /// matters, and a sub-frame that navigates the top frame is still checked as a main-frame navigation.
    func policy(for url: URL?, isMainFrame: Bool) -> WKNavigationActionPolicy {
        guard isMainFrame else {
            return .allow
        }

        guard let origin = WebViewOrigin(url: url),
              origin.isHTTPS,
              self.allowedOrigins.contains(origin) else {
            return .cancel
        }

        return .allow
    }

}

#endif
