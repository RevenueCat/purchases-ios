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

/// The live web view behind a `web_view` component, owned by ``WebViewComponentViewModel``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewInstance: ObservableObject {

    let session: WebViewSession

    @Published private(set) var measuredWidth: CGFloat?
    @Published private(set) var measuredHeight: CGFloat?

    @Published private(set) var processTerminated = false
    @Published private(set) var loadFailed = false

    var isUnusable: Bool {
        self.processTerminated || self.loadFailed
    }

    private var webView: PlatformWebView?
    private var navigationDelegateObject: AnyObject?

    private weak var attachedHost: WebViewHostView?

    /// Hosts currently in a window, in entry order. Several is normal: a parent redraw can mount the new
    /// host before unmounting the old one, and a looping carousel mounts copies of each page.
    private var candidateHosts: [WeakHost] = []

    /// `true` while playback is suspended because no host is showing the web view. Tracked so suspend
    /// and resume stay paired, as WebKit requires.
    private(set) var isMediaPlaybackSuspended = false

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
        self.registerCandidate(host)
        self.reconcileAttachment()
    }

    func hostDidLeaveWindow(_ host: WebViewHostView) {
        self.candidateHosts.removeAll { $0.host === host }
        self.reconcileAttachment()
    }

    private func registerCandidate(_ host: WebViewHostView) {
        guard !self.candidateHosts.contains(where: { $0.host === host }) else {
            return
        }

        self.candidateHosts.append(WeakHost(host))
    }

    /// Moves the web view to the host that should be showing it, and suspends playback while it is off-screen.
    private func reconcileAttachment() {
        guard self.webView != nil else {
            return
        }

        self.candidateHosts.removeAll { $0.host?.window == nil }

        guard let preferredHost = self.preferredHost() else {
            // Nothing is showing the web view any more — the component was hidden, or the paywall went
            // away. The web view survives on the view model, so without this an `autoplay` video would
            // keep playing audio from a component that is no longer on screen.
            self.attachedHost = nil
            self.setMediaPlaybackSuspended(true)
            return
        }

        self.setMediaPlaybackSuspended(preferredHost.carouselDistance > 1)
        self.attachWebView(to: preferredHost)
    }

    /// The candidate closest to its carousel's active page. Ties go to the host already showing the web
    /// view, then to the host that entered the window first, so a replacement host mounted during a
    /// redraw only takes over once the current host leaves.
    private func preferredHost() -> WebViewHostView? {
        let candidates = self.candidateHosts.compactMap(\.host)
        guard let closestDistance = candidates.map(\.carouselDistance).min() else {
            return nil
        }

        if let attachedHost = self.attachedHost,
           attachedHost.carouselDistance == closestDistance,
           candidates.contains(where: { $0 === attachedHost }) {
            return attachedHost
        }

        return candidates.first { $0.carouselDistance == closestDistance }
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
        self.navigationDelegateObject = nil
        self.attachedHost = nil
        self.candidateHosts.removeAll()

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

    private struct WeakHost {

        weak var host: WebViewHostView?

        init(_ host: WebViewHostView) {
            self.host = host
        }

    }

}

/// SwiftUI-owned container that the shared `WKWebView` is re-parented into.
#if os(macOS)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewHostView: NSView {

    var onMoveToWindow: ((WebViewHostView) -> Void)?

    /// Distance from the active carousel page; `0` when active or not in a carousel. Closest host wins.
    var carouselDistance: Int = 0

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.onMoveToWindow?(self)
    }

}
#else
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewHostView: UIView {

    var onMoveToWindow: ((WebViewHostView) -> Void)?

    /// Distance from the active carousel page; `0` when active or not in a carousel. Closest host wins.
    var carouselDistance: Int = 0

    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.onMoveToWindow?(self)
    }

}
#endif

#endif
