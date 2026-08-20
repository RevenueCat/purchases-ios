//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBundlePrewarmer.swift
//
//  Created by Jacob Zivan Rakidzich on 8/17/26.

import Foundation
@_spi(Internal) import RevenueCat

#if canImport(WebKit)
import WebKit
#endif

/// Loads a batch of web-view entry URLs into hidden `WKWebView`s so WebKit can populate its HTTP cache.
///
/// Unused: nothing in the SDK calls this yet. `WebPage` is intentionally not used; it is unavailable on
/// the SDK's deployment targets.
final class WebBundlePrewarmer {

    static let defaultMaxConcurrentLoads = 3

    private let maxConcurrentLoads: Int
    private let load: @MainActor @Sendable (URL) async -> Void

    init(
        maxConcurrentLoads: Int = defaultMaxConcurrentLoads,
        identifierStore: WebViewDataStoreIdentifierStore = .init()
    ) {
        self.maxConcurrentLoads = maxConcurrentLoads
        self.load = { url in
            await Self.loadURL(url, storeID: identifierStore.identifier())
        }
    }

    #if DEBUG
    // Test initializer — creating WKWebView in XCTest crashes the suite.
    init(
        maxConcurrentLoads: Int = defaultMaxConcurrentLoads,
        load: @escaping @MainActor @Sendable (URL) async -> Void
    ) {
        self.maxConcurrentLoads = maxConcurrentLoads
        self.load = load
    }
    #endif

    /// Loads every URL in `urls` with at most ``maxConcurrentLoads`` in flight. One failure does
    /// not cancel the rest of the batch.
    func prewarm(_ urls: [URLWithValidation]) async {
        guard !urls.isEmpty else { return }

        let concurrency = min(max(self.maxConcurrentLoads, 1), urls.count)

        await withTaskGroup(of: Void.self) { group in
            var nextIndex = 0

            func startNext() {
                guard nextIndex < urls.count else { return }
                let url = urls[nextIndex].url
                nextIndex += 1
                group.addTask { [load] in
                    await load(url)
                }
            }

            for _ in 0..<concurrency {
                startNext()
            }

            for await _ in group {
                startNext()
            }
        }
    }

}

private extension WebBundlePrewarmer {

    static let loadTimeout: TimeInterval = 15

    @MainActor
    static func loadURL(_ url: URL, storeID: UUID) async {
        #if !os(tvOS) && !os(watchOS) && canImport(WebKit)
        if #available(iOS 17.0, macOS 14.0, *) {
            await self.loadUsingWKWebView(url, storeID: storeID)
        }
        #endif
    }

    #if !os(tvOS) && !os(watchOS) && canImport(WebKit)
    @available(iOS 17.0, macOS 14.0, *)
    @MainActor
    static func loadUsingWKWebView(_ url: URL, storeID: UUID) async {
        let configuration = WKWebViewConfiguration()
        configuration.setPersistentStoreIfAble(withID: storeID)
        configuration.mediaTypesRequiringUserActionForPlayback = .all

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setAllMediaPlaybackSuspended(true, completionHandler: nil)
        let delegate = NavigationCompletion()
        webView.navigationDelegate = delegate
        webView.load(URLRequest(url: url))

        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                await delegate.completed()
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(Self.loadTimeout * 1_000_000_000))
            }
            await group.next()
            group.cancelAll()
        }

        delegate.finish()
        webView.stopLoading()
        webView.navigationDelegate = nil
        withExtendedLifetime(webView) {}
    }

    @MainActor
    final class NavigationCompletion: NSObject, WKNavigationDelegate {

        private var continuation: CheckedContinuation<Void, Never>?
        private var isFinished = false

        func completed() async {
            if self.isFinished { return }
            await withTaskCancellationHandler {
                await withCheckedContinuation { continuation in
                    if self.isFinished {
                        continuation.resume()
                    } else {
                        self.continuation = continuation
                    }
                }
            } onCancel: { [weak self] in
                Task { @MainActor [weak self] in
                    self?.finish()
                }
            }
        }

        func finish() {
            guard !self.isFinished else { return }
            self.isFinished = true
            self.continuation?.resume()
            self.continuation = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Logger.debug(Strings.paywall_web_view_loaded(webView.url))
            self.finish()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Logger.debug(Strings.paywall_web_view_load_failed(error.localizedDescription))
            self.finish()
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            Logger.debug(Strings.paywall_web_view_load_failed(error.localizedDescription))
            self.finish()
        }

    }
    #endif

}

#if !os(tvOS) && !os(watchOS) && canImport(WebKit)
extension WKWebViewConfiguration {
    func setPersistentStoreIfAble(withID id: UUID) {
        #if compiler(>=5.9)
        if #available(iOS 17.0, macOS 14.0, *) {
            self.websiteDataStore = .init(forIdentifier: id)
            return
        }
        #endif
        self.websiteDataStore = .nonPersistent()
    }
}
#endif
