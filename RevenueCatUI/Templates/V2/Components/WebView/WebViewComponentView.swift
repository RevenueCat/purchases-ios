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
    let onDismiss: () -> Void

    init(viewModel: WebViewComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
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
        #if canImport(UIKit)
        if let resolvedURL = viewModel.resolvedURL(customVariables: customVariables) {
            let urlToLoad = viewModel.cachedURL(for: resolvedURL) ?? resolvedURL
            WebViewRepresentable(url: urlToLoad, height: $dynamicHeight)
                .modifier(WebViewSizeModifier(size: viewModel.size, measuredHeight: dynamicHeight))
                .clipped()
                .background(Color.clear)
            // swiftlint:disable:next todo
            // TODO: render `fallback` if the web content fails to load mid-flight
            // (network/render error), not just when the URL is invalid.
        } else {
            self.fallback
        }
        #elseif os(macOS)
        if let resolvedURL = viewModel.resolvedURL(customVariables: customVariables) {
            let urlToLoad = viewModel.cachedURL(for: resolvedURL) ?? resolvedURL
            let macHeight = dynamicHeight ?? Self.initialHeight
            MacWebViewRepresentable(url: urlToLoad, height: $dynamicHeight)
                .modifier(WebViewSizeModifier(size: viewModel.size, measuredHeight: macHeight))
                .clipped()
                .background(Color.clear)
        } else {
            self.fallback
        }
        #else
        self.fallback
        #endif
    }

    @ViewBuilder
    private var fallback: some View {
        if let fallbackStackViewModel = viewModel.fallbackStackViewModel {
            StackComponentView(viewModel: fallbackStackViewModel, onDismiss: onDismiss)
        }
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
private enum PaywallWebViewScripts {

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

}

#endif

#if canImport(UIKit)

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
private struct WebViewRepresentable: UIViewRepresentable {

    let url: URL
    @Binding var height: CGFloat?

    func makeUIView(context: Context) -> WKWebView {
        let webView = WebViewPool.shared.acquire()
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
        webView.load(URLRequest(url: url))
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

        if let webView = uiView as? AutoSizingWebView {
            WebViewPool.shared.return(webView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(height: $height)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate, WKScriptMessageHandler {

        static let heightMessageHandlerName = "rcWebViewHeight"

        @Binding var height: CGFloat?
        var currentURL: URL?
        private var heightMessageHandler: WeakScriptMessageHandler?
        private weak var webView: WKWebView?
        private var heightMeasurementGeneration = 0

        init(height: Binding<CGFloat?>) {
            _height = height
        }

        func reportHeightIfNeeded(in webView: WKWebView) {
            webView.evaluateJavaScript("window.__rcReportHeight && window.__rcReportHeight()")
        }

        func registerHeightReporting(on webView: WKWebView) {
            self.webView = webView
            let handler = WeakScriptMessageHandler(delegate: self)
            self.heightMessageHandler = handler
            webView.configuration.userContentController.add(handler, name: Self.heightMessageHandlerName)
        }

        func unregisterHeightReporting(from webView: WKWebView) {
            webView.configuration.userContentController.removeScriptMessageHandler(
                forName: Self.heightMessageHandlerName
            )
            self.heightMessageHandler = nil
            self.webView = nil
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == Self.heightMessageHandlerName else { return }

            let reportedHeight: CGFloat?
            if let number = message.body as? NSNumber {
                reportedHeight = CGFloat(number.doubleValue)
            } else if let double = message.body as? Double {
                reportedHeight = CGFloat(double)
            } else {
                reportedHeight = nil
            }

            if let reportedHeight {
                self.applyHeight(reportedHeight, to: self.webView)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(Self.installHeightReportingJavaScript)
            self.measureHeight(in: webView)
            // Re-check after all resources finish loading
            let javaScript = """
            new Promise(r => {
              if (document.readyState === 'complete') { r(); return; }
              window.addEventListener('load', () => r(), { once: true });
            }).then(() => 0);
            """
            webView.evaluateJavaScript(javaScript) { [weak self, weak webView] _, _ in
                guard let self, let webView else { return }
                webView.evaluateJavaScript(Self.installHeightReportingJavaScript)
                self.measureHeight(in: webView)
                self.scheduleDelayedMeasurements(in: webView)
            }
        }

        private func measureHeight(in webView: WKWebView) {
            guard webView.scrollView.frame.width > 0 else { return }

            self.heightMeasurementGeneration += 1
            let generation = self.heightMeasurementGeneration

            webView.evaluateJavaScript(Self.measureHeightJavaScript) { [weak self] result, _ in
                guard let self, generation == self.heightMeasurementGeneration else { return }

                let measuredHeight: CGFloat?
                if let number = result as? NSNumber {
                    measuredHeight = CGFloat(number.doubleValue)
                } else if let double = result as? Double {
                    measuredHeight = CGFloat(double)
                } else {
                    measuredHeight = nil
                }

                if let measuredHeight {
                    self.applyHeight(measuredHeight, to: webView)
                }
            }
        }

        private func scheduleDelayedMeasurements(in webView: WKWebView) {
            let delays: [TimeInterval] = [0.05, 0.15, 0.35]
            for delay in delays {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak webView] in
                    guard let self, let webView else { return }
                    self.measureHeight(in: webView)
                }
            }
        }

        private func applyHeight(_ newHeight: CGFloat, to webView: WKWebView?) {
            guard newHeight >= 0 else { return }
            guard abs(newHeight - (height ?? 0)) > 0.5 else { return }

            DispatchQueue.main.async {
                self.height = newHeight
                (webView as? AutoSizingWebView)?.setContentHeight(newHeight)
            }
        }

        private static let measureHeightJavaScript = PaywallWebViewScripts.measureHeightJavaScript

        private static let installHeightReportingJavaScript = PaywallWebViewScripts.heightReportingJavaScriptSource

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return nil
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            scrollView.zoomScale = 1.0
        }

    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewPool {

    static let shared = WebViewPool(capacity: 3)

    private let processPool = WKProcessPool()
    private var pool: [AutoSizingWebView] = []
    private let capacity: Int

    init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    func warmUp() {
        guard self.pool.isEmpty else { return }

        for _ in 0..<self.capacity {
            let webView = self.makeWebView()
            webView.loadHTMLString("<!doctype html><html></html>", baseURL: nil)
            self.pool.append(webView)
        }
    }

    func acquire() -> AutoSizingWebView {
        return self.pool.popLast() ?? self.makeWebView()
    }

    func `return`(_ webView: AutoSizingWebView) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.scrollView.delegate = nil
        webView.scrollView.zoomScale = 1.0
        webView.setContentHeight(0)
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: WebViewRepresentable.Coordinator.heightMessageHandlerName
        )
        webView.configuration.websiteDataStore.removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: .distantPast
        ) { [weak self, weak webView] in
            DispatchQueue.main.async {
                guard let self, let webView else { return }
                webView.loadHTMLString("<!doctype html><html></html>", baseURL: nil)

                if self.pool.count < self.capacity {
                    self.pool.append(webView)
                }
            }
        }
    }

    private func makeWebView() -> AutoSizingWebView {
        return AutoSizingWebView(processPool: self.processPool)
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

    init(processPool: WKProcessPool) {
        let config = WKWebViewConfiguration()
        config.processPool = processPool
        config.websiteDataStore = .nonPersistent()
        config.allowsInlineMediaPlayback = true
        config.userContentController.addUserScript(PaywallWebViewScripts.disableZoomUserScript)
        config.userContentController.addUserScript(PaywallWebViewScripts.heightReportingUserScript)
        config.setURLSchemeHandler(InMemoryHTMLURLSchemeHandler(), forURLScheme: "purchaseshtml")
        super.init(frame: .zero, configuration: config)
        isOpaque = false
        backgroundColor = .clear
        scrollView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {

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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class InMemoryHTMLURLSchemeHandler: NSObject, WKURLSchemeHandler {

    private let session = URLSession(
        configuration: InMemoryHTMLFileRepository.makeURLSessionConfiguration()
    )
    private let lock = NSLock()
    private var loadingTasks: [ObjectIdentifier: Task<Void, Never>] = [:]

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let identifier = ObjectIdentifier(urlSchemeTask)

        let task = Task { [weak self, session] in
            defer {
                self?.removeLoadingTask(identifier)
            }

            do {
                let (data, response) = try await session.data(for: urlSchemeTask.request)
                guard !Task.isCancelled else { return }
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
            } catch {
                guard !Task.isCancelled else { return }
                urlSchemeTask.didFailWithError(error)
            }
        }

        self.lock.lock()
        self.loadingTasks[identifier] = task
        self.lock.unlock()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        let identifier = ObjectIdentifier(urlSchemeTask)

        self.lock.lock()
        let task = self.loadingTasks.removeValue(forKey: identifier)
        self.lock.unlock()

        task?.cancel()
    }

    private func removeLoadingTask(_ identifier: ObjectIdentifier) {
        self.lock.lock()
        self.loadingTasks.removeValue(forKey: identifier)
        self.lock.unlock()
    }

}

/// PaywallWebViewPool
///
/// Namespace for the web view pre-warming entry point. Declared as a caseless
/// `struct` (not an `enum`) so it does not add a new public enum to the SDK's
/// consumer-facing surface (see the `no_new_public_enums` SwiftLint rule).
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public struct PaywallWebViewPool {

    private init() {}

    /// Warms the pool so it's ready. This should be invoked well before the paywall goes to render.
    public static func warmUp() {
        WebViewPool.shared.warmUp()
    }

}

#endif // canImport(UIKit)

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
        webView.load(URLRequest(url: url))

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
        config.setURLSchemeHandler(InMemoryHTMLURLSchemeHandler(), forURLScheme: "purchaseshtml")

        return config
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

        static let heightMessageHandlerName = "rcWebViewHeight"

        @Binding var height: CGFloat?
        var currentURL: URL?
        private var heightMessageHandler: WeakScriptMessageHandler?
        private weak var webView: WKWebView?
        private var heightMeasurementGeneration = 0

        init(height: Binding<CGFloat?>) {
            _height = height
        }

        func reportHeightIfNeeded(in webView: WKWebView) {
            webView.evaluateJavaScript("window.__rcReportHeight && window.__rcReportHeight()")
        }

        func registerHeightReporting(on webView: WKWebView) {
            self.webView = webView
            let handler = WeakScriptMessageHandler(delegate: self)
            self.heightMessageHandler = handler
            webView.configuration.userContentController.add(handler, name: Self.heightMessageHandlerName)
        }

        func unregisterHeightReporting(from webView: WKWebView) {
            webView.configuration.userContentController.removeScriptMessageHandler(
                forName: Self.heightMessageHandlerName
            )
            self.heightMessageHandler = nil
            self.webView = nil
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == Self.heightMessageHandlerName else { return }

            let reportedHeight: CGFloat?
            if let number = message.body as? NSNumber {
                reportedHeight = CGFloat(number.doubleValue)
            } else if let double = message.body as? Double {
                reportedHeight = CGFloat(double)
            } else {
                reportedHeight = nil
            }

            if let reportedHeight {
                self.applyHeight(reportedHeight)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(PaywallWebViewScripts.heightReportingJavaScriptSource)
            self.measureHeight(in: webView)
            let javaScript = """
            new Promise(r => {
              if (document.readyState === 'complete') { r(); return; }
              window.addEventListener('load', () => r(), { once: true });
            }).then(() => 0);
            """
            webView.evaluateJavaScript(javaScript) { [weak self, weak webView] _, _ in
                guard let self, let webView else { return }
                webView.evaluateJavaScript(PaywallWebViewScripts.heightReportingJavaScriptSource)
                self.measureHeight(in: webView)
                self.scheduleDelayedMeasurements(in: webView)
            }
        }

        private func measureHeight(in webView: WKWebView) {
            self.heightMeasurementGeneration += 1
            let generation = self.heightMeasurementGeneration

            webView.evaluateJavaScript(PaywallWebViewScripts.measureHeightJavaScript) { [weak self] result, _ in
                guard let self, generation == self.heightMeasurementGeneration else { return }

                let measuredHeight: CGFloat?
                if let number = result as? NSNumber {
                    measuredHeight = CGFloat(number.doubleValue)
                } else if let double = result as? Double {
                    measuredHeight = CGFloat(double)
                } else {
                    measuredHeight = nil
                }

                if let measuredHeight {
                    self.applyHeight(measuredHeight)
                }
            }
        }

        private func scheduleDelayedMeasurements(in webView: WKWebView) {
            let delays: [TimeInterval] = [0.05, 0.15, 0.35]
            for delay in delays {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak webView] in
                    guard let self, let webView else { return }
                    self.measureHeight(in: webView)
                }
            }
        }

        private func applyHeight(_ newHeight: CGFloat) {
            guard newHeight >= 0 else { return }
            guard abs(newHeight - (height ?? 0)) > 0.5 else { return }

            DispatchQueue.main.async {
                self.height = newHeight
            }
        }

    }

}

@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {

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

@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private final class InMemoryHTMLURLSchemeHandler: NSObject, WKURLSchemeHandler {

    private let session = URLSession(
        configuration: InMemoryHTMLFileRepository.makeURLSessionConfiguration()
    )
    private let lock = NSLock()
    private var loadingTasks: [ObjectIdentifier: Task<Void, Never>] = [:]

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let identifier = ObjectIdentifier(urlSchemeTask)

        let task = Task { [weak self, session] in
            defer {
                self?.removeLoadingTask(identifier)
            }

            do {
                let (data, response) = try await session.data(for: urlSchemeTask.request)
                guard !Task.isCancelled else { return }
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
            } catch {
                guard !Task.isCancelled else { return }
                urlSchemeTask.didFailWithError(error)
            }
        }

        self.lock.lock()
        self.loadingTasks[identifier] = task
        self.lock.unlock()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        let identifier = ObjectIdentifier(urlSchemeTask)

        self.lock.lock()
        let task = self.loadingTasks.removeValue(forKey: identifier)
        self.lock.unlock()

        task?.cancel()
    }

    private func removeLoadingTask(_ identifier: ObjectIdentifier) {
        self.lock.lock()
        self.loadingTasks.removeValue(forKey: identifier)
        self.lock.unlock()
    }

}

#endif // os(macOS) && canImport(WebKit)

#endif // !os(tvOS)
