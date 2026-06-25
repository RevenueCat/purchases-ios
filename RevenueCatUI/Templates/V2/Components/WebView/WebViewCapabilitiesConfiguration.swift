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
/// For the initial version every `web_view` is isolated from external sources: customers must
/// upload everything in a single bundle. The fixed policy blocks remote (third-party) images,
/// scripts and fonts while allowing same-origin assets, blocks `data:` images and fonts, and
/// blocks XHR (`raw`) loads entirely.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WebViewCapabilitiesConfiguration {

    /// Stable identifier used to cache the compiled `WKContentRuleList` for the fixed isolation
    /// policy. The policy never varies, so a single identifier is enough.
    static let contentRuleListIdentifier = "rc-webview-v1-isolation"

    /// The fixed content-blocking rules (as a JSON string) enforcing full isolation from external
    /// sources. `raw` is used for XHR (rather than the newer `fetch`/`websocket` resource types) so
    /// the list compiles on older OS versions; an unknown resource-type would fail the whole list
    /// closed.
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
            // Block inline `data:` images and fonts.
            [
                "trigger": [
                    "url-filter": "^data:",
                    "resource-type": ["image", "font"]
                ],
                "action": ["type": "block"]
            ],
            // Block XHR.
            [
                "trigger": [
                    "url-filter": ".*",
                    "resource-type": ["raw"]
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

/// Caches compiled `WKContentRuleList`s keyed by ``WebViewCapabilitiesConfiguration/contentRuleListIdentifier(for:)``.
///
/// Compilation is asynchronous, so this lets the web view pool stay non-blocking: a view that needs
/// network blocking can attach an already-compiled list synchronously (via ``cached(identifier:)``),
/// or defer its load until ``ruleList(forIdentifier:json:completion:)`` finishes compiling.
///
/// Accessed on the main thread only (`compileContentRuleList`'s completion handler is invoked there).
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewContentRuleListStore {

    static let shared = WebViewContentRuleListStore()

    private var cache: [String: WKContentRuleList] = [:]

    private init() {}

    /// Synchronously returns the compiled rule list for `identifier` if it was already compiled this
    /// session, otherwise `nil`.
    func cached(identifier: String) -> WKContentRuleList? {
        return self.cache[identifier]
    }

    /// Returns the compiled rule list for `identifier`, compiling `json` if it isn't cached yet.
    /// Completes on the main thread; `nil` indicates compilation failed (the caller should fail
    /// closed by blocking all requests).
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
