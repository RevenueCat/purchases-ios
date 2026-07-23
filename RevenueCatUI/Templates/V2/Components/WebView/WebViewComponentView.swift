//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if canImport(WebKit)
import WebKit
#endif

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WebViewComponentView: View {

    let viewModel: WebViewComponentViewModel

    var body: some View {
        #if os(watchOS) || !canImport(WebKit)
        EmptyView()
        #else
        // Resolving the origin here (rather than deep in the session) is what lets the whole web view
        // stay unrendered when the URL has no usable origin, instead of rendering an inert bridge.
        if viewModel.visible, let url = viewModel.url, let origin = viewModel.origin {
            BridgedWebViewComponentView(
                viewModel: viewModel,
                url: url,
                expectedOrigin: origin,
                componentID: viewModel.componentID
            )
            .id(
                "\(viewModel.urlString)-\(viewModel.componentID)-" +
                "\(viewModel.size.width.isFit)-\(viewModel.size.height.isFit)"
            )
        }
        #endif
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WebViewSizing {

    static func resolvedDimension(
        measured: CGFloat?,
        defaultSize: UInt?,
        fallback: CGFloat
    ) -> CGFloat {
        measured ?? defaultSize.map { CGFloat($0) } ?? fallback
    }

}

private extension PaywallComponent.SizeConstraint {

    var isFit: Bool {
        if case .fit = self {
            return true
        }

        return false
    }

}

#if canImport(WebKit) && !os(watchOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct BridgedWebViewComponentView: View {

    let viewModel: WebViewComponentViewModel
    let url: URL
    let expectedOrigin: WebViewOrigin

    @StateObject
    private var session: WebViewSession

    @State
    private var measuredWidth: CGFloat?

    @State
    private var measuredHeight: CGFloat?

    @State
    private var processTerminated = false

    init(
        viewModel: WebViewComponentViewModel,
        url: URL,
        expectedOrigin: WebViewOrigin,
        componentID: String
    ) {
        self.viewModel = viewModel
        self.url = url
        self.expectedOrigin = expectedOrigin

        // `evaluateJavaScript`/`currentURL` are rebound to the live web view in the representable's
        // `configureSession(for:)`; the no-op defaults only cover the window before it is created.
        self._session = StateObject(
            wrappedValue: WebViewSession(
                componentID: componentID,
                expectedOrigin: expectedOrigin,
                fitAxes: (
                    width: viewModel.size.width.isFit,
                    height: viewModel.size.height.isFit
                ),
                evaluateJavaScript: { _ in false },
                currentURL: { nil }
            )
        )
    }

    var body: some View {
        // The resize sink is (re)assigned inside the representable's make/update (not `.onAppear`)
        // so a connect arriving before `.onAppear` fires always sees the current values.
        if !processTerminated {
            WebViewRepresentable(
                url: url,
                expectedOrigin: expectedOrigin,
                session: session,
                onContentResize: { width, height in
                    if let width {
                        self.measuredWidth = width
                    }
                    if let height {
                        self.measuredHeight = height
                    }
                },
                onDocumentReset: {
                    self.measuredWidth = nil
                    self.measuredHeight = nil
                },
                onProcessTerminated: {
                    self.processTerminated = true
                }
            )
            .webViewSize(viewModel.size, measuredWidth: measuredWidth, measuredHeight: measuredHeight)
            // Content can momentarily overflow the exact frame mid-resize (fit axes animate through
            // placeholder -> measured); never paint outside the component's box.
            .clipped()
        }
    }

}

#if os(macOS)
private typealias PlatformViewRepresentable = NSViewRepresentable
#else
private typealias PlatformViewRepresentable = UIViewRepresentable
#endif
typealias PlatformWebView = WKWebView

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WebViewRepresentable: PlatformViewRepresentable {

    let url: URL
    let expectedOrigin: WebViewOrigin
    weak var session: WebViewSession?
    var onContentResize: (@MainActor (CGFloat?, CGFloat?) -> Void)?
    var onDocumentReset: (@MainActor () -> Void)?
    var onProcessTerminated: (@MainActor () -> Void)?

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(expectedOrigin: expectedOrigin)
        coordinator.session = session
        coordinator.onProcessTerminated = onProcessTerminated
        return coordinator
    }

    #if os(macOS)
    func makeNSView(context: Context) -> PlatformWebView {
        self.makeWebView(context: context)
    }

    func updateNSView(_ webView: PlatformWebView, context: Context) {
        context.coordinator.onProcessTerminated = onProcessTerminated
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
        context.coordinator.onProcessTerminated = onProcessTerminated
        self.update(webView)
    }

    static func dismantleUIView(_ webView: PlatformWebView, coordinator: Coordinator) {
        dismantle(webView)
    }
    #endif

    @MainActor
    static func makeConfiguration(session: WebViewSession?) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.userContentController = WKUserContentController()

        if let session {
            configuration.userContentController.add(
                WeakScriptMessageHandler(session),
                name: WebViewEnvelope.messageHandlerName
            )
        }

        // This is required to allow media to begin playing without a user gesture
        configuration.mediaTypesRequiringUserActionForPlayback = []

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

        return configuration
    }

    @MainActor
    private func makeWebView(context: Context) -> PlatformWebView {
        let configuration = Self.makeConfiguration(session: session)
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
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        webView.scrollView.minimumZoomScale = 1
        webView.scrollView.maximumZoomScale = 1
        #endif

        self.configureSession(for: webView)
        self.load(webView)
        return webView
    }

    @MainActor
    private func update(_ webView: PlatformWebView) {
        self.configureSession(for: webView)
    }

    @MainActor
    private func configureSession(for webView: PlatformWebView) {
        self.session?.onContentResize = self.onContentResize
        self.session?.onDocumentReset = self.onDocumentReset
        self.session?.evaluateJavaScript = { [weak webView] script in
            // A released web view means the frame never reaches the page; report the miss
            guard let webView else { return false }
            webView.evaluateJavaScript(script) { _, error in
                if let error {
                    Logger.debug(Strings.paywall_web_view_post_message_failed(String(describing: error)))
                }
            }
            return true
        }
        self.session?.currentURL = { [weak webView] in
            webView?.url
        }
    }

    private func load(_ webView: PlatformWebView) {
        // Cross-origin isolation is delegated to the server-provided CSP (see WebViewNavigationPolicy),
        // so no WKContentRuleList is installed here.
        webView.load(URLRequest(url: url))
    }

    private static func dismantle(_ webView: PlatformWebView) {
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: WebViewEnvelope.messageHandlerName
        )
    }

    // `WKNavigationDelegate` is `@MainActor`-annotated in the SDK (its `WK_SWIFT_UI_ACTOR` attribute
    // resolves to `@MainActor`), so isolating the coordinator to the main actor lets the delegate
    // methods touch main-actor state directly instead of wrapping each body in `assumeIsolated`.
    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {

        let expectedOrigin: WebViewOrigin
        weak var session: WebViewSession?
        var onProcessTerminated: (@MainActor () -> Void)?

        init(expectedOrigin: WebViewOrigin) {
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

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            self.session?.resetForNewDocument()
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            Logger.debug(Strings.paywall_web_view_content_process_terminated)
            self.onProcessTerminated?()
        }

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
        case .fit(let defaultSize):
            self.frame(
                width: WebViewSizing.resolvedDimension(
                    measured: measuredWidth,
                    defaultSize: defaultSize,
                    fallback: WebViewEnvelope.fallbackFitWidth
                )
            )
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
        case .fit(let defaultSize):
            self.frame(
                height: WebViewSizing.resolvedDimension(
                    measured: measuredHeight,
                    defaultSize: defaultSize,
                    fallback: WebViewEnvelope.fallbackFitHeight
                )
            )
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
