//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewComponentView.swift

@_spi(Internal) import RevenueCat
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(WebKit)
import WebKit
#endif

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WebViewComponentView: View {

    let viewModel: WebViewComponentViewModel

    init(viewModel: WebViewComponentViewModel) {
        self.viewModel = viewModel
    }

    #if canImport(UIKit) || os(macOS)
    @State private var dynamicHeight: CGFloat?
    #endif

    @Environment(\.paywallWebViewMessageAction)
    private var webViewMessageAction

    var body: some View {
        if viewModel.visible {
            self.content
        }
    }

    /// The current bidirectional-communication configuration for this `web_view`. Rebuilt on each
    /// `body` evaluation so SDK-managed variables and the app handler stay fresh as the environment
    /// changes.
    private var bridge: WebViewBridgeConfiguration {
        WebViewBridgeConfiguration(
            componentID: viewModel.componentID,
            protocolVersion: viewModel.protocolVersion,
            expectedURL: viewModel.url,
            messageAction: webViewMessageAction,
            baseVariables: PaywallWebViewVariables.base(locale: viewModel.locale),
            size: viewModel.size,
            onContentResize: { width, height in
                if case .fit = viewModel.size.height, let height {
                    dynamicHeight = height
                }
                if case .fit = viewModel.size.width, let width {
                    _ = width
                }
            }
        )
    }

    @ViewBuilder
    private var content: some View {
        #if canImport(UIKit) && canImport(WebKit)
        if let resolvedURL = viewModel.url {
            WebViewRepresentable(url: resolvedURL, height: $dynamicHeight, bridge: bridge)
                .modifier(WebViewSizeModifier(size: viewModel.size, measuredHeight: dynamicHeight))
                .clipped()
                .background(Color.clear)
        }
        #elseif os(macOS)
        if let resolvedURL = viewModel.url {
            let macHeight = dynamicHeight ?? Self.initialHeight
            MacWebViewRepresentable(url: resolvedURL, height: $dynamicHeight, bridge: bridge)
                .modifier(WebViewSizeModifier(size: viewModel.size, measuredHeight: macHeight))
                .clipped()
                .background(Color.clear)
        }
        // An invalid/unresolvable URL renders nothing.
        #else
        EmptyView()
        #endif
    }

}

// MARK: - Bidirectional communication bridge

/// Per-render configuration for the `web_view` postMessage bridge. Captured from the environment in
/// `WebViewComponentView.body` and refreshed into the coordinator on every `updateUIView`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WebViewBridgeConfiguration {

    /// The canonical `component_id`. When `nil` (legacy/partial config without an `id`) the message
    /// bridge is not installed.
    let componentID: String?
    let protocolVersion: Int
    let expectedURL: URL?
    let messageAction: PaywallWebViewMessageAction?

    /// SDK-managed variables sent automatically in response to `rc:request-variables`.
    let baseVariables: [String: PaywallWebViewValue]

    let size: PaywallComponent.Size
    let onContentResize: (CGFloat?, CGFloat?) -> Void

}

/// Builds the SDK-managed variable set exposed to web content. `WebKit`-free so it's unit-testable.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallWebViewVariables {

    /// The SDK-managed variables exposed to web content. Sending the paywall's custom variables is
    /// out of scope for v1; only `locale` is provided automatically.
    static func base(locale: Locale) -> [String: PaywallWebViewValue] {
        return ["locale": .string(self.bcp47Identifier(for: locale))]
    }

    static func bcp47Identifier(for locale: Locale) -> String {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return locale.identifier(.bcp47)
        } else {
            return locale.identifier.replacingOccurrences(of: "_", with: "-")
        }
    }

}

