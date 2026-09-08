//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebCheckoutViewModel.swift
//
//  Created by Antonio Pallares on 4/9/26.
//

#if os(iOS) && canImport(WebKit)

@_spi(Internal) import RevenueCat
import SwiftUI
import WebKit

/// Owns the web view that presents a checkout page.
///
/// Kept separate from the view so a caller can build it, start loading, and only then present the
/// result: the page is a payment provider's and takes a while to paint, and re-creating the web view
/// when SwiftUI re-makes the view would restart that load.
@available(iOS 15.0, *)
@MainActor
final class WebCheckoutViewModel: NSObject, ObservableObject {

    enum LoadState {

        /// Nothing has been asked to load yet.
        case idle
        case loading
        case loaded
        /// A page that has painted is navigating to the provider's next step.
        case navigating
        /// The page could not be shown. The presenting host decides what the customer sees.
        case failed
        /// The page reached a return URL. Terminal: nothing moves the state after it.
        case finished

        /// Whether the customer has nothing to look at yet.
        var isWaitingForFirstPaint: Bool {
            self == .idle || self == .loading
        }

    }

    @Published private(set) var loadState: LoadState = .idle

    /// Called once, when the page navigates to the return URL.
    var onFinished: ((WebCheckoutReturnStatus) -> Void)?

    /// Called for links the page opens outside the checkout, for the host to hand to the browser.
    var onOpenExternalURL: ((URL) -> Void)?

    let webView: WKWebView

    private let checkoutURL: URL
    private let returnURL: WebCheckoutReturnURL?

    private var hasPainted: Bool {
        self.loadState == .loaded || self.loadState == .navigating
    }

    /// - Parameter checkoutURL: The provider-hosted page to present.
    /// - Parameter successURL: Where the provider sends the customer once checkout succeeds.
    /// - Parameter cancelURL: Where the provider sends the customer once checkout is abandoned.
    /// - Parameter dataStoreIdentifierStore: Supplies the website data store shared with RevenueCat's
    /// other web views.
    init(
        checkoutURL: URL,
        successURL: URL,
        cancelURL: URL,
        dataStoreIdentifierStore: WebViewDataStoreIdentifierStore
    ) {
        self.checkoutURL = checkoutURL
        self.returnURL = WebCheckoutReturnURL(successURL: successURL, cancelURL: cancelURL)
        self.webView = Self.makeWebView(dataStoreID: dataStoreIdentifierStore.identifier())

        super.init()

        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self

        if self.returnURL == nil {
            Logger.error(Strings.web_checkout_unusable_return_urls(success: successURL, cancel: cancelURL))
        }
    }

    /// Begins the first load. Later calls do nothing, so a host can call it on every appearance.
    func loadIfNeeded() {
        guard self.loadState == .idle else {
            return
        }

        self.transition(to: .loading)
        self.webView.load(URLRequest(url: self.checkoutURL))
    }

    /// Ignores everything that arrives after the checkout ended, so a navigation still in flight
    /// cannot blank the page while the host is dismissing.
    private func transition(to state: LoadState) {
        guard self.loadState != .finished else {
            return
        }

        self.loadState = state
    }

    /// Installs no `WKUserScript`: on iOS 15 that disables Apple Pay for every document the web view
    /// loads. https://webkit.org/blog/9674/new-webkit-features-in-safari-13/
    private static func makeWebView(dataStoreID: UUID) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.setPersistentStoreIfAble(withID: dataStoreID)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = false

        return webView
    }

    private func handleFailure(_ error: Error) {
        // We cancel the return-URL navigation ourselves, and it arrives here looking like an error.
        guard !WebViewNavigationFailure.isCancellation(error) else {
            return
        }

        Logger.error(Strings.web_checkout_load_failed((error as NSError).localizedDescription))
        self.transition(to: .failed)
    }

    private func finish(returnedFrom url: URL?) {
        guard self.loadState != .finished else {
            return
        }

        self.loadState = .finished

        guard let status = self.returnURL?.status(of: url) else {
            Logger.warning(Strings.web_checkout_return_status_missing)
            // Reported as a cancel rather than guessed optimistically: the caller confirms the outcome
            // against the backend either way, and a wrong `success` would show the customer a purchase
            // that never happened.
            self.onFinished?(.cancel)
            return
        }

        self.onFinished?(status)
    }

}

@available(iOS 15.0, *)
extension WebCheckoutViewModel: WKNavigationDelegate {

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let url = navigationAction.request.url
        let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true

        if isMainFrame, self.returnURL?.matches(url) == true {
            decisionHandler(.cancel)
            self.finish(returnedFrom: url)
            return
        }

        decisionHandler(.allow)
    }

    // WebKit reports an HTTP 4xx/5xx as a *successful* navigation, rendering the error body and never
    // calling `didFail*`, so the status code has to be caught here instead.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if let response = navigationResponse.response as? HTTPURLResponse,
           WebViewHTTPStatus.isTerminalError(
            statusCode: response.statusCode,
            isMainFrame: navigationResponse.isForMainFrame
           ) {
            Logger.error(Strings.web_checkout_http_error(statusCode: response.statusCode))
            self.transition(to: .failed)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // Only the first load shows a spinner. Later steps are managed by the provider.
        self.transition(to: self.hasPainted ? .navigating : .loading)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.transition(to: .loaded)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.handleFailure(error)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        self.handleFailure(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        Logger.error(Strings.web_checkout_content_process_terminated)
        self.transition(to: .failed)
    }

}

@available(iOS 15.0, *)
extension WebCheckoutViewModel: WKUIDelegate {

    /// Handles what the page opens in a new window, which WebKit routes here and never through the
    /// navigation delegate. Without this, a `target="_blank"` link — the provider's terms and privacy
    /// notices, typically — does nothing at all when tapped.
    ///
    /// These go to the browser rather than loading in place. The customer keeps a way back there, where
    /// this sheet has no navigation of its own, and the checkout they were part-way through stays on
    /// screen underneath.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let url = navigationAction.request.url,
              WebViewOrigin(url: url)?.isHTTPS == true else {
            return nil
        }

        self.onOpenExternalURL?(url)

        // Never a second web view: the checkout owns the one frame we control.
        return nil
    }

}

#endif
