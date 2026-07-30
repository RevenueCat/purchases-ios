//
//  WebViewInstance.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 30/7/26.
//

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) && !os(watchOS) && canImport(WebKit) // For Paywalls V2

import WebKit

/// The live web view behind a `web_view` component: the `WKWebView` itself, its bridge session, and
/// the sizing/failure state derived from them.
///
/// Owned by ``WebViewComponentViewModel``, which is already shared by every duplicate `ViewThatFits`
/// subtree for the component. This therefore outlives candidate changes without requiring a separate
/// process-wide cache or presentation identity.
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

    var isUnusable: Bool {
        self.processTerminated || self.loadFailed
    }

    private var webView: PlatformWebView?
    private var navigationDelegateObject: AnyObject?

    /// The host currently displaying the web view, if any. Weak so a discarded host doesn't keep its
    /// claim alive.
    private weak var attachedHost: WebViewHostView?

    /// A host that entered a window while the current host was still mounted. Remembering it lets the
    /// current host complete the handoff when it leaves instead of stranding the web view off-screen.
    private weak var pendingHost: WebViewHostView?

    init(
        componentID: String,
        expectedOrigin: WebViewOrigin,
        fitsWidth: Bool,
        fitsHeight: Bool
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
    ///
    /// If another host is still displaying the web view, remember this request until that host leaves
    /// its window. This avoids both repeated re-parenting during overlapping SwiftUI updates and a
    /// missed handoff when the incoming host enters before the outgoing host leaves.
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
        }
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

    /// Releases the web view and its message handlers before the view model replaces an unusable
    /// instance. Healthy instances otherwise live for the lifetime of their component view model.
    func tearDown() {
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

}

/// SwiftUI-owned container that the shared `WKWebView` is re-parented into.
///
/// The representable hands SwiftUI one of these rather than the web view itself, so that tearing
/// down a subtree only discards the container.
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
