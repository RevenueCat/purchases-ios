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

import Combine
import SwiftUI
import WebKit

/// Shows a checkout page, with a spinner until it first paints, and an error in its place if it never does.
@available(iOS 15.0, *)
struct WebCheckoutView: View {

    @ObservedObject
    var viewModel: WebCheckoutViewModel

    @Environment(\.openURL)
    private var openURL

    var body: some View {
        ZStack {
            if self.viewModel.loadState == .failed {
                ErrorView()
                    .padding()
            } else {
                // The page's background reaches the bottom edge rather than stopping above the home indicator,
                // which would leave a strip of the host's background under a checkout that fills its sheet.
                WebCheckoutWebView(webView: self.viewModel.webView)
                    .ignoresSafeArea(.container, edges: .bottom)
            }

            if self.viewModel.loadState.isWaitingForFirstPaint {
                ProgressView()
            }
        }
        .onAppear {
            self.viewModel.onOpenExternalURL = { url in
                self.openURL(url) { accepted in
                    if !accepted {
                        Logger.warning(Strings.web_checkout_external_url_not_opened(scheme: url.scheme ?? ""))
                    }
                }
            }
            self.viewModel.loadIfNeeded()
        }
    }

}

@available(iOS 15.0, *)
private struct WebCheckoutWebView: UIViewRepresentable {

    let webView: WKWebView

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        self.attach(to: container, coordinator: context.coordinator)
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        self.attach(to: container, coordinator: context.coordinator)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {

        var pageBackgroundObservation: AnyCancellable?

    }

    /// The web view outlives any one container, since it is owned by the view model so that loading can
    /// start before presentation. Re-parenting on every update covers SwiftUI re-making the
    /// representable, which would otherwise leave a container empty and the checkout blank.
    ///
    /// The web view stops at the safe area while the container fills the strip below it with the page's
    /// background. A web view that reached under the home indicator would give the page two viewport heights,
    /// one with the strip and one without, and pages sized to both switch between them on every frame.
    private func attach(to container: UIView, coordinator: Coordinator) {
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
            self.webView.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor)
        ])

        coordinator.pageBackgroundObservation = self.webView
            .publisher(for: \.underPageBackgroundColor)
            .receive(on: DispatchQueue.main)
            .sink { [weak container] color in
                container?.backgroundColor = color
            }
    }

}

#endif
