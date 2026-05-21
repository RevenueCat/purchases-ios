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
    @State private var displayURL: URL?
    #endif

    var body: some View {
        #if canImport(UIKit)
        Group {
            if let displayURL {
                WebViewRepresentable(url: displayURL, height: $dynamicHeight)
                    .frame(height: dynamicHeight)
                    .background(Color.clear)
                    .accessibilityHidden(dynamicHeight == .zero)
            } else {
                Color.clear
                    .frame(height: .zero)
                    .accessibilityHidden(true)
            }
        }
        .task(id: viewModel.url) {
            let resolvedURL = await viewModel.displayURL()
            if resolvedURL != displayURL {
                dynamicHeight = .zero
                displayURL = resolvedURL
            }
        }
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

        context.coordinator.observeHeightChanges(in: webView.scrollView)

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
        coordinator.contentSizeObservation = nil
        uiView.navigationDelegate = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(height: $height)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {

        @Binding var height: CGFloat
        var currentURL: URL?
        var contentSizeObservation: NSKeyValueObservation?

        init(height: Binding<CGFloat>) {
            _height = height
        }

        func observeHeightChanges(in scrollView: UIScrollView) {
            let options: NSKeyValueObservingOptions = [.new, .initial]
            contentSizeObservation = scrollView.observe(\.contentSize, options: options) { [weak self] scrollView, _ in
                self?.updateHeight(from: scrollView)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updateHeight(from: webView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self, weak webView] in
                if let webView { self?.updateHeight(from: webView) }
            }
            // Re-check after all resources finish loading
            let javaScript = """
            new Promise(r => {
              if (document.readyState === 'complete') { r(); return; }
              window.addEventListener('load', () => r(), { once: true });
            }).then(() => 0);
            """
            webView.evaluateJavaScript(javaScript) { [weak self, weak webView] _, _ in
                if let webView { self?.updateHeight(from: webView) }
            }
        }

        private func updateHeight(from scrollView: UIScrollView) {
            guard scrollView.frame.width > 0 else { return }

            let newHeight = scrollView.contentSize.height
            if abs(newHeight - height) > 0.5 {
                DispatchQueue.main.async { self.height = newHeight }
            }
        }

        private func updateHeight(from webView: WKWebView) {
            self.updateHeight(from: webView.scrollView)
        }

    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class AutoSizingWebView: WKWebView {

    init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.setURLSchemeHandler(InMemoryHTMLURLSchemeHandler(), forURLScheme: "purchaseshtml")
        super.init(frame: .zero, configuration: config)
        isOpaque = false
        backgroundColor = .clear
        scrollView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

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

#endif // canImport(UIKit)

#endif // !os(tvOS)