/// Dispatches validated inbound `web_view` transport frames. `WebKit`-free so it's unit-testable.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallWebViewMessageDispatcher {

    private static let maxResizeDimension: CGFloat = 10_000

    @MainActor
    static func handle(
        envelope: WebViewEnvelope.Parsed,
        componentID: String,
        protocolVersion: Int,
        controller: PaywallWebViewController,
        bridge: WebViewBridgeConfiguration
    ) {
        switch envelope.kind {
        case WebViewEnvelope.kindMessage, WebViewEnvelope.kindRequest:
            break
        default:
            return
        }

        if envelope.kind == WebViewEnvelope.kindMessage,
           envelope.type == PaywallWebViewMessageType.resize {
            Self.handleResize(envelope: envelope, bridge: bridge)
            return
        }

        let parser = PaywallWebViewMessageParser(expectedComponentID: componentID)
        switch parser.parseEnvelope(Self.envelopeDictionary(envelope)) {
        case .success(let parsed):
            if parsed.message.type == PaywallWebViewMessageType.requestVariables {
                Self.replyToVariablesRequest(
                    parsed: parsed,
                    controller: controller,
                    bridge: bridge,
                    protocolVersion: protocolVersion,
                    componentID: componentID
                )
            }
            bridge.messageAction?(parsed.message, controller)

        case .failure(let error):
            Logger.debug(Strings.paywall_web_view_message_rejected(reason: "\(error)"))
        }
    }

    @MainActor
    private static func replyToVariablesRequest(
        parsed: PaywallWebViewMessageParser.ParsedAppMessage,
        controller: PaywallWebViewController,
        bridge: WebViewBridgeConfiguration,
        protocolVersion: Int,
        componentID: String
    ) {
        if let requestID = parsed.requestID, let requestType = parsed.requestType {
            controller.deliverEnvelope(
                WebViewEnvelope.build(
                    kind: WebViewEnvelope.kindResponse,
                    protocolVersion: protocolVersion,
                    componentID: componentID,
                    type: requestType,
                    id: requestID,
                    payload: bridge.baseVariables
                )
            )
        } else {
            controller.deliverEnvelope(
                WebViewEnvelope.build(
                    kind: WebViewEnvelope.kindMessage,
                    protocolVersion: protocolVersion,
                    componentID: componentID,
                    type: PaywallWebViewMessageType.variables,
                    payload: bridge.baseVariables
                )
            )
        }
    }

    @MainActor
    private static func handleResize(
        envelope: WebViewEnvelope.Parsed,
        bridge: WebViewBridgeConfiguration
    ) {
        guard let payload = envelope.payload else {
            return
        }

        let width = Self.validatedDimension(payload["width"]?.numberValue)
        let height = Self.validatedDimension(payload["height"]?.numberValue)
        bridge.onContentResize(width, height)
    }

    private static func validatedDimension(_ value: Double?) -> CGFloat? {
        guard let value, value.isFinite, value > 0 else {
            return nil
        }

        return min(CGFloat(value), Self.maxResizeDimension)
    }

    private static func envelopeDictionary(_ envelope: WebViewEnvelope.Parsed) -> [String: Any] {
        var dictionary: [String: Any] = [
            WebViewEnvelope.Field.channel: WebViewEnvelope.channel,
            WebViewEnvelope.Field.protocolVersion: envelope.protocolVersion,
            WebViewEnvelope.Field.kind: envelope.kind,
            WebViewEnvelope.Field.componentID: envelope.componentID
        ]

        if let type = envelope.type {
            dictionary[WebViewEnvelope.Field.type] = type
        }
        if let id = envelope.id {
            dictionary[WebViewEnvelope.Field.id] = id
        }
        if let error = envelope.error {
            dictionary[WebViewEnvelope.Field.error] = error
        }
        if let payload = envelope.payload {
            dictionary[WebViewEnvelope.Field.payload] = PaywallWebViewValue.object(payload).jsonObject
        }

        return dictionary
    }

}

/// Applies the component's ``PaywallComponent/Size`` to the web view. For a `fit` height the
/// dynamically-measured web content height is used; other constraints follow the shared
/// Paywalls V2 sizing semantics.
// swiftlint:disable:next todo
// TODO: refine `fill`/`relative` height behavior to fully match `SizeModifier`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WebViewSizeModifier: ViewModifier {

    let size: PaywallComponent.Size
    let measuredHeight: CGFloat?

    func body(content: Content) -> some View {
        content
            .applyWebViewWidth(size.width)
            .applyWebViewHeight(size.height, measuredHeight: measuredHeight)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension View {

    @ViewBuilder
    func applyWebViewWidth(_ constraint: PaywallComponent.SizeConstraint) -> some View {
        switch constraint {
        case .fit:
            self
        case .fill:
            self.frame(maxWidth: .infinity)
        case .fixed(let value):
            self.frame(width: CGFloat(value))
        case .relative:
            self
        }
    }

    @ViewBuilder
    func applyWebViewHeight(_ constraint: PaywallComponent.SizeConstraint, measuredHeight: CGFloat?) -> some View {
        switch constraint {
        case .fit, .relative:
            self.frame(height: measuredHeight)
        case .fill:
            self.frame(maxHeight: .infinity)
        case .fixed(let value):
            self.frame(height: CGFloat(value))
        }
    }

}

#if canImport(UIKit) || os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WebViewComponentView {

    static let initialHeight: CGFloat = 100

}

