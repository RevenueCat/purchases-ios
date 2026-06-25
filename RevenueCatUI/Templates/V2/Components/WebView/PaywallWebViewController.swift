//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallWebViewController.swift

import Foundation
@_spi(Internal) import RevenueCat

#if canImport(WebKit)
import WebKit
#endif

#if !os(tvOS) // For Paywalls V2

/// A handle, passed to your `View/onPaywallWebViewMessage(_:)` handler, for sending messages from
/// native code back into a Paywalls V2 `web_view` component.
///
/// Use it to reply to a `"rc:request-variables"` message with additional variables, or to send any
/// message that follows the web view protocol envelope. Messages are delivered to the web content
/// via `window.__revenueCatReceiveMessage(...)`.
///
/// Modeled as a concrete `struct` (rather than a protocol) following the SDK convention for
/// callback-supplied action handles, so methods can be added without a source-breaking change.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public struct PaywallWebViewController {

    #if canImport(WebKit)
    private weak var webView: WKWebView?
    #endif

    private let componentID: String
    private let expectedLoadedURL: URL?

    #if canImport(WebKit)
    init(webView: WKWebView?, componentID: String, expectedLoadedURL: URL?) {
        self.webView = webView
        self.componentID = componentID
        self.expectedLoadedURL = expectedLoadedURL
    }
    #else
    init(componentID: String, expectedLoadedURL: URL?) {
        self.componentID = componentID
        self.expectedLoadedURL = expectedLoadedURL
    }
    #endif

    /// Sends an `"rc:variables"` message to the web content.
    ///
    /// - Parameters:
    ///   - componentID: The component to address. Should match the `componentID` of the message you
    ///     are replying to.
    ///   - variables: The variables to deliver to the web content. The `"locale"` top-level key is
    ///     SDK-managed and reserved.
    public func postVariables(
        componentID: String,
        variables: [String: PaywallWebViewValue]
    ) {
        self.postMessage(
            componentID: componentID,
            type: PaywallWebViewMessageType.variables,
            variables: variables
        )
    }

    /// Sends a message to the web content following the web view protocol envelope
    /// `{ "type", "component_id", "variables" }`.
    ///
    /// - Parameters:
    ///   - componentID: The component to address.
    ///   - type: The message type, e.g. `"rc:variables"`.
    ///   - variables: The message payload, delivered under the `"variables"` key.
    public func postMessage(
        componentID: String,
        type: String,
        variables: [String: PaywallWebViewValue]
    ) {
        guard let script = Self.receiveMessageScript(
            componentID: componentID,
            type: type,
            variables: variables
        ) else {
            return
        }

        self.evaluate(script: script)
    }

    /// Builds the envelope `{ "type", "component_id", "variables" }` and wraps it in a guarded call
    /// to `window.__revenueCatReceiveMessage`. The JSON is produced by `JSONSerialization`, never
    /// string-interpolated from raw values, so app- or web-supplied strings cannot break out of the
    /// call. Internal for testability.
    static func receiveMessageScript(
        componentID: String,
        type: String,
        variables: [String: PaywallWebViewValue]
    ) -> String? {
        let envelope: [String: PaywallWebViewValue] = [
            "type": .string(type),
            "component_id": .string(componentID),
            "variables": .object(variables)
        ]

        let jsonObject = PaywallWebViewValue.object(envelope).jsonObject
        guard let data = try? JSONSerialization.data(withJSONObject: jsonObject),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }

        return """
        (function(){var m=\(json);if(typeof window.__revenueCatReceiveMessage==='function'){\
        window.__revenueCatReceiveMessage(m);}})();
        """
    }

    private func evaluate(script: String) {
        #if canImport(WebKit)
        guard let webView = self.webView,
              self.expectedLoadedURL == nil || webView.url == self.expectedLoadedURL else {
            // The web view was deallocated or navigated elsewhere — don't post into
            // unrelated content.
            Logger.debug(Strings.paywall_web_view_post_message_skipped)
            return
        }

        webView.evaluateJavaScript(script) { _, error in
            if let error {
                Logger.debug(Strings.paywall_web_view_post_message_failed(error))
            }
        }
        #endif
    }

}

#endif
