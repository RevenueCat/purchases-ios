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
        // Gating here (rather than deep in the session) keeps the whole web view unrendered when it
        // can't work — no usable origin, or an empty component id the bridge would only reject on —
        // instead of mounting an inert bridge. See `WebViewComponentViewModel.isRenderable`.
        if viewModel.isRenderable, let url = viewModel.url, let origin = viewModel.origin {
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
        } else if viewModel.visible {
            // Meant to be shown but not renderable (bad URL / no resolvable origin / missing id):
            // this renders nothing, so surface why instead of leaving authors with a silent blank.
            Color.clear
                .frame(width: 0, height: 0)
                .onAppear { Logger.error(Strings.paywall_web_view_not_rendered(reason: self.nonRenderReason)) }
        }
        #endif
    }

    #if canImport(WebKit) && !os(watchOS)
    private var nonRenderReason: String {
        if viewModel.componentID.isEmpty {
            return "missing component id"
        } else if viewModel.url == nil {
            return "invalid or unsupported URL '\(viewModel.urlString)'"
        } else {
            return "URL '\(viewModel.urlString)' has no resolvable origin"
        }
    }
    #endif

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

    @State
    private var loadFailed = false

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
        if !processTerminated, !loadFailed {
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
                },
                onLoadFailed: {
                    self.loadFailed = true
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
    var onLoadFailed: (@MainActor () -> Void)?

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(expectedOrigin: expectedOrigin)
        coordinator.session = session
        coordinator.onProcessTerminated = onProcessTerminated
        coordinator.onLoadFailed = onLoadFailed
        return coordinator
    }

    #if os(macOS)
    func makeNSView(context: Context) -> PlatformWebView {
        self.makeWebView(context: context)
    }

    func updateNSView(_ webView: PlatformWebView, context: Context) {
        context.coordinator.onProcessTerminated = onProcessTerminated
        context.coordinator.onLoadFailed = onLoadFailed
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
        context.coordinator.onLoadFailed = onLoadFailed
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

        // Enable Safari Web Inspector for authors, double-gated so it can never ship enabled:
        // `#if DEBUG` strips it from release builds and the log level keeps it opt-in.
        // https://webkit.org/blog/13936/enabling-the-inspection-of-web-content-in-apps/
        #if DEBUG
        if #available(iOS 16.4, macOS 13.3, *), Purchases.logLevel <= .debug {
            webView.isInspectable = true
        }
        #endif

        #if os(iOS)
        // Nested-scroll arbitration: let JS-panned content (maps, inner overflow scrollers) claim a
        // drag from the enclosing paywall scroll. Installed before `load` so the document-start probe
        // is present for the first navigation.
        self.installScrollGestureArbitration(on: webView)
        #endif

        self.configureSession(for: webView)
        self.load(webView)
        return webView
    }

    #if os(iOS)
    @MainActor
    private func installScrollGestureArbitration(on webView: PlatformWebView) {
        let recognizer = WebViewScrollOwnershipRecognizer(webView: webView)
        webView.addGestureRecognizer(recognizer)
        webView.configuration.userContentController.add(
            WeakScriptMessageHandler(recognizer),
            name: WebViewGestureProbe.messageHandlerName
        )
        webView.configuration.userContentController.addUserScript(WebViewGestureProbe.userScript)
    }
    #endif

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
        #if os(iOS)
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: WebViewGestureProbe.messageHandlerName
        )
        #endif
    }

    // `WKNavigationDelegate` is `@MainActor`-annotated in the SDK (its `WK_SWIFT_UI_ACTOR` attribute
    // resolves to `@MainActor`), so isolating the coordinator to the main actor lets the delegate
    // methods touch main-actor state directly instead of wrapping each body in `assumeIsolated`.
    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {

        let expectedOrigin: WebViewOrigin
        weak var session: WebViewSession?
        var onProcessTerminated: (@MainActor () -> Void)?
        var onLoadFailed: (@MainActor () -> Void)?

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

        // WebKit treats an HTTP 4xx/5xx as a *successful* navigation (the server replied, so the error
        // body gets rendered) and does not call `didFail*`. This is the only place we can see the status
        // code, so we inspect it here and tear the web view down on a main-frame error. We handle the
        // failure inline rather than relying on `.cancel` surfacing in `didFail`, since cancelling shows
        // up there as a cancellation that `handleLoadFailure` deliberately ignores.
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            if let httpResponse = navigationResponse.response as? HTTPURLResponse,
               WebViewNavigationPolicy.isTerminalHTTPError(
                statusCode: httpResponse.statusCode,
                isMainFrame: navigationResponse.isForMainFrame
               ) {
                Logger.error(Strings.paywall_web_view_http_error(statusCode: httpResponse.statusCode))
                self.onLoadFailed?()
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            self.handleLoadFailure(error)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            self.handleLoadFailure(error)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            Logger.debug(Strings.paywall_web_view_content_process_terminated)
            self.onProcessTerminated?()
        }

        /// Treats a terminal navigation failure (including SSL/server-trust failures, which WebKit
        /// surfaces here) as a reason to remove the web view. Cancellations are ignored: we
        /// deliberately cancel cross-origin navigations in `decidePolicyFor`, and those surface here.
        private func handleLoadFailure(_ error: Error) {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                return
            }
            // Cancelling via the navigation policy can also surface as WebKitErrorDomain 102
            // ("frame load interrupted by a policy change"), which is not a real failure.
            if nsError.domain == "WebKitErrorDomain", nsError.code == 102 {
                return
            }
            Logger.error(Strings.paywall_web_view_load_failed(nsError.localizedDescription))
            self.onLoadFailed?()
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