#endif

#if canImport(WebKit)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallWebViewScripts {

    static let disableZoomUserScript: WKUserScript = {
        let source = """
        (function() {
          var content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
          var viewport = document.querySelector('meta[name="viewport"]');
          if (!viewport) {
            viewport = document.createElement('meta');
            viewport.name = 'viewport';
            document.head.appendChild(viewport);
          }
          viewport.setAttribute('content', content);
        })();
        """

        return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    }()

    /// Attaches the content-blocking rule list (compiling it if necessary), then loads `url`. The
    /// load is deferred until the rules are in place so no request is issued before isolation
    /// applies. Fails closed: if compilation fails the page is not loaded.
    static func loadIsolated(url: URL, on webView: WKWebView) {
        guard let json = WebViewCapabilitiesConfiguration.contentBlockingRules else {
            webView.load(URLRequest(url: url))
            return
        }

        WebViewContentRuleListStore.shared.ruleList(
            forIdentifier: WebViewCapabilitiesConfiguration.contentRuleListIdentifier,
            json: json
        ) { [weak webView] ruleList in
            guard let webView else { return }
            guard let ruleList else {
                return
            }
            webView.configuration.userContentController.add(ruleList)
            webView.load(URLRequest(url: url))
        }
    }

}

/// Holds a `WKScriptMessageHandler` weakly so the `WKUserContentController` (which retains its
/// handlers strongly) does not create a retain cycle with the coordinator that owns it.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {

    private weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        self.delegate?.userContentController(userContentController, didReceive: message)
    }

}

/// Source of the per-render bridge state a ``WebViewMessageBridge`` needs when a message arrives.
/// Implemented by the platform coordinators so the bridge can read the current configuration and
/// loaded URL without duplicating that state.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol WebViewBridgeHost: AnyObject {
    var bridge: WebViewBridgeConfiguration? { get }
    var currentURL: URL? { get }
    func resetMeasuredContentSize()
}

