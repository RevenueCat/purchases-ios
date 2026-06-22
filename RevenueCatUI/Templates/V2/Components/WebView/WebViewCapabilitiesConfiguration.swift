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

/// WebKit-free decision logic for `web_view` capabilities. Kept separate from the WKWebView
/// rendering code so it can be unit-tested without instantiating a web view.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WebViewCapabilitiesConfiguration {

    /// Stable identifier used to cache the compiled `WKContentRuleList` for a given
    /// `network_access` declaration. Derived from the sorted `allowed_domains` so the same set of
    /// domains always maps to the same compiled rule list. `nil` when `network_access` is absent.
    static func contentRuleListIdentifier(
        for networkAccess: PaywallComponent.WebViewCapabilities.NetworkAccess?
    ) -> String? {
        guard let networkAccess else { return nil }

        let domains = (networkAccess.allowedDomains ?? []).sorted()
        guard !domains.isEmpty else {
            return "rc-webview-block-all"
        }

        return "rc-webview-allow-" + domains.joined(separator: ",")
    }

    /// Content-blocking rules (as a JSON string) enforcing `network_access`:
    /// - `nil` `network_access` → `nil` (no rules installed, the secure default applies elsewhere)
    /// - empty `allowed_domains` → a single block-all rule with no `unless-domain`
    /// - non-empty → a single block rule whose `unless-domain` lists every allowed domain (sorted,
    ///   so the output is deterministic and matches ``contentRuleListIdentifier(for:)``)
    static func contentBlockingRules(
        for networkAccess: PaywallComponent.WebViewCapabilities.NetworkAccess?
    ) -> String? {
        guard let networkAccess else { return nil }

        let domains = (networkAccess.allowedDomains ?? []).sorted()

        var trigger: [String: Any] = ["url-filter": ".*"]
        if !domains.isEmpty {
            trigger["unless-domain"] = domains
        }

        let rules: [[String: Any]] = [
            [
                "trigger": trigger,
                "action": ["type": "block"]
            ]
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: rules),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }

        return json
    }

    /// Maps a media-capture request to a grant/deny decision based on the declared capabilities.
    /// Camera and microphone are granted only when the matching field is explicitly `true`;
    /// `.cameraAndMicrophone` requires both. Unknown types are denied.
    @available(iOS 15.0, macOS 12.0, *)
    static func mediaCaptureDecision(
        type: WKMediaCaptureType,
        capabilities: PaywallComponent.WebViewCapabilities?
    ) -> WKPermissionDecision {
        switch type {
        case .camera:
            return capabilities?.camera == true ? .grant : .deny
        case .microphone:
            return capabilities?.microphone == true ? .grant : .deny
        case .cameraAndMicrophone:
            let allow = capabilities?.camera == true && capabilities?.microphone == true
            return allow ? .grant : .deny
        @unknown default:
            return .deny
        }
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
