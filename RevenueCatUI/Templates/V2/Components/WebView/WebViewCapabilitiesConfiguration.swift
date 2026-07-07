//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewCapabilitiesConfiguration.swift

import Foundation
@_spi(Internal) import RevenueCat
#if canImport(WebKit)
import WebKit
#endif

#if !os(tvOS) && canImport(WebKit) // For Paywalls V2

/// WebKit-free content-blocking policy for `web_view` components. Kept separate from the WKWebView
/// rendering code so it can be unit-tested without instantiating a web view.
///
/// Same-origin subresources and same-origin fetch/XHR are allowed; `data:` images and fonts are
/// allowed; cross-origin third-party subresource loads are blocked.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WebViewCapabilitiesConfiguration {

    /// Stable identifier used to cache the compiled `WKContentRuleList` for the fixed isolation
    /// policy. Bump when the policy changes.
    static let contentRuleListIdentifier = "rc-webview-v2-isolation"

    /// The fixed content-blocking rules (as a JSON string) enforcing bundle isolation.
    static var contentBlockingRules: String? {
        let rules: [[String: Any]] = [
            // Block remote (third-party) images, scripts and fonts; same-origin assets still load.
            [
                "trigger": [
                    "url-filter": ".*",
                    "resource-type": ["image", "script", "font"],
                    "load-type": ["third-party"]
                ],
                "action": ["type": "block"]
            ],
            // Block third-party XHR/fetch.
            [
                "trigger": [
                    "url-filter": ".*",
                    "resource-type": ["raw"],
                    "load-type": ["third-party"]
                ],
                "action": ["type": "block"]
            ]
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: rules),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }

        return json
    }

}

/// Caches compiled `WKContentRuleList`s keyed by identifier so the fixed isolation policy is
/// compiled at most once per session.
///
/// Compilation is asynchronous; a web view attaches the rule list once
/// ``ruleList(forIdentifier:json:completion:)`` finishes compiling it.
///
/// Accessed on the main thread only (`compileContentRuleList`'s completion handler is invoked there).
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class WebViewContentRuleListStore {

    static var shared = WebViewContentRuleListStore()

    private var cache: [String: WKContentRuleList] = [:]

    private init() {}

    /// Returns the compiled rule list for `identifier`, compiling `json` if it isn't cached yet.
    /// Completes on the main thread; `nil` indicates compilation failed.
    func ruleList(
        forIdentifier identifier: String,
        json: String,
        completion: @escaping (WKContentRuleList?) -> Void
    ) {
        if let cached = self.cache[identifier] {
            completion(cached)
            return
        }

        guard let store = WKContentRuleListStore.default() else {
            completion(nil)
            return
        }

        store.compileContentRuleList(
            forIdentifier: identifier,
            encodedContentRuleList: json
        ) { [weak self] ruleList, error in
            if let error {
                Logger.debug(Strings.paywall_web_view_content_rules_failed(error))
            }
            if let ruleList {
                self?.cache[identifier] = ruleList
            }
            completion(ruleList)
        }
    }

}

#endif