/// Bridges inbound `web_view` transport frames to ``PaywallWebViewMessageDispatcher``. Shared by
/// the iOS and macOS coordinators. The handler is installed only when the component has a stable `id`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewMessageBridge: NSObject, WKScriptMessageHandler {

    static let handlerName = WebViewEnvelope.messageHandlerName

    private weak var host: WebViewBridgeHost?
    private var messageHandler: WeakScriptMessageHandler?
    private var channelOpen = false

    init(host: WebViewBridgeHost) {
        self.host = host
    }

    func registerIfNeeded(on webView: WKWebView) {
        guard self.host?.bridge?.componentID != nil else {
            Logger.debug(Strings.paywall_web_view_missing_id)
            return
        }
        let handler = WeakScriptMessageHandler(delegate: self)
        self.messageHandler = handler
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Self.handlerName)
        webView.configuration.userContentController.add(handler, name: Self.handlerName)
    }

    func unregister(from webView: WKWebView) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Self.handlerName)
        self.messageHandler = nil
        self.channelOpen = false
    }

    func resetChannel() {
        self.channelOpen = false
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == Self.handlerName,
              let host = self.host,
              let bridge = host.bridge,
              let componentID = bridge.componentID,
              let webView = message.webView else {
            return
        }

        guard message.frameInfo.isMainFrame else {
            Logger.debug(Strings.paywall_web_view_message_rejected(reason: "message not from the main frame"))
            return
        }

        guard let dictionary = Self.dictionary(from: message.body) else {
            Logger.debug(Strings.paywall_web_view_message_rejected(reason: "invalid envelope"))
            return
        }

        guard JSONSerialization.isValidJSONObject(dictionary),
              let serialized = try? JSONSerialization.data(withJSONObject: dictionary),
              serialized.count <= PaywallWebViewMessageParser.maxPayloadBytes else {
            Logger.debug(Strings.paywall_web_view_message_rejected(reason: "oversized or invalid payload"))
            return
        }

        guard let envelope = WebViewEnvelope.parse(dictionary) else {
            Logger.debug(Strings.paywall_web_view_message_rejected(reason: "invalid envelope"))
            return
        }

        let expectedURL = bridge.expectedURL ?? host.currentURL
        let allowBeforeNavigation = envelope.kind == WebViewEnvelope.kindConnect
        guard WebViewOrigin.matches(
            currentURL: webView.url,
            expectedURL: expectedURL,
            allowBeforeNavigation: allowBeforeNavigation
        ) else {
            Logger.debug(Strings.paywall_web_view_message_rejected(reason: "origin mismatch"))
            return
        }

        if envelope.kind == WebViewEnvelope.kindConnect {
            self.handleConnect(envelope: envelope, webView: webView, bridge: bridge, componentID: componentID)
            return
        }

        guard self.channelOpen else {
            Logger.debug(Strings.paywall_web_view_message_rejected(reason: "channel not open"))
            return
        }

        if envelope.componentID != componentID {
            Logger.debug(Strings.paywall_web_view_message_rejected(reason: "component_id mismatch"))
            return
        }

        let controller = PaywallWebViewController(
            webView: webView,
            componentID: componentID,
            expectedLoadedURL: expectedURL,
            protocolVersion: bridge.protocolVersion,
            channelOpen: { self.channelOpen }
        )

        PaywallWebViewMessageDispatcher.handle(
            envelope: envelope,
            componentID: componentID,
            protocolVersion: bridge.protocolVersion,
            controller: controller,
            bridge: bridge
        )
    }

    private func handleConnect(
        envelope: WebViewEnvelope.Parsed,
        webView: WKWebView,
        bridge: WebViewBridgeConfiguration,
        componentID: String
    ) {
        guard !self.channelOpen else {
            return
        }

        if envelope.protocolVersion != bridge.protocolVersion {
            self.deliver(
                WebViewEnvelope.build(
                    kind: WebViewEnvelope.kindReject,
                    protocolVersion: bridge.protocolVersion,
                    componentID: "",
                    error: "Unsupported protocol_version \(envelope.protocolVersion); " +
                        "native host supports \(bridge.protocolVersion)"
                ),
                to: webView,
                expectedURL: bridge.expectedURL,
                allowBeforeNavigation: true
            )
            return
        }

        self.channelOpen = true
        self.deliver(
            WebViewEnvelope.build(
                kind: WebViewEnvelope.kindInit,
                protocolVersion: bridge.protocolVersion,
                componentID: componentID
            ),
            to: webView,
            expectedURL: bridge.expectedURL,
            allowBeforeNavigation: true
        )
    }

    private func deliver(
        _ envelope: [String: PaywallWebViewValue],
        to webView: WKWebView,
        expectedURL: URL?,
        allowBeforeNavigation: Bool
    ) {
        guard WebViewOrigin.matches(
            currentURL: webView.url,
            expectedURL: expectedURL,
            allowBeforeNavigation: allowBeforeNavigation
        ) else {
            return
        }

        guard let script = PaywallWebViewController.receiveEnvelopeScript(envelope: envelope) else {
            return
        }

        webView.evaluateJavaScript(script)
    }

    private static func dictionary(from body: Any) -> [String: Any]? {
        if let dictionary = body as? [String: Any] {
            return dictionary
        }

        if let jsonString = body as? String,
           let data = jsonString.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return object
        }

        return nil
    }

}

#endif

#if canImport(UIKit) && canImport(WebKit)

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
private struct WebViewRepresentable: UIViewRepresentable {

    let url: URL
    @Binding var height: CGFloat?
    let bridge: WebViewBridgeConfiguration

