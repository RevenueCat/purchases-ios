import Foundation
@_spi(Internal) import RevenueCat

#if canImport(WebKit)
import WebKit
#endif

#if !os(tvOS) && canImport(WebKit) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewSession: NSObject, ObservableObject, WKScriptMessageHandler {

    let componentID: String
    let protocolVersion: Int
    let expectedOrigin: String
    var messageHandler: PaywallWebViewMessageAction?
    var onContentResize: (@MainActor (CGFloat?, CGFloat?) -> Void)?
    private(set) var channelOpen = false

    var evaluateJavaScript: (String) -> Void
    var currentURL: () -> URL?

    let fitAxes: (width: Bool, height: Bool)

    private let localeIdentifier: String
    private var lastAppliedWidth: CGFloat?
    private var lastAppliedHeight: CGFloat?

    init(
        componentID: String,
        protocolVersion: Int,
        expectedOrigin: String,
        localeIdentifier: String,
        fitAxes: (width: Bool, height: Bool),
        messageHandler: PaywallWebViewMessageAction? = nil,
        evaluateJavaScript: @escaping (String) -> Void = { _ in },
        currentURL: @escaping () -> URL? = { nil }
    ) {
        self.componentID = componentID
        self.protocolVersion = protocolVersion
        self.expectedOrigin = expectedOrigin
        self.localeIdentifier = localeIdentifier
        self.fitAxes = fitAxes
        self.messageHandler = messageHandler
        self.evaluateJavaScript = evaluateJavaScript
        self.currentURL = currentURL
    }

    nonisolated func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        MainActor.assumeIsolated {
            self.handle(
                rawMessage: message.body,
                isMainFrame: message.frameInfo.isMainFrame,
                currentURL: message.webView?.url
            )
        }
    }

    func handle(rawMessage: Any, isMainFrame: Bool, currentURL: URL?) {
        guard isMainFrame else {
            self.logRejected("non-main-frame")
            return
        }
        guard let envelope = WebViewEnvelope.decode(rawMessage: rawMessage) else {
            self.logRejected("malformed-envelope")
            return
        }

        if envelope.kind == .connect {
            self.handleConnect(envelope, currentURL: currentURL)
            return
        }

        guard let type = self.validatedAppFrameType(envelope, currentURL: currentURL) else {
            return
        }

        switch type {
        case WebViewEnvelope.messageTypeResize:
            // SDK-internal, regardless of kind; never forwarded to the app handler.
            self.handleResize(envelope.payload)
        case WebViewEnvelope.messageTypeStepLoaded:
            self.deliver(type: type)
        case WebViewEnvelope.messageTypeStepComplete:
            self.handleStepComplete(envelope)
        case WebViewEnvelope.messageTypeRequestVariables:
            self.handleRequestVariables(envelope)
        case WebViewEnvelope.messageTypeError:
            self.handleError(envelope)
        default:
            self.logRejected("unknown-message-type")
        }
    }

    /// Validates a post-handshake frame and returns its app message type, or `nil` (logged) when
    /// the frame must be dropped.
    private func validatedAppFrameType(
        _ envelope: WebViewEnvelope.Envelope,
        currentURL: URL?
    ) -> String? {
        guard self.channelOpen else {
            self.logRejected("channel-closed")
            return nil
        }
        // App frames ride only `message`/`request`; other kinds (init/reject/response/error)
        // are host-to-content or reply framing and must never reach the app handler.
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
        guard self.originMatches(currentURL: currentURL, allowBeforeNavigation: false) else {
            self.logRejected("origin-mismatch")
            return nil
        }
        guard let type = envelope.type else {
            self.logRejected("missing-type")
            return nil
        }
        return type
    }

    func postVariables(componentID: String, variables: [String: PaywallWebViewValue]) {
        self.post(
            componentID: componentID,
            type: WebViewEnvelope.messageTypeVariables,
            variables: Self.sanitizeAppProvidedVariables(variables)
        )
    }

    func post(componentID: String, type: String, variables: [String: PaywallWebViewValue]) {
        self.send(
            .init(kind: .message, componentID: componentID, type: type, payload: variables),
            allowBeforeNavigation: false
        )
    }

    static func sanitizeAppProvidedVariables(
        _ variables: [String: PaywallWebViewValue]
    ) -> [String: PaywallWebViewValue] {
        guard variables.keys.contains("locale") else {
            return variables
        }

        Logger.debug(Strings.paywall_web_view_reserved_locale_stripped)
        return variables.filter { $0.key != "locale" }
    }

    private func handleConnect(_ envelope: WebViewEnvelope.Envelope, currentURL: URL?) {
        guard self.originMatches(currentURL: currentURL, allowBeforeNavigation: true) else {
            self.logRejected("origin-mismatch")
            return
        }
        guard !self.channelOpen else {
            return
        }

        if envelope.protocolVersion == WebViewEnvelope.defaultProtocolVersion {
            self.channelOpen = true
            self.send(.init(kind: .`init`, componentID: self.componentID), allowBeforeNavigation: true)
            self.sendFitMessageIfNeeded()
        } else {
            let error = "Unsupported protocol_version \(envelope.protocolVersion); native host supports 1"
            self.send(.init(kind: .reject, componentID: "", error: error), allowBeforeNavigation: true)
        }
    }

    private func handleStepComplete(_ envelope: WebViewEnvelope.Envelope) {
        let responses: [String: PaywallWebViewValue]
        if let value = envelope.payload?["responses"] {
            guard let object = value.objectValue else {
                self.logRejected("malformed-responses")
                return
            }
            responses = object
        } else if let payload = envelope.payload {
            guard WebViewEnvelope.reservedPayloadKeys.isDisjoint(with: payload.keys) else {
                self.logRejected("reserved-response-key")
                return
            }
            responses = payload
        } else {
            responses = [:]
        }

        self.deliver(type: WebViewEnvelope.messageTypeStepComplete, responses: responses)
    }

    private func handleRequestVariables(_ envelope: WebViewEnvelope.Envelope) {
        switch envelope.kind {
        case .request:
            guard let id = envelope.id else {
                self.logRejected("request-without-id")
                return
            }
            self.send(
                .init(
                    kind: .response,
                    componentID: self.componentID,
                    type: WebViewEnvelope.messageTypeRequestVariables,
                    id: id,
                    payload: self.sdkVariables
                ),
                allowBeforeNavigation: false
            )
        case .message:
            self.send(
                .init(
                    kind: .message,
                    componentID: self.componentID,
                    type: WebViewEnvelope.messageTypeVariables,
                    payload: self.sdkVariables
                ),
                allowBeforeNavigation: false
            )
        default:
            self.logRejected("unsupported-request-variables-kind")
            return
        }

        self.deliver(type: WebViewEnvelope.messageTypeRequestVariables)
    }

    private func handleError(_ envelope: WebViewEnvelope.Envelope) {
        let error = envelope.payload?["error"]?.stringValue ?? envelope.error
        guard let error else {
            self.logRejected("missing-error")
            return
        }
        self.deliver(type: WebViewEnvelope.messageTypeError, error: error)
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

    private func deliver(
        type: String,
        responses: [String: PaywallWebViewValue]? = nil,
        error: String? = nil
    ) {
        self.messageHandler?(
            PaywallWebViewMessage(
                componentID: self.componentID,
                type: type,
                responses: responses,
                error: error
            ),
            PaywallWebViewController(session: self)
        )
    }

    private func send(_ envelope: WebViewEnvelope.Envelope, allowBeforeNavigation: Bool) {
        guard self.channelOpen || envelope.kind == .reject else {
            Logger.debug(Strings.paywall_web_view_post_message_skipped)
            return
        }
        guard self.originMatches(currentURL: self.currentURL(), allowBeforeNavigation: allowBeforeNavigation) else {
            Logger.debug(Strings.paywall_web_view_post_message_skipped)
            return
        }
        guard let script = WebViewEnvelope.receiveScript(for: envelope) else {
            Logger.debug(Strings.paywall_web_view_post_message_failed("encoding failed"))
            return
        }

        self.evaluateJavaScript(script)
    }

    private var sdkVariables: [String: PaywallWebViewValue] {
        ["locale": .string(Self.bcp47Tag(fromLocaleIdentifier: self.localeIdentifier))]
    }

    nonisolated static func bcp47Tag(fromLocaleIdentifier identifier: String) -> String {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return Locale(identifier: identifier).identifier(.bcp47)
        } else {
            return identifier.replacingOccurrences(of: "_", with: "-")
        }
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

    private func originMatches(currentURL: URL?, allowBeforeNavigation: Bool) -> Bool {
        guard let currentURL else {
            return allowBeforeNavigation
        }
        return Self.origin(of: currentURL) == self.expectedOrigin
    }

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

    private func logRejected(_ reason: String) {
        Logger.debug(Strings.paywall_web_view_message_rejected(reason: reason))
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
