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

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WebViewComponentView: View {

    let viewModel: WebViewComponentViewModel

    #if canImport(UIKit)
    @State private var dynamicHeight: CGFloat = .zero
    #endif

    var body: some View {
        #if canImport(UIKit)
        WebViewRepresentable(url: viewModel.url, height: $dynamicHeight)
            .frame(height: dynamicHeight)
            .background(Color.clear)
            .accessibilityHidden(dynamicHeight == .zero)
        #else
        EmptyView()
        #endif
    }

}

#if canImport(UIKit)

import WebKit

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
private struct WebViewRepresentable: UIViewRepresentable {

    let url: URL
    @Binding var height: CGFloat

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

        webView.scrollView.addObserver(context.coordinator,
                                       forKeyPath: #keyPath(UIScrollView.contentSize),
                                       options: [.new, .initial],
                                       context: nil)

        context.coordinator.currentURL = url
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.currentURL != url {
            context.coordinator.currentURL = url
            uiView.load(URLRequest(url: url))
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.scrollView.removeObserver(coordinator, forKeyPath: #keyPath(UIScrollView.contentSize))
        uiView.navigationDelegate = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(height: $height)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {

        @Binding var height: CGFloat
        var currentURL: URL?

        init(height: Binding<CGFloat>) {
            _height = height
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updateHeight(from: webView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self, weak webView] in
                if let webView { self?.updateHeight(from: webView) }
            }
            // Re-check after all resources finish loading
            let js = """
            new Promise(r => {
              if (document.readyState === 'complete') { r(); return; }
              window.addEventListener('load', () => r(), { once: true });
            }).then(() => 0);
            """
            webView.evaluateJavaScript(js) { [weak self, weak webView] _, _ in
                if let webView { self?.updateHeight(from: webView) }
            }
        }

        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            guard keyPath == #keyPath(UIScrollView.contentSize),
                  let scrollView = object as? UIScrollView,
                  scrollView.frame.width > 0 else { return }
            let newHeight = scrollView.contentSize.height
            if abs(newHeight - height) > 0.5 {
                DispatchQueue.main.async { self.height = newHeight }
            }
        }

        private func updateHeight(from webView: WKWebView) {
            let newHeight = webView.scrollView.contentSize.height
            if abs(newHeight - height) > 0.5 {
                height = newHeight
            }
        }

    }

}

private final class AutoSizingWebView: WKWebView {

    init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        super.init(frame: .zero, configuration: config)
        isOpaque = false
        backgroundColor = .clear
        scrollView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

}

#endif // canImport(UIKit)

#endif // !os(tvOS)
