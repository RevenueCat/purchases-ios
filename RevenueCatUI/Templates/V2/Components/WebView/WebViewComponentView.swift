@_spi(Internal) import RevenueCat
import SwiftUI

#if canImport(WebKit)
import WebKit
#endif

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WebViewComponentView: View {

    let viewModel: WebViewComponentViewModel

    @Environment(\.paywallWebViewMessageAction)
    private var messageHandler

    var body: some View {
        #if os(watchOS) || !canImport(WebKit)
        EmptyView()
        #else
        if viewModel.visible, let url = viewModel.url {
            if let componentID = viewModel.componentID {
                BridgedWebViewComponentView(
                    viewModel: viewModel,
                    url: url,
                    componentID: componentID,
                    messageHandler: messageHandler
                )
                .id("\(viewModel.urlString)-\(componentID)")
            } else {
                RenderOnlyWebViewComponentView(viewModel: viewModel, url: url)
                    .id("\(viewModel.urlString)-render-only")
                    .onAppear {
                        Logger.debug(Strings.paywall_web_view_missing_id)
                    }
            }
        }
        #endif
    }

}

#if canImport(WebKit) && !os(watchOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct BridgedWebViewComponentView: View {

    let viewModel: WebViewComponentViewModel
    let url: URL
    let componentID: String
    let messageHandler: PaywallWebViewMessageAction?

    @StateObject
    private var session: WebViewSession

    @State
    private var measuredWidth: CGFloat?

    @State
    private var measuredHeight: CGFloat?

    init(
        viewModel: WebViewComponentViewModel,
        url: URL,
        componentID: String,
        messageHandler: PaywallWebViewMessageAction?
    ) {
        self.viewModel = viewModel
        self.url = url
        self.componentID = componentID
        self.messageHandler = messageHandler

        let origin = WebViewSession.origin(of: url) ?? ""
        self._session = StateObject(
            wrappedValue: WebViewSession(
                componentID: componentID,
                protocolVersion: viewModel.protocolVersion,
                expectedOrigin: origin,
                localeIdentifier: viewModel.locale.identifier,
                fitAxes: (
                    width: viewModel.size.width == .fit,
                    height: viewModel.size.height == .fit
                )
            )
        )
    }

    var body: some View {
        // The handler and resize sink are (re)assigned inside the representable's make/update
        // (not `.onAppear`) so a handler swapped into the environment after first appearance —
        // or a connect arriving before `.onAppear` fires — always sees the current values.
        WebViewRepresentable(
            url: url,
            expectedOrigin: session.expectedOrigin,
            session: session,
            messageHandler: messageHandler,
            onContentResize: { width, height in
                if let width {
                    self.measuredWidth = width
                }
                if let height {
                    self.measuredHeight = height
                }
            }
        )
        .webViewSize(viewModel.size, measuredWidth: measuredWidth, measuredHeight: measuredHeight)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct RenderOnlyWebViewComponentView: View {

    let viewModel: WebViewComponentViewModel
    let url: URL

    var body: some View {
        WebViewRepresentable(
            url: url,
            expectedOrigin: WebViewSession.origin(of: url) ?? "",
            session: nil
        )
        .webViewSize(viewModel.size, measuredWidth: nil, measuredHeight: nil)
    }

}

#if os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
typealias PlatformWebView = WKWebView
#else
typealias PlatformViewRepresentable = UIViewRepresentable
typealias PlatformWebView = WKWebView
#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WebViewRepresentable: PlatformViewRepresentable {

    let url: URL
    let expectedOrigin: String
    weak var session: WebViewSession?
    var messageHandler: PaywallWebViewMessageAction?
    var onContentResize: (@MainActor (CGFloat?, CGFloat?) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(expectedOrigin: expectedOrigin)
    }

    #if os(macOS)
    func makeNSView(context: Context) -> PlatformWebView {
        self.makeWebView(context: context)
    }

    func updateNSView(_ webView: PlatformWebView, context: Context) {
        self.update(webView)
    }

    static func dismantleNSView(_ webView: PlatformWebView, coordinator: Coordinator) {
        dismantle(webView)
    }
    #else
    func makeUIView(context: Context) -> PlatformWebView {
        self.makeWebView(context: context)
    }

    func updateUIView(_ webView: PlatformWebView, context: Context) {
        self.update(webView)
    }

    static func dismantleUIView(_ webView: PlatformWebView, coordinator: Coordinator) {
        dismantle(webView)
    }
    #endif

    private func makeWebView(context: Context) -> PlatformWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.userContentController = WKUserContentController()

        if let session {
            configuration.userContentController.add(
                WeakScriptMessageHandler(session),
                name: WebViewEnvelope.messageHandlerName
            )
        }

        #if os(iOS)
        configuration.allowsInlineMediaPlayback = true
        let disableZoomScript = """
        var meta=document.querySelector('meta[name=viewport]');
        if(!meta){meta=document.createElement('meta');meta.name='viewport';document.head.appendChild(meta);}
        meta.content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        """
        configuration.userContentController.addUserScript(
            WKUserScript(source: disableZoomScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        )
        #endif

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator

        #if os(macOS)
        // There is no public AppKit API for a fully transparent WKWebView background;
        // `drawsBackground` via KVC is the long-standing, widely-used workaround
        // (`underPageBackgroundColor` only affects the under-page area, not the page background).
        webView.setValue(false, forKey: "drawsBackground")
        #else
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.minimumZoomScale = 1
        webView.scrollView.maximumZoomScale = 1
        #endif

        self.configureSession(for: webView)
        self.load(webView)
        return webView
    }

    private func update(_ webView: PlatformWebView) {
        self.configureSession(for: webView)
    }

    private func configureSession(for webView: PlatformWebView) {
        self.session?.messageHandler = self.messageHandler
        self.session?.onContentResize = self.onContentResize
        self.session?.evaluateJavaScript = { [weak webView] script in
            webView?.evaluateJavaScript(script) { _, error in
                if let error {
                    Logger.debug(Strings.paywall_web_view_post_message_failed(String(describing: error)))
                }
            }
        }
        self.session?.currentURL = { [weak webView] in
            webView?.url
        }
    }

    private func load(_ webView: PlatformWebView) {
        Task { @MainActor in
            guard let rules = await WebViewIsolation.ruleList() else {
                Logger.debug(Strings.paywall_web_view_content_rules_failed("rule list unavailable"))
                return
            }

            webView.configuration.userContentController.add(rules)
            webView.load(URLRequest(url: url))
        }
    }

    private static func dismantle(_ webView: PlatformWebView) {
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: WebViewEnvelope.messageHandlerName
        )

        #if os(macOS)
        webView.configuration.websiteDataStore.removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: .distantPast
        ) {}
        #endif
    }

    final class Coordinator: NSObject, WKNavigationDelegate {

        let expectedOrigin: String

        init(expectedOrigin: String) {
            self.expectedOrigin = expectedOrigin
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            let policy = WebViewNavigationPolicy.policy(
                for: navigationAction.request.url,
                isMainFrame: navigationAction.targetFrame?.isMainFrame ?? true,
                expectedOrigin: expectedOrigin
            )
            decisionHandler(policy)
        }

    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WebViewNavigationPolicy {

    static func policy(for url: URL?, isMainFrame: Bool, expectedOrigin: String) -> WKNavigationActionPolicy {
        guard isMainFrame else {
            return .allow
        }
        guard let url,
              WebViewSession.origin(of: url) == expectedOrigin else {
            return .cancel
        }
        return .allow
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension View {

    @ViewBuilder
    func webViewSize(
        _ size: PaywallComponent.Size,
        measuredWidth: CGFloat?,
        measuredHeight: CGFloat?
    ) -> some View {
        self
            .webViewWidth(size.width, measuredWidth: measuredWidth)
            .webViewHeight(size.height, measuredHeight: measuredHeight)
    }

    @ViewBuilder
    func webViewWidth(
        _ constraint: PaywallComponent.SizeConstraint,
        measuredWidth: CGFloat?
    ) -> some View {
        switch constraint {
        case .fit:
            self.frame(width: measuredWidth ?? WebViewEnvelope.fallbackFitWidth)
        case .fill:
            self.frame(maxWidth: .infinity)
        case .fixed(let value):
            self.frame(width: CGFloat(value))
        case .relative:
            self
        }
    }

    @ViewBuilder
    func webViewHeight(
        _ constraint: PaywallComponent.SizeConstraint,
        measuredHeight: CGFloat?
    ) -> some View {
        switch constraint {
        case .fit:
            self.frame(height: measuredHeight ?? WebViewEnvelope.fallbackFitHeight)
        case .fill:
            self.frame(maxHeight: .infinity)
        case .fixed(let value):
            self.frame(height: CGFloat(value))
        case .relative:
            self
        }
    }

}

#endif

#endif
