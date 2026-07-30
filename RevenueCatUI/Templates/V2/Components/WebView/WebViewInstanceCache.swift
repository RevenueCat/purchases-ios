//
//  WebViewInstanceCache.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 30/7/26.
//

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) && !os(watchOS) && canImport(WebKit) // For Paywalls V2

import WebKit

/// Identity of a cached web view. Two components that agree on all of these can share one loaded
/// document; a change to any of them means a different bridge and a different navigation, so the
/// cached instance must be discarded rather than reused.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WebViewInstanceKey: Hashable {

    let componentID: String
    let url: URL
    let fitsWidth: Bool
    let fitsHeight: Bool

}

/// The live web view behind a `web_view` component: the `WKWebView` itself, its bridge session, and
/// the sizing/failure state derived from them.
///
/// This deliberately outlives the SwiftUI subtree that displays it. `ViewThatFits` (used by the root
/// stack when it fills its container) instantiates *every* candidate to measure it, and swaps
/// candidates whenever a fit-axis child reports a new size. Holding this state in `@State`/
/// `@StateObject` meant each of those events built a brand new `WKWebView` and reloaded the page
/// from the network, which showed up as the component blanking out and coming back.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewInstance: ObservableObject {

    let session: WebViewSession

    /// Last size reported by the content, per axis. `nil` until the content reports one (and again
    /// after a new document commits), which is when the component falls back to its declared
    /// `fit` default.
    @Published private(set) var measuredWidth: CGFloat?
    @Published private(set) var measuredHeight: CGFloat?

    @Published private(set) var processTerminated = false
    @Published private(set) var loadFailed = false

    private var webView: PlatformWebView?
    private var navigationDelegateObject: AnyObject?

    init(key: WebViewInstanceKey, expectedOrigin: WebViewOrigin) {
        // `evaluateJavaScript`/`currentURL` are rebound to the live web view in `webView(creatingWith:)`;
        // the no-op defaults only cover the window before it is created.
        self.session = WebViewSession(
            componentID: key.componentID,
            expectedOrigin: expectedOrigin,
            fitAxes: (width: key.fitsWidth, height: key.fitsHeight),
            evaluateJavaScript: { _ in false },
            currentURL: { nil }
        )

        self.session.onContentResize = { [weak self] width, height in
            if let width {
                self?.measuredWidth = width
            }
            if let height {
                self?.measuredHeight = height
            }
        }
        self.session.onDocumentReset = { [weak self] in
            self?.measuredWidth = nil
            self?.measuredHeight = nil
        }
    }

    /// The navigation delegate for this component, creating it on first use. Retained here because
    /// `WKWebView.navigationDelegate` is a weak reference.
    func navigationDelegate<Delegate: AnyObject>(creating factory: () -> Delegate) -> Delegate {
        if let existing = self.navigationDelegateObject as? Delegate {
            return existing
        }

        let created = factory()
        self.navigationDelegateObject = created
        return created
    }

    /// The web view for this component, creating and loading it on first use.
    ///
    /// `factory` is only invoked once per instance, no matter how many SwiftUI hosts ask for it.
    func webView(creatingWith factory: () -> PlatformWebView) -> PlatformWebView {
        if let webView = self.webView {
            return webView
        }

        let webView = factory()
        self.webView = webView
        self.session.evaluateJavaScript = { [weak webView] script in
            // A released web view means the frame never reaches the page; report the miss
            guard let webView else { return false }
            webView.evaluateJavaScript(script) { _, error in
                if let error {
                    Logger.debug(Strings.paywall_web_view_post_message_failed(String(describing: error)))
                }
            }
            return true
        }
        self.session.currentURL = { [weak webView] in
            webView?.url
        }
        return webView
    }

    func markProcessTerminated() {
        self.processTerminated = true
    }

    func markLoadFailed() {
        self.loadFailed = true
    }

    /// Moves the web view into `host`, which is the SwiftUI-owned container that is currently on
    /// screen. A `ViewThatFits` swap replaces the container but not the web view, so re-parenting
    /// here is what keeps the loaded document alive across the swap.
    func attachWebView(to host: WebViewHostView) {
        guard let webView = self.webView, webView.superview !== host else {
            return
        }

        webView.removeFromSuperview()
        webView.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            webView.topAnchor.constraint(equalTo: host.topAnchor),
            webView.bottomAnchor.constraint(equalTo: host.bottomAnchor)
        ])
    }

    /// Releases the web view and its message handlers. Called only once no SwiftUI subtree holds a
    /// lease on this instance, so an unmounted `ViewThatFits` candidate can never tear down a web
    /// view another candidate is still showing.
    func tearDown() {
        self.navigationDelegateObject = nil

        guard let webView = self.webView else {
            return
        }

        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: WebViewEnvelope.messageHandlerName
        )
        #if os(iOS)
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: WebViewGestureProbe.messageHandlerName
        )
        #endif
        webView.navigationDelegate = nil
        webView.stopLoading()
        webView.removeFromSuperview()
        self.webView = nil
    }

}

/// Keeps one ``WebViewInstance`` alive per identity for as long as at least one SwiftUI subtree is
/// displaying it.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewInstanceCache {

    static let shared = WebViewInstanceCache()

    private var instances: [WebViewInstanceKey: WebViewInstance] = [:]
    private var leaseCounts: [WebViewInstanceKey: Int] = [:]

    func acquire(key: WebViewInstanceKey, expectedOrigin: WebViewOrigin) -> WebViewInstance {
        self.leaseCounts[key, default: 0] += 1

        if let instance = self.instances[key] {
            return instance
        }

        let instance = WebViewInstance(key: key, expectedOrigin: expectedOrigin)
        self.instances[key] = instance
        return instance
    }

    func release(key: WebViewInstanceKey) {
        guard let count = self.leaseCounts[key] else {
            return
        }

        guard count > 1 else {
            self.leaseCounts.removeValue(forKey: key)
            self.instances.removeValue(forKey: key)?.tearDown()
            return
        }

        self.leaseCounts[key] = count - 1
    }

}

/// Ties a ``WebViewInstance`` lease to the lifetime of one SwiftUI subtree.
///
/// Held as a `@StateObject`, so SwiftUI creates one per mounted subtree (including each
/// `ViewThatFits` candidate) and deallocates it when that subtree goes away. The instance itself is
/// only torn down once the last lease is gone.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewInstanceLease: ObservableObject {

    let instance: WebViewInstance

    private let key: WebViewInstanceKey

    init(key: WebViewInstanceKey, expectedOrigin: WebViewOrigin) {
        self.key = key
        self.instance = WebViewInstanceCache.shared.acquire(key: key, expectedOrigin: expectedOrigin)
    }

    deinit {
        // `deinit` is not main-actor isolated, so hop rather than assume. Releasing a tick late is
        // safe: a replacement subtree always acquires before the outgoing lease is deallocated, so
        // the count never reaches zero while the component is still on screen.
        let key = self.key
        Task { @MainActor in
            WebViewInstanceCache.shared.release(key: key)
        }
    }

}

/// SwiftUI-owned container that the shared `WKWebView` is re-parented into.
///
/// The representable hands SwiftUI one of these rather than the web view itself, so that tearing
/// down a subtree only discards the container.
#if os(macOS)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewHostView: NSView {

    var onMoveToWindow: (() -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if self.window != nil {
            self.onMoveToWindow?()
        }
    }

}
#else
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewHostView: UIView {

    var onMoveToWindow: (() -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.window != nil {
            self.onMoveToWindow?()
        }
    }

}
#endif

#endif
