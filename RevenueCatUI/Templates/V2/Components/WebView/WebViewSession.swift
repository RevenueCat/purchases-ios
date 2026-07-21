//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

#if !os(tvOS) && canImport(WebKit) // For Paywalls V2

import Foundation
@_spi(Internal) import RevenueCat
import WebKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewSession: NSObject, ObservableObject, WKScriptMessageHandler {

    let componentID: String
    /// The canonical origin every message is gated against. Guaranteed valid by construction:
    /// callers resolve the origin (and skip creating the web view if it cannot be) before the
    /// session exists.
    let expectedOrigin: WebViewOrigin
    var onContentResize: (@MainActor (CGFloat?, CGFloat?) -> Void)?
    /// Invoked from ``resetForNewDocument()`` so the SwiftUI host can clear measured fit sizes.
    var onDocumentReset: (@MainActor () -> Void)?
    private(set) var channelOpen = false

    var evaluateJavaScript: (String) -> Void
    var currentURL: () -> URL?

    let fitAxes: (width: Bool, height: Bool)

    /// The single protocol version this SDK build implements. Deliberately not the schema's
    /// `protocol_version`: the host must never accept a handshake for a version it cannot service,
    /// even if a future schema declares one.
    private let protocolVersion = WebViewEnvelope.defaultProtocolVersion

    private var lastAppliedWidth: CGFloat?
    private var lastAppliedHeight: CGFloat?

    init(
        componentID: String,
        expectedOrigin: WebViewOrigin,
        fitAxes: (width: Bool, height: Bool),
        evaluateJavaScript: @escaping (String) -> Void,
        currentURL: @escaping () -> URL?
    ) {
        self.componentID = componentID
        self.expectedOrigin = expectedOrigin
        self.fitAxes = fitAxes
        self.evaluateJavaScript = evaluateJavaScript
        self.currentURL = currentURL
    }

    /// Resets handshake and resize thresholds for a new main-frame document.
    ///
    /// Each committed main-frame navigation creates a new JS document that must re-handshake.
    /// Without this, `connect` after a reload is dropped by the `channelOpen` guard forever.
    func resetForNewDocument() {
        self.channelOpen = false
        self.lastAppliedWidth = nil
        self.lastAppliedHeight = nil
        self.onDocumentReset?()
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        // Validate against the origin of the frame that actually posted the message, not the
        // WebView's top-level URL (which can lag behind navigations).
        let sourceOrigin = WebViewOrigin(securityOrigin: message.frameInfo.securityOrigin)?.value
        let isMainFrame = message.frameInfo.isMainFrame
        let body = message.body
        self.handle(rawMessage: body, isMainFrame: isMainFrame, sourceOrigin: sourceOrigin)
    }

    func handle(rawMessage: Any, isMainFrame: Bool, sourceOrigin: String?) {
        guard self.isSourceTrusted(sourceOrigin: sourceOrigin, isMainFrame: isMainFrame) else {
            self.logRejected("untrusted-source")
            return
        }
        guard let envelope = WebViewEnvelope.decode(rawMessage: rawMessage) else {
            self.logRejected("malformed-envelope")
            return
        }

        if envelope.kind == .connect {
            self.handleConnect(protocolVersion: envelope.protocolVersion)
            return
        }

        guard let type = self.validatedAppFrameType(envelope) else {
            return
        }

        switch type {
        case WebViewEnvelope.messageTypeResize:
            self.handleResize(envelope.payload)
        default:
            self.logRejected("unknown-message-type")
        }
    }

    /// Validates a post-handshake frame and returns its app message type, or `nil` (logged) when
    /// the frame must be dropped.
    private func validatedAppFrameType(_ envelope: WebViewEnvelope.Envelope) -> String? {
        guard self.channelOpen else {
            self.logRejected("channel-closed")
            return nil
        }
        // App frames ride only `message`/`request`; other kinds (init/reject/response/error)
        // are host-to-content or reply framing and must be dropped.
        guard envelope.kind == .message || envelope.kind == .request else {
            self.logRejected("unsupported-kind")
            return nil
        }
        if envelope.kind == .request, envelope.id == nil {
            self.logRejected("request-without-id")
            return nil
        }
        guard envelope.componentID == self.componentID else {
            self.logRejected("component-id-mismatch")
            return nil
        }
        guard let type = envelope.type else {
            self.logRejected("missing-type")
            return nil
        }
        return type
    }

    private func handleConnect(protocolVersion: Int) {
        guard !self.channelOpen else {
            return
        }

        if protocolVersion == self.protocolVersion {
            self.channelOpen = true
            // Handshake replies (`init` and the follow-up fit message) use `allowBeforeNavigation:
            // true`: the `connect` that triggered them was already gated against the authoritative
            // sender-frame origin, but the WebView's top-level `url` may not be populated yet this
            // early, and dropping these would leave the bridge half-open. The stricter current-URL
            // check still applies to every later send.
            self.send(.init(kind: .`init`, componentID: self.componentID), allowBeforeNavigation: true)
            self.sendFitMessageIfNeeded()
        } else {
            let error = "Unsupported protocol_version \(protocolVersion); " +
                "native host supports \(self.protocolVersion)"
            self.send(.init(kind: .reject, componentID: "", error: error), allowBeforeNavigation: true)
        }
    }

    private func handleResize(_ payload: [String: PaywallWebViewValue]?) {
        guard let payload else {
            return
        }

        let width = self.validResizeValue(payload["width"]?.numberValue, axisIsFit: self.fitAxes.width)
        let height = self.validResizeValue(payload["height"]?.numberValue, axisIsFit: self.fitAxes.height)
        let appliedWidth = self.resizeValue(width, lastApplied: &self.lastAppliedWidth)
        let appliedHeight = self.resizeValue(height, lastApplied: &self.lastAppliedHeight)

        if appliedWidth != nil || appliedHeight != nil {
            self.onContentResize?(appliedWidth, appliedHeight)
        }
    }

    private func sendFitMessageIfNeeded() {
        var payload: [String: PaywallWebViewValue] = [:]
        if self.fitAxes.width {
            payload["width"] = .bool(true)
        }
        if self.fitAxes.height {
            payload["height"] = .bool(true)
        }
        guard !payload.isEmpty else {
            return
        }
        self.send(
            .init(
                kind: .message,
                componentID: self.componentID,
                type: WebViewEnvelope.messageTypeFit,
                payload: payload
            ),
            allowBeforeNavigation: true
        )
    }

    private func send(_ envelope: WebViewEnvelope.Envelope, allowBeforeNavigation: Bool) {
        guard self.channelOpen || envelope.kind == .reject else {
            Logger.warning(Strings.paywall_web_view_post_message_skipped(reason: "channel-not-open"))
            return
        }
        // Defense in depth: drop outbound frames if the top-level URL left the expected origin.
        guard self.isCurrentURLTrusted(allowBeforeNavigation: allowBeforeNavigation) else {
            Logger.warning(Strings.paywall_web_view_post_message_skipped(reason: "untrusted-current-url"))
            return
        }
        guard let script = Self.receiveScript(for: envelope) else {
            Logger.debug(Strings.paywall_web_view_post_message_failed("encoding failed"))
            return
        }

        self.evaluateJavaScript(script)
    }

    /// Serializes `envelope` into the JS snippet injected into the web view to deliver a
    /// host-to-content frame. This is bridge/transport behavior, so it lives here rather than
    /// on the envelope data model.
    nonisolated static func receiveScript(for envelope: WebViewEnvelope.Envelope) -> String? {
        guard let data = try? JSONEncoder().encode(envelope),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        // Escape JS line terminators that are legal in JSON but not in JS string literals.
        let escaped = json
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028") // line separator
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029") // paragraph separator

        let receiveFunction = WebViewEnvelope.receiveFunction
        return """
        (function(){var m=\(escaped);if(typeof window.\(receiveFunction)==='function'){\
        window.\(receiveFunction)(m);}})();
        """
    }

    private func validResizeValue(_ value: Double?, axisIsFit: Bool) -> CGFloat? {
        guard axisIsFit,
              let value,
              value.isFinite,
              value > 0 else {
            return nil
        }

        return min(CGFloat(value), WebViewEnvelope.maxResizePoints)
    }

    private func resizeValue(_ value: CGFloat?, lastApplied: inout CGFloat?) -> CGFloat? {
        guard let value else {
            return nil
        }
        if let lastApplied, abs(value - lastApplied) < WebViewEnvelope.resizeThreshold {
            return nil
        }
        lastApplied = value
        return value
    }

    /// Whether the message came from the expected origin on the main frame. Uses the sender frame's
    /// origin (the authoritative source); subframe messages are always rejected — isolation for
    /// those is expected from the server CSP.
    private func isSourceTrusted(sourceOrigin: String?, isMainFrame: Bool) -> Bool {
        guard isMainFrame else {
            return false
        }
        return self.expectedOrigin.matches(originString: sourceOrigin)
    }

    /// Whether the WebView's current top-level URL still has the expected origin. Used only as an
    /// outbound defense-in-depth check; inbound traffic is gated by ``isSourceTrusted(sourceOrigin:isMainFrame:)``.
    private func isCurrentURLTrusted(allowBeforeNavigation: Bool) -> Bool {
        guard let currentURL = self.currentURL() else {
            return allowBeforeNavigation
        }
        return self.expectedOrigin.matches(url: currentURL)
    }

    private func logRejected(_ reason: String) {
        Logger.warning(Strings.paywall_web_view_message_rejected(reason: reason))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {

    weak var target: WKScriptMessageHandler?

    init(_ target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.target?.userContentController(userContentController, didReceive: message)
    }

}

#endif
