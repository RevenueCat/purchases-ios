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

    @EnvironmentObject
    private var packageContext: PackageContext

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var paywallPromoOfferCache: PaywallPromoOfferCache

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    @Environment(\.customPaywallVariables)
    private var customVariables

    @Environment(\.locale)
    private var locale

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.selectedPackageId)
    private var selectedPackageId

    @Environment(\.paywallWebViewStaticContext)
    private var webViewStaticContext

    @Environment(\.paywallStateValues)
    private var paywallStateValues

    @Environment(\.paywallStateDefaults)
    private var paywallStateDefaults

    let viewModel: WebViewComponentViewModel

    private var style: WebViewComponentStyle {
        let currentPackage = self.packageContext.package
        return self.viewModel.style(
            state: self.componentViewState,
            condition: self.screenCondition,
            isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(package: currentPackage),
            isEligibleForPromoOffer: self.paywallPromoOfferCache.isMostLikelyEligible(for: currentPackage),
            selectedPackageId: self.selectedPackageId,
            customVariables: self.customVariables,
            stateValues: self.paywallStateValues,
            stateDefaults: self.paywallStateDefaults
        )
    }

    private var webViewContext: PaywallWebViewContext? {
        return self.webViewStaticContext?.snapshot(
            package: self.packageContext.package,
            selectedPackageID: self.selectedPackageId,
            customVariables: self.viewModel.resolvedCustomVariables(overridingWith: self.customVariables),
            locale: self.locale,
            isDarkMode: self.colorScheme == .dark
        )
    }

    var body: some View {
        #if os(watchOS) || !canImport(WebKit)
        EmptyView()
        #else
        let style = self.style
        // Gating here (rather than deep in the session) keeps the whole web view unrendered when it
        // can't work — no usable origin, or an empty component id the bridge would only reject on —
        // instead of mounting an inert bridge. See `WebViewComponentStyle.isRenderable`.
        if style.isRenderable,
           let url = style.url,
           let instance = self.viewModel.webViewInstance(context: self.webViewContext) {
            HostedWebViewComponentView(
                size: style.size,
                url: url,
                instance: instance
            )
        } else if style.visible {
            // Meant to be shown but not renderable (bad URL / no resolvable origin / missing id):
            // this renders nothing, so surface why instead of leaving authors with a silent blank.
            Color.clear
                .frame(width: 0, height: 0)
                .onAppear {
                    Logger.error(Strings.paywall_web_view_not_rendered(reason: Self.nonRenderReason(for: style)))
                }
        }
        #endif
    }

    #if canImport(WebKit) && !os(watchOS)
    private static func nonRenderReason(for style: WebViewComponentStyle) -> String {
        if style.componentID.isEmpty {
            return "missing component id"
        } else if style.url == nil {
            return "invalid or unsupported URL '\(style.urlString)'"
        } else {
            return "URL '\(style.urlString)' has no resolvable origin"
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

#if canImport(WebKit) && !os(watchOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct HostedWebViewComponentView: View {

    let size: PaywallComponent.Size
    let url: URL

    @ObservedObject
    var instance: WebViewInstance

    var body: some View {
        if !self.instance.processTerminated, !self.instance.loadFailed {
            WebViewRepresentable(
                url: self.url,
                instance: self.instance,
                idStore: .shared
            )
            .webViewSize(
                self.size,
                measuredWidth: self.instance.measuredWidth,
                measuredHeight: self.instance.measuredHeight
            )
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
    let instance: WebViewInstance
    let idStore: WebViewDataStoreIdentifierStore

    var expectedOrigin: WebViewOrigin {
        self.instance.session.expectedOrigin
    }

    /// One coordinator per instance, retained by the instance: `navigationDelegate` is weak, so a
    /// coordinator owned by a `ViewThatFits` candidate would stop delivering callbacks the moment
    /// that candidate is discarded.
    func makeCoordinator() -> Coordinator {
        self.instance.navigationDelegate {
            let coordinator = Coordinator(expectedOrigin: self.expectedOrigin)
            coordinator.session = self.instance.session
            coordinator.onProcessTerminated = { [weak instance] in instance?.markProcessTerminated() }
            coordinator.onLoadFailed = { [weak instance] in instance?.markLoadFailed() }
            return coordinator
        }
    }

    // Deliberately no `dismantleNSView/dismantleUIView` implementation: a discarded subtree is usually just a
    // `ViewThatFits` candidate losing the layout, and tearing the web view down there is what caused
    // the component to blank out and reload. The component view model owns the web view instead.
    #if os(macOS)
    func makeNSView(context: Context) -> WebViewHostView {
        self.makeHost(context: context)
    }

    func updateNSView(_ host: WebViewHostView, context: Context) {
        self.update(host)
    }
    #else
    func makeUIView(context: Context) -> WebViewHostView {
        self.makeHost(context: context)
    }

    func updateUIView(_ host: WebViewHostView, context: Context) {
        self.update(host)
    }
    #endif

    @MainActor
    private func makeHost(context: Context) -> WebViewHostView {
        let host = WebViewHostView()

        _ = self.instance.webView {
            self.makeWebView(context: context)
        }

        let instance = self.instance
        host.onMoveToWindow = { [weak instance] host in
            if host.window == nil {
                instance?.hostDidLeaveWindow(host)
            } else {
                instance?.hostDidEnterWindow(host)
            }
        }

        return host
    }

    @MainActor
    private func update(_ host: WebViewHostView) {
        if host.window != nil {
            self.instance.updateHost(host)
        }
    }

    @MainActor
    static func makeConfiguration(session: WebViewSession?, storeID: UUID) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.setPersistentStoreIfAble(withID: storeID)
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
        let configuration = Self.makeConfiguration(session: self.instance.session, storeID: idStore.identifier())
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
        webView.scrollView.bounces = true
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
        // Nested-scroll arbitration: let JS-panned content claim a drag from the enclosing paywall
        // scroll. Installed before `load` so the document-start probe is present for the first
        // navigation.
        self.installScrollGestureArbitration(on: webView)
        #endif

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

    private func load(_ webView: PlatformWebView) {
        // Cross-origin isolation is delegated to the server-provided CSP (see
        // WebViewComponentNavigationPolicy), so no WKContentRuleList is installed here.
        webView.load(URLRequest(url: url))
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
            let policy = WebViewComponentNavigationPolicy.policy(
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
               WebViewHTTPStatus.isTerminalError(
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
        case .fit(let defaultSize, _):
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
        case .fit(let defaultSize, _):
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
