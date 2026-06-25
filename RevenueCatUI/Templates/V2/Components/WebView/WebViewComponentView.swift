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

    @Environment(\.customPaywallVariables)
    private var customVariables

    var body: some View {
        if viewModel.visible {
            self.content
        }
    }

    @ViewBuilder
    private var content: some View {
        #if canImport(UIKit) && canImport(WebKit)
        if let resolvedURL = viewModel.resolvedURL(customVariables: customVariables) {
            WebViewRepresentable(url: resolvedURL, height: $dynamicHeight)
                .modifier(WebViewSizeModifier(size: viewModel.size, measuredHeight: dynamicHeight))
                .clipped()
                .background(Color.clear)
        }
        #elseif os(macOS)
        if let resolvedURL = viewModel.resolvedURL(customVariables: customVariables) {
            let macHeight = dynamicHeight ?? Self.initialHeight
            MacWebViewRepresentable(url: resolvedURL, height: $dynamicHeight)
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
            // Web content has no intrinsic height, so use the dynamically-measured height.
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

    static let measureHeightJavaScript = "window.__rcMeasureHeight && window.__rcMeasureHeight()"

    static let heightReportingJavaScriptSource = """
    (function() {
      function measureHeight() {
        var body = document.body;
        var html = document.documentElement;
        var bodyRect = body.getBoundingClientRect();
        var height = Math.max(bodyRect.height, html.getBoundingClientRect().height);

        var children = body.children;
        for (var i = 0; i < children.length; i++) {
          var child = children[i];
          var style = window.getComputedStyle(child);
          if (style.display === 'none' || style.visibility === 'hidden') { continue; }
          var rect = child.getBoundingClientRect();
          if (rect.height > 0) {
            height = Math.max(height, rect.bottom - bodyRect.top);
          }
        }

        return Math.ceil(height);
      }

      window.__rcMeasureHeight = measureHeight;

      function reportHeight() {
        var height = measureHeight();
        if (window.webkit && window.webkit.messageHandlers.rcWebViewHeight) {
          window.webkit.messageHandlers.rcWebViewHeight.postMessage(height);
        }
      }

      window.__rcReportHeight = reportHeight;

      if (!window.__rcHeightObserverInstalled) {
        window.__rcHeightObserverInstalled = true;

        if (window.ResizeObserver) {
          var resizeObserver = new ResizeObserver(reportHeight);
          resizeObserver.observe(document.documentElement);
          if (document.body) { resizeObserver.observe(document.body); }
        }

        new MutationObserver(reportHeight).observe(document.documentElement, {
          subtree: true,
          childList: true,
          attributes: true,
          characterData: true
        });

        document.addEventListener('click', function() {
          reportHeight();
          setTimeout(reportHeight, 50);
          setTimeout(reportHeight, 150);
          setTimeout(reportHeight, 350);
        }, true);

        document.addEventListener('transitionend', reportHeight, true);
        document.addEventListener('animationend', reportHeight, true);
        window.addEventListener('load', reportHeight);
      }

      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', reportHeight, { once: true });
      } else {
        reportHeight();
      }
    })();
    """

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

    static let heightReportingUserScript = WKUserScript(
        source: PaywallWebViewScripts.heightReportingJavaScriptSource,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: true
    )

    /// Attaches the content-blocking rule list (compiling it if necessary), then loads `url`. The
    /// load is deferred until the rules are in place so no request is issued before isolation
    /// applies. Fails closed: if compilation fails the page still loads, already isolated to its
    /// uploaded bundle.
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
            if let ruleList {
                webView.configuration.userContentController.add(ruleList)
            }
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

/// Measures a web view's rendered content height and reports changes via `onHeight`. Shared by the
/// iOS and macOS coordinators so the (otherwise identical) measurement logic lives in one place.
/// Registers itself as the `rcWebViewHeight` script-message handler and also measures on demand
/// after navigation finishes.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewHeightReporter: NSObject, WKScriptMessageHandler {

    static let handlerName = "rcWebViewHeight"

    /// Invoked with each newly measured content height (raw; callers apply their own change
    /// threshold and main-thread dispatch).
    private let onHeight: (CGFloat, WKWebView) -> Void
    private var messageHandler: WeakScriptMessageHandler?
    private var measurementGeneration = 0

    init(onHeight: @escaping (CGFloat, WKWebView) -> Void) {
        self.onHeight = onHeight
    }

    func register(on webView: WKWebView) {
        let handler = WeakScriptMessageHandler(delegate: self)
        self.messageHandler = handler
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Self.handlerName)
        webView.configuration.userContentController.add(handler, name: Self.handlerName)
    }

    func unregister(from webView: WKWebView) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Self.handlerName)
        self.messageHandler = nil
    }

    func reportIfNeeded(in webView: WKWebView) {
        webView.evaluateJavaScript("window.__rcReportHeight && window.__rcReportHeight()")
    }

    /// Re-injects the height-reporting script and measures, both immediately and once all resources
    /// finish loading. Call from the navigation delegate's `didFinish`.
    func handleNavigationFinished(in webView: WKWebView) {
        webView.evaluateJavaScript(PaywallWebViewScripts.heightReportingJavaScriptSource)
        self.measure(in: webView)
        let javaScript = """
        new Promise(r => {
          if (document.readyState === 'complete') { r(); return; }
          window.addEventListener('load', () => r(), { once: true });
        }).then(() => 0);
        """
        webView.evaluateJavaScript(javaScript) { [weak self, weak webView] _, _ in
            guard let self, let webView else { return }
            webView.evaluateJavaScript(PaywallWebViewScripts.heightReportingJavaScriptSource)
            self.measure(in: webView)
            self.scheduleDelayedMeasurements(in: webView)
        }
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == Self.handlerName, let webView = message.webView else { return }
        if let height = Self.height(from: message.body) {
            self.onHeight(height, webView)
        }
    }

    private func measure(in webView: WKWebView) {
        // Skip until the view has a width, otherwise the measurement collapses to zero.
        guard webView.bounds.width > 0 else { return }

        self.measurementGeneration += 1
        let generation = self.measurementGeneration

        let measureJS = PaywallWebViewScripts.measureHeightJavaScript
        webView.evaluateJavaScript(measureJS) { [weak self, weak webView] result, _ in
            guard let self, let webView, generation == self.measurementGeneration else { return }
            if let height = Self.height(from: result) {
                self.onHeight(height, webView)
            }
        }
    }

    private func scheduleDelayedMeasurements(in webView: WKWebView) {
        let delays: [TimeInterval] = [0.05, 0.15, 0.35]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak webView] in
                guard let self, let webView else { return }
                self.measure(in: webView)
            }
        }
    }

    private static func height(from value: Any?) -> CGFloat? {
        if let number = value as? NSNumber {
            return CGFloat(number.doubleValue)
        } else if let double = value as? Double {
            return CGFloat(double)
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

        context.coordinator.registerHeightReporting(on: webView)
        context.coordinator.currentURL = url
        PaywallWebViewScripts.loadIsolated(url: url, on: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.currentURL != url {
            context.coordinator.currentURL = url
            uiView.load(URLRequest(url: url))
        }

        if let height, let autoSizingWebView = uiView as? AutoSizingWebView {
            autoSizingWebView.setContentHeight(height)
        }

        context.coordinator.reportHeightIfNeeded(in: uiView)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.unregisterHeightReporting(from: uiView)
        uiView.navigationDelegate = nil
        uiView.scrollView.delegate = nil
        uiView.stopLoading()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(height: $height)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {

        @Binding var height: CGFloat?
        var currentURL: URL?

        private lazy var heightReporter = WebViewHeightReporter { [weak self] newHeight, webView in
            guard let self, newHeight >= 0, abs(newHeight - (self.height ?? 0)) > 0.5 else { return }
            DispatchQueue.main.async {
                self.height = newHeight
                (webView as? AutoSizingWebView)?.setContentHeight(newHeight)
            }
        }

        init(height: Binding<CGFloat?>) {
            _height = height
        }

        func registerHeightReporting(on webView: WKWebView) {
            self.heightReporter.register(on: webView)
        }

        func unregisterHeightReporting(from webView: WKWebView) {
            self.heightReporter.unregister(from: webView)
        }

        func reportHeightIfNeeded(in webView: WKWebView) {
            self.heightReporter.reportIfNeeded(in: webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.heightReporter.handleNavigationFinished(in: webView)
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
        config.userContentController.addUserScript(PaywallWebViewScripts.heightReportingUserScript)
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

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: Self.makeConfiguration())
        webView.navigationDelegate = context.coordinator
        context.coordinator.registerHeightReporting(on: webView)
        context.coordinator.currentURL = url
        PaywallWebViewScripts.loadIsolated(url: url, on: webView)

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if context.coordinator.currentURL != url {
            context.coordinator.currentURL = url
            nsView.load(URLRequest(url: url))
        }

        context.coordinator.reportHeightIfNeeded(in: nsView)
    }

    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        coordinator.unregisterHeightReporting(from: nsView)
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
        config.userContentController.addUserScript(PaywallWebViewScripts.heightReportingUserScript)

        return config
    }

    final class Coordinator: NSObject, WKNavigationDelegate {

        @Binding var height: CGFloat?
        var currentURL: URL?

        private lazy var heightReporter = WebViewHeightReporter { [weak self] newHeight, _ in
            guard let self, newHeight >= 0, abs(newHeight - (self.height ?? 0)) > 0.5 else { return }
            DispatchQueue.main.async {
                self.height = newHeight
            }
        }

        init(height: Binding<CGFloat?>) {
            _height = height
        }

        func registerHeightReporting(on webView: WKWebView) {
            self.heightReporter.register(on: webView)
        }

        func unregisterHeightReporting(from webView: WKWebView) {
            self.heightReporter.unregister(from: webView)
        }

        func reportHeightIfNeeded(in webView: WKWebView) {
            self.heightReporter.reportIfNeeded(in: webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.heightReporter.handleNavigationFinished(in: webView)
        }

    }

}

#endif // os(macOS) && canImport(WebKit)

#endif // !os(tvOS)
