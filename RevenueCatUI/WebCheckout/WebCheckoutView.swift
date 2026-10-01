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
//  Created by Antonio Pallares on 4/9/26.
//

#if os(iOS) && canImport(WebKit)

import SwiftUI
import WebKit

/// Shows a checkout page, with a spinner until it first paints.
///
/// Hides the page when loading fails, without showing an error or offering a retry.
@available(iOS 15.0, *)
struct WebCheckoutView: View {

    @ObservedObject
    var viewModel: WebCheckoutViewModel

    @Environment(\.openURL)
    private var openURL

    var body: some View {
        ZStack {
            if self.viewModel.loadState != .failed {
                // The page paints to the bottom edge rather than stopping above the home indicator, which
                // would leave a strip of the host's background under a checkout that fills its sheet. What
                // the page puts there stays reachable: the web view insets its own content by the safe area.
                WebCheckoutWebView(webView: self.viewModel.webView)
                    .ignoresSafeArea(.container, edges: .bottom)
            }

            if self.viewModel.loadState.isWaitingForFirstPaint {
                ProgressView()
            }
        }
        .onAppear {
            self.viewModel.onOpenExternalURL = { self.openURL($0) }
            self.viewModel.loadIfNeeded()
        }
    }

}

@available(iOS 15.0, *)
private struct WebCheckoutWebView: UIViewRepresentable {

    let webView: WKWebView

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        self.attach(to: container)
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        self.attach(to: container)
    }

    /// The web view outlives any one container, since it is owned by the view model so that loading can
    /// start before presentation. Re-parenting on every update covers SwiftUI re-making the
    /// representable, which would otherwise leave a container empty and the checkout blank.
    private func attach(to container: UIView) {
        guard self.webView.superview !== container else {
            return
        }

        self.webView.removeFromSuperview()
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(self.webView)
        NSLayoutConstraint.activate([
            self.webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            self.webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            self.webView.topAnchor.constraint(equalTo: container.topAnchor),
            self.webView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

}

#endif
