//
//  WebViewInstance.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 30/7/26.
//

import Combine
import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) && !os(watchOS) && canImport(WebKit) // For Paywalls V2

import WebKit

/// The live web view behind a `web_view` component, owned by ``WebViewComponentViewModel``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewInstance: ObservableObject {

    let session: WebViewSession

    @Published private(set) var measuredWidth: CGFloat?
    @Published private(set) var measuredHeight: CGFloat?

    @Published private(set) var processTerminated = false
    @Published private(set) var loadFailed = false
    @Published private(set) var retiredByCacheClear = false

    var isUnusable: Bool {
        self.processTerminated || self.loadFailed || self.retiredByCacheClear
    }

    private var webView: PlatformWebView?
    private var navigationDelegateObject: AnyObject?
    private var cacheClearSubscription: AnyCancellable?

    private weak var attachedHost: WebViewHostView?

    /// A host that entered a window while the current host was still mounted. Remembering it lets the
    /// current host complete the handoff when it leaves instead of stranding the web view off-screen.
    private weak var pendingHost: WebViewHostView?

    /// `true` while playback is suspended because no host is showing the web view. Tracked so suspend
    /// and resume stay paired, as WebKit requires.
    private(set) var isMediaPlaybackSuspended = false

    init(
        componentID: String,
        expectedOrigin: WebViewOrigin,
        fitsWidth: Bool,
        fitsHeight: Bool,
        cacheClearEvents: AnyPublisher<WebBundleEvent, Never> = WebBundleEventBus.shared.publisher
    ) {
        // `evaluateJavaScript`/`currentURL` are rebound to the live web view in `webView(creatingWith:)`;
        // the no-op defaults only cover the window before it is created.
        self.session = WebViewSession(
            componentID: componentID,
            expectedOrigin: expectedOrigin,
            fitAxes: (width: fitsWidth, height: fitsHeight),
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

        self.cacheClearSubscription = cacheClearEvents
            .sink { [weak self] event in
                guard event == .cacheClearRequested else { return }
                Task { @MainActor in
                    self?.retireForIdentityChange()
                }
            }
    }

    func navigationDelegate<Delegate: AnyObject>(creating factory: () -> Delegate) -> Delegate {
        if let existing = self.navigationDelegateObject as? Delegate {
            return existing
        }

        let created = factory()
        self.navigationDelegateObject = created
        return created
    }

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

    func hostDidEnterWindow(_ host: WebViewHostView) {
        guard let webView = self.webView else {
            return
        }

        if let attachedHost = self.attachedHost,
           attachedHost !== host,
           attachedHost.window != nil,
           webView.superview === attachedHost {
            self.pendingHost = host
            return
        }

        self.pendingHost = nil
        self.attachWebView(to: host)
    }

    func hostDidLeaveWindow(_ host: WebViewHostView) {
        if self.pendingHost === host {
            self.pendingHost = nil
        }

        guard self.attachedHost === host else {
            return
        }

        self.attachedHost = nil

        if let pendingHost = self.pendingHost, pendingHost.window != nil {
            self.pendingHost = nil
            self.attachWebView(to: pendingHost)
            return
        }

        // Nothing is showing the web view any more — the component was hidden, or the paywall went
        // away. The web view survives on the view model, so without this an `autoplay` video would
        // keep playing audio from a component that is no longer on screen.
        self.setMediaPlaybackSuspended(true)
    }

    /// Reasserts attachment for a host SwiftUI updated after it was already in a window. Unlike
    /// ``hostDidEnterWindow(_:)``, updates from another mounted candidate do not compete for ownership.
    func updateHost(_ host: WebViewHostView) {
        guard self.attachedHost == nil || self.attachedHost === host else {
            return
        }

        self.attachWebView(to: host)
    }

    private func attachWebView(to host: WebViewHostView) {
        guard let webView = self.webView else {
            return
        }

        self.attachedHost = host
        self.setMediaPlaybackSuspended(false)

        guard webView.superview !== host else {
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

    /// Suspends rather than pauses: a paused page can restart itself by calling `play()`, whereas
    /// suspension blocks the page and the user until it is lifted.
    private func setMediaPlaybackSuspended(_ suspended: Bool) {
        guard suspended != self.isMediaPlaybackSuspended, let webView = self.webView else {
            return
        }

        self.isMediaPlaybackSuspended = suspended
        webView.setAllMediaPlaybackSuspended(suspended)
    }

    func tearDown() {
        self.cacheClearSubscription?.cancel()
        self.cacheClearSubscription = nil
        self.navigationDelegateObject = nil
        self.attachedHost = nil
        self.pendingHost = nil

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

    private func retireForIdentityChange() {
        self.retiredByCacheClear = true
        self.tearDown()
    }

}

/// SwiftUI-owned container that the shared `WKWebView` is re-parented into.
#if os(macOS)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewHostView: NSView {

    var onMoveToWindow: ((WebViewHostView) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.onMoveToWindow?(self)
    }

}
#else
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewHostView: UIView {

    var onMoveToWindow: ((WebViewHostView) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.onMoveToWindow?(self)
    }

}
#endif

#endif
