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

    let config: EmbeddedCheckoutConfig
    var onPurchaseCompleted: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WebCheckoutViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                WebCheckoutWebView(config: config, viewModel: viewModel)
                    .ignoresSafeArea(edges: .bottom)

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
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
        .onChange(of: viewModel.checkoutOutcome) { outcome in
            guard let outcome else { return }
            switch outcome {
            case .complete(let redeemURL):
                Task {
                    await self.finishPurchase(redeemURL: redeemURL)
                }
            case .cancelled:
                self.dismiss()
            case .error:
                break
            }
        }
    }

    @MainActor
    private func finishPurchase(redeemURL: URL?) async {
        if Purchases.isConfigured {
            if let redeemURL, let redemption = Purchases.parseAsWebPurchaseRedemption(redeemURL) {
                _ = await Purchases.shared.redeemWebPurchase(redemption)
            } else {
                _ = try? await Purchases.shared.customerInfo()
            }
        }

        self.dismiss()
        self.onPurchaseCompleted?()
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private class WebCheckoutViewModel: ObservableObject {

    enum CheckoutOutcome: Equatable {
        case complete(URL?)
        case cancelled
        case error(String)
    }

    @Published var isLoading: Bool = true
    @Published var checkoutOutcome: CheckoutOutcome?

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct WebCheckoutWebView: UIViewRepresentable {

    static let messageHandlerName = "rcCheckout"

    let config: EmbeddedCheckoutConfig
    let viewModel: WebCheckoutViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        configuration.userContentController.add(context.coordinator, name: Self.messageHandlerName)
        context.coordinator.userContentController = configuration.userContentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.minimumZoomScale = 1.0
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        if let html = config.assembledHTML() {
            webView.loadHTMLString(html, baseURL: EmbeddedCheckoutConfig.pageBaseURL)
        } else {
            Logger.error(Strings.embedded_checkout_skipped(
                "Could not assemble bundled checkout HTML."
            ))
            context.coordinator.failLoading("Could not assemble bundled checkout HTML.")
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.userContentController?.removeScriptMessageHandler(forName: Self.messageHandlerName)
        uiView.stopLoading()
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

        let viewModel: WebCheckoutViewModel
        var userContentController: WKUserContentController?

        init(viewModel: WebCheckoutViewModel) {
            self.viewModel = viewModel
        }

        func failLoading(_ message: String) {
            DispatchQueue.main.async {
                self.viewModel.isLoading = false
                self.viewModel.checkoutOutcome = .error(message)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            self.failLoading(error.localizedDescription)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            self.failLoading(error.localizedDescription)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == WebCheckoutWebView.messageHandlerName else { return }
            guard let body = message.body as? [String: Any],
                  let type = body["type"] as? String else {
                return
            }

            DispatchQueue.main.async {
                self.handleCheckoutMessage(type: type, body: body)
            }
        }

        private func handleCheckoutMessage(type: String, body: [String: Any]) {
            switch type {
            case "ready":
                self.viewModel.isLoading = false
            case "complete":
                self.viewModel.isLoading = false
                let redeemURL = (body["redeemUrl"] as? String).flatMap(URL.init(string:))
                self.viewModel.checkoutOutcome = .complete(redeemURL)
            case "cancelled":
                self.viewModel.isLoading = false
                self.viewModel.checkoutOutcome = .cancelled
            case "error":
                self.viewModel.isLoading = false
                let errorMessage = body["message"] as? String ?? "Unknown checkout error"
                Logger.error("Embedded checkout error: \(errorMessage)")
                self.viewModel.checkoutOutcome = .error(errorMessage)
            default:
                break
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
