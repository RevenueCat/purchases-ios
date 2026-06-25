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
            // Height auto-sizing is layered on in a follow-up change; until then render at a fixed
            // initial height.
            let height = dynamicHeight ?? Self.initialHeight
            WebViewRepresentable(url: resolvedURL)
                .modifier(WebViewSizeModifier(size: viewModel.size, measuredHeight: height))
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

#endif

#if canImport(UIKit) && canImport(WebKit)

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
private struct WebViewRepresentable: UIViewRepresentable {

    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: Self.makeConfiguration())
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

        context.coordinator.currentURL = url
        PaywallWebViewScripts.loadIsolated(url: url, on: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.currentURL != url {
            context.coordinator.currentURL = url
            uiView.load(URLRequest(url: url))
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.navigationDelegate = nil
        uiView.scrollView.delegate = nil
        uiView.stopLoading()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private static func makeConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.allowsInlineMediaPlayback = true
        config.userContentController.addUserScript(PaywallWebViewScripts.disableZoomUserScript)
        return config
    }

    final class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {

        var currentURL: URL?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return nil
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            scrollView.zoomScale = 1.0
        }

    }

}

#endif // canImport(UIKit) && canImport(WebKit)

#endif // !os(tvOS)
