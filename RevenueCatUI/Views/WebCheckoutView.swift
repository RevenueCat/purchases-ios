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

@_spi(Internal) import RevenueCat
import SwiftUI
import WebKit

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct WebCheckoutView: View {

    let url: URL
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WebCheckoutViewModel()

    var body: some View {
        NavigationView {
            WebCheckoutWebView(url: url, viewModel: viewModel)
                .ignoresSafeArea(edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .modifier(MediumDetentModifier())
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private class WebCheckoutViewModel: ObservableObject {
    @Published var isLoading: Bool = true
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct WebCheckoutWebView: UIViewRepresentable {

    let url: URL
    let viewModel: WebCheckoutViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.minimumZoomScale = 1.0
        webView.load(URLRequest(url: url))

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {

        let viewModel: WebCheckoutViewModel

        init(viewModel: WebCheckoutViewModel) {
            self.viewModel = viewModel
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.viewModel.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.viewModel.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            self.handleLoadFailure(error)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            // TLS failures (untrusted vite cert) land here, not in didFail.
            self.handleLoadFailure(error)
        }

        func webView(
            _ webView: WKWebView,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            // PoC only: vite serves HTTPS with a local pem. WKWebView has no "proceed anyway"
            // prompt, so localhost would otherwise fail and leave the drawer spinning.
            let space = challenge.protectionSpace
            if space.authenticationMethod == NSURLAuthenticationMethodServerTrust,
               space.host == "localhost",
               let trust = space.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: trust))
                return
            }
            completionHandler(.performDefaultHandling, nil)
        }

        private func handleLoadFailure(_ error: Error) {
            Logger.error(Strings.failed_to_open_url_external_browser(error.localizedDescription))
            DispatchQueue.main.async {
                self.viewModel.isLoading = false
            }
        }
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct MediumDetentModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.presentationDetents([.medium])
        } else {
            content
        }
    }
}

#endif