    func makeUIView(context: Context) -> WKWebView {
        let webView = AutoSizingWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.backgroundColor = .clear
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.contentInset = .zero
        webView.scrollView.bouncesZoom = false
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.scrollView.delegate = context.coordinator

        context.coordinator.bridge = bridge
        context.coordinator.registerMessageBridgeIfNeeded(on: webView)
        context.coordinator.currentURL = url
        if height == nil, case .fit = bridge.size.height {
            height = WebViewComponentView.initialHeight
        }
        PaywallWebViewScripts.loadIsolated(url: url, on: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.bridge = bridge

        if context.coordinator.currentURL != url {
            context.coordinator.currentURL = url
            context.coordinator.resetMeasuredContentSize()
            context.coordinator.messageBridge.resetChannel()
            uiView.load(URLRequest(url: url))
        }

        if let height, let autoSizingWebView = uiView as? AutoSizingWebView {
            autoSizingWebView.setContentHeight(height)
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.unregisterMessageBridge(from: uiView)
        uiView.navigationDelegate = nil
        uiView.scrollView.delegate = nil
        uiView.stopLoading()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(height: $height)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate, WebViewBridgeHost {

        @Binding var height: CGFloat?
        var currentURL: URL?
        var bridge: WebViewBridgeConfiguration?

        fileprivate lazy var messageBridge = WebViewMessageBridge(host: self)

        init(height: Binding<CGFloat?>) {
            _height = height
        }

        func resetMeasuredContentSize() {
            self.height = nil
        }

        func registerMessageBridgeIfNeeded(on webView: WKWebView) {
            self.messageBridge.registerIfNeeded(on: webView)
        }

        func unregisterMessageBridge(from webView: WKWebView) {
            self.messageBridge.unregister(from: webView)
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return nil
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            scrollView.zoomScale = 1.0
        }

    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class AutoSizingWebView: WKWebView {

    private var contentHeight: CGFloat = 0

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: self.contentHeight)
    }

    func setContentHeight(_ height: CGFloat) {
        guard abs(self.contentHeight - height) > 0.5 else { return }
        self.contentHeight = height
        self.invalidateIntrinsicContentSize()
    }

    init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.allowsInlineMediaPlayback = true
        config.userContentController.addUserScript(PaywallWebViewScripts.disableZoomUserScript)
        super.init(frame: .zero, configuration: config)
        isOpaque = false
        backgroundColor = .clear
        scrollView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

}

#endif // canImport(UIKit) && canImport(WebKit)

#if os(macOS) && canImport(WebKit)

@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct MacWebViewRepresentable: NSViewRepresentable {

    let url: URL
    @Binding var height: CGFloat?
    let bridge: WebViewBridgeConfiguration

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: Self.makeConfiguration())
        webView.navigationDelegate = context.coordinator
        context.coordinator.bridge = bridge
        context.coordinator.registerMessageBridgeIfNeeded(on: webView)
        context.coordinator.currentURL = url
        if height == nil, case .fit = bridge.size.height {
            height = WebViewComponentView.initialHeight
        }
        PaywallWebViewScripts.loadIsolated(url: url, on: webView)

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.bridge = bridge

        if context.coordinator.currentURL != url {
            context.coordinator.currentURL = url
            context.coordinator.resetMeasuredContentSize()
            context.coordinator.messageBridge.resetChannel()
            nsView.load(URLRequest(url: url))
        }
    }

    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        coordinator.unregisterMessageBridge(from: nsView)
        nsView.navigationDelegate = nil
        nsView.stopLoading()
        nsView.configuration.websiteDataStore.removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: .distantPast
        ) {}
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(height: $height)
    }

    private static func makeConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        // macOS WKWebView does not support pinch-zoom on scroll views the way iOS does; viewport
        // meta injection is unnecessary for zoom parity.
        config.userContentController.addUserScript(PaywallWebViewScripts.disableZoomUserScript)

        return config
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WebViewBridgeHost {

        @Binding var height: CGFloat?
        var currentURL: URL?
        var bridge: WebViewBridgeConfiguration?

        fileprivate lazy var messageBridge = WebViewMessageBridge(host: self)

        init(height: Binding<CGFloat?>) {
            _height = height
        }

        func resetMeasuredContentSize() {
            self.height = nil
        }

        func registerMessageBridgeIfNeeded(on webView: WKWebView) {
            self.messageBridge.registerIfNeeded(on: webView)
        }

        func unregisterMessageBridge(from webView: WKWebView) {
            self.messageBridge.unregister(from: webView)
        }

    }

}

#endif // os(macOS) && canImport(WebKit)

#endif // !os(tvOS)
