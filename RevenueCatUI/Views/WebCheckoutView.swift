//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebCheckoutView.swift
//
//  Created by Antonio Pallares on 2026-03-19.

#if canImport(WebKit) && canImport(UIKit) && !os(tvOS)

import SwiftUI
import WebKit

enum WebCheckoutSheetResult: Equatable {
    case success
    case cancelled
}

/// Owns a `WKWebView` so checkout can start loading before the sheet is on screen.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
@MainActor
final class WebCheckoutViewModel: NSObject, ObservableObject, WKNavigationDelegate {

    private static let readyTimeoutNanoseconds: UInt64 = 3_000_000_000

    let webView: WKWebView

    private(set) var url: URL?

    @Published private(set) var isLoading: Bool = true

    var onFinished: ((WebCheckoutSheetResult) -> Void)?

    private var hasBecomeReady = false
    private var didFinishCheckout = false
    private var readyContinuations: [CheckedContinuation<Void, Never>] = []

    override init() {
        let configuration = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.bounces = false
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.minimumZoomScale = 1.0
        self.webView = webView

        super.init()

        webView.navigationDelegate = self
        Self.attachOffscreen(webView)
    }

    convenience init(url: URL) {
        self.init()
        self.load(url)
    }

    func load(_ url: URL) {
        self.url = url
        if !self.hasBecomeReady {
            self.isLoading = true
        }
        self.webView.load(URLRequest(url: url))
    }

    /// Waits until the first page load finishes, or `3` seconds, whichever is first.
    func waitUntilReady() async {
        guard self.isLoading else { return }

        await withCheckedContinuation { continuation in
            self.readyContinuations.append(continuation)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: Self.readyTimeoutNanoseconds)
                self.resumeReadyWaiters()
            }
        }
    }

    deinit {
        let webView = self.webView
        let cleanup = {
            webView.stopLoading()
            webView.removeFromSuperview()
        }
        if Thread.isMainThread {
            cleanup()
        } else {
            DispatchQueue.main.async(execute: cleanup)
        }
    }

    func prepareForDisplay() {
        self.webView.alpha = 1
        self.webView.isUserInteractionEnabled = true
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url, Self.isAppReturnURL(url) else {
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)
        self.finishCheckout(Self.result(from: url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.markReady()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.markReady()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        self.markReady()
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // After the first paint, later Stripe redirects should not bring the spinner back.
        if !self.hasBecomeReady {
            self.isLoading = true
        }
    }

    private func markReady() {
        self.hasBecomeReady = true
        self.isLoading = false
        self.resumeReadyWaiters()
    }

    private func resumeReadyWaiters() {
        let waiters = self.readyContinuations
        self.readyContinuations.removeAll()
        waiters.forEach { $0.resume() }
    }

    private func finishCheckout(_ result: WebCheckoutSheetResult) {
        guard !self.didFinishCheckout else { return }
        self.didFinishCheckout = true
        self.onFinished?(result)
    }

    private static func attachOffscreen(_ webView: WKWebView) {
        guard webView.superview == nil else { return }
        guard let window = keyWindow() else { return }

        webView.frame = CGRect(
            origin: CGPoint(x: -window.bounds.width, y: 0),
            size: window.bounds.size
        )
        webView.alpha = 0.01
        webView.isUserInteractionEnabled = false
        window.addSubview(webView)
    }

    private static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    static func isAppReturnURL(_ url: URL) -> Bool {
        return url.path.contains("/hosted-checkout-return")
    }

    static func result(from url: URL) -> WebCheckoutSheetResult {
        let status = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "status" })?
            .value
        return status == "success" ? .success : .cancelled
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct WebCheckoutView: View {

    @StateObject private var viewModel: WebCheckoutViewModel
    var onFinished: ((WebCheckoutSheetResult) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var didFinish = false

    init(url: URL, onFinished: ((WebCheckoutSheetResult) -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: WebCheckoutViewModel(url: url))
        self.onFinished = onFinished
    }

    init(viewModel: WebCheckoutViewModel, onFinished: ((WebCheckoutSheetResult) -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onFinished = onFinished
    }

    var body: some View {
        ZStack {
            WebCheckoutWebView(viewModel: viewModel)
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            self.viewModel.onFinished = { result in
                self.finish(result)
            }
        }
        .modifier(HostedCheckoutSheetPresentationModifier())
    }

    private func finish(_ result: WebCheckoutSheetResult) {
        guard !self.didFinish else { return }
        self.didFinish = true

        if let onFinished {
            onFinished(result)
        } else {
            dismiss()
        }
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct WebCheckoutWebView: UIViewRepresentable {

    let viewModel: WebCheckoutViewModel

    func makeUIView(context: Context) -> WKWebView {
        self.viewModel.prepareForDisplay()
        return self.viewModel.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct HostedCheckoutSheetPresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationDetents([.medium])
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
        } else if #available(iOS 16.0, *) {
            content
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}

#endif
