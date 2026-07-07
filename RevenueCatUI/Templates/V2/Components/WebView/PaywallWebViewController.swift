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
/// via `window.__rcWebComponentsReceive(...)`.
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
    private let protocolVersion: Int
    private let channelOpen: () -> Bool
    internal var envelopeDeliveryHandler: (([String: PaywallWebViewValue]) -> Void)?

    #if canImport(WebKit)
    init(
        webView: WKWebView?,
        componentID: String,
        expectedLoadedURL: URL?,
        protocolVersion: Int,
        channelOpen: @escaping () -> Bool
    ) {
        self.webView = webView
        self.componentID = componentID
        self.expectedLoadedURL = expectedLoadedURL
        self.protocolVersion = protocolVersion
        self.channelOpen = channelOpen
    }
    #else
    init(
        componentID: String,
        expectedLoadedURL: URL?,
        protocolVersion: Int,
        channelOpen: @escaping () -> Bool
    ) {
        self.componentID = componentID
        self.expectedLoadedURL = expectedLoadedURL
        self.protocolVersion = protocolVersion
        self.channelOpen = channelOpen
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
            variables: Self.sanitizeAppProvidedVariables(variables)
        )
    }

    /// Sends a message to the web content using the canonical transport envelope.
    ///
    /// - Parameters:
    ///   - componentID: The component to address.
    ///   - type: The message type, e.g. `"rc:variables"`.
    ///   - variables: The message payload, delivered flat in the envelope `payload` field.
    public func postMessage(
        componentID: String,
        type: String,
        variables: [String: PaywallWebViewValue]
    ) {
        guard self.channelOpen() else {
            return
        }

        let envelope = WebViewEnvelope.build(
            kind: WebViewEnvelope.kindMessage,
            protocolVersion: self.protocolVersion,
            componentID: componentID,
            type: type,
            payload: variables
        )

        guard let script = Self.receiveEnvelopeScript(envelope: envelope) else {
            return
        }

        self.evaluate(script: script)
    }

    /// Builds a guarded call to `window.__rcWebComponentsReceive` for the given transport envelope.
    /// Internal for testability.
    static func receiveEnvelopeScript(envelope: [String: PaywallWebViewValue]) -> String? {
        let jsonObject = PaywallWebViewValue.object(envelope).jsonObject
        guard let data = try? JSONSerialization.data(withJSONObject: jsonObject),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }

        let escaped = Self.escapeForJavaScript(json)
        return """
        (function(){var m=\(escaped);if(typeof window.\(WebViewEnvelope.receiveFunction)==='function'){\
        window.\(WebViewEnvelope.receiveFunction)(m);}})();
        """
    }

    /// Strips SDK-managed keys from app-provided variable maps.
    static func sanitizeAppProvidedVariables(
        _ variables: [String: PaywallWebViewValue]
    ) -> [String: PaywallWebViewValue] {
        guard variables.keys.contains("locale") else {
            return variables
        }

        Logger.debug(Strings.paywall_web_view_reserved_locale_stripped)
        return variables.filter { $0.key != "locale" }
    }

    /// Delivers a pre-built transport envelope to the web content.
    func deliverEnvelope(_ envelope: [String: PaywallWebViewValue]) {
        guard self.channelOpen() else {
            return
        }

        guard let script = Self.receiveEnvelopeScript(envelope: envelope) else {
            return
        }

        self.envelopeDeliveryHandler?(envelope)
        self.evaluate(script: script)
    }

    private func evaluate(script: String) {
        #if canImport(WebKit)
        guard let webView = self.webView,
              WebViewOrigin.matches(
                currentURL: webView.url,
                expectedURL: self.expectedLoadedURL,
                allowBeforeNavigation: false
              ) else {
            Logger.debug(Strings.paywall_web_view_post_message_skipped)
            return
        }

        webView.evaluateJavaScript(script) { _, error in
            if let error {
                Logger.debug(Strings.paywall_web_view_post_message_failed(error))
            }
        }
        #else
        _ = script
        #endif
    }

    /// JSON is a subset of JS object-literal syntax, but U+2028/U+2029 are valid in JSON strings
    /// yet terminate JS statements. Escape them so the payload is safe to embed.
    private static func escapeForJavaScript(_ json: String) -> String {
        json
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
    }

}

#endif
