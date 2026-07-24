//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  WebViewScrollGestureArbitration.swift
//
//  Created by Antonio Pallares.
//

// A web_view component embedded in a scrollable paywall competes for drag gestures with the paywall
// scroll — on whichever axis the paywall scrolls (vertical for a typical paywall, horizontal for a
// paged/carousel container). iOS resolves nested *native* scroll views on its own (the inner web
// scroll wins when it can scroll), but content that pans via JavaScript — an SVG map with
// `touch-action: none`, an inner `overflow: auto` list — is invisible to that arbitration, so a drag
// both pans the content *and* scrolls the paywall ("double scroll").

#if os(iOS) && canImport(WebKit)

import Foundation
@_spi(Internal) import RevenueCat
import UIKit.UIGestureRecognizerSubclass
import WebKit

// MARK: - Probe

@available(iOS 15.0, *)
enum WebViewGestureProbe {

    /// Message handler name the probe posts verdicts to. Distinct from the bridge's
    /// ``WebViewEnvelope/messageHandlerName`` so gesture traffic never touches the app channel.
    static let messageHandlerName = "rcPaywallGestureProbe"

    static let verdictOwn = "own"
    static let verdictRelease = "release"

    /// Runs at document start in the main frame. On every `touchstart` it walks from the touched
    /// element up its ancestors and posts `own` when one declares a non-default `touch-action`
    /// (JS panning) or is an overflowing `auto`/`scroll` scroller — the per-element signals the
    /// native scroll-offset checks can't see — otherwise `release`. Passive, so it never blocks
    /// the page's own handling.
    static var userScript: WKUserScript {
        let source = """
        (function () {
          function consumesGesture(el) {
            var ELEMENT_NODE = Node.ELEMENT_NODE;
            var node = el && el.nodeType === ELEMENT_NODE ? el : (el ? el.parentElement : null);
            for (var n = node; n && n.nodeType === ELEMENT_NODE; n = n.parentElement) {
              var s = getComputedStyle(n);
              if (s.touchAction && s.touchAction !== 'auto' && s.touchAction !== 'manipulation') return true;
              if ((s.overflowY === 'auto' || s.overflowY === 'scroll') && n.scrollHeight > n.clientHeight) return true;
              if ((s.overflowX === 'auto' || s.overflowX === 'scroll') && n.scrollWidth > n.clientWidth) return true;
            }
            return false;
          }
          function post(verdict) {
            try {
              window.webkit.messageHandlers.\(messageHandlerName).postMessage(verdict);
            } catch (e) {}
          }
          document.addEventListener('touchstart', function (event) {
            post(consumesGesture(event.target) ? '\(verdictOwn)' : '\(verdictRelease)');
          }, { passive: true, capture: true });
        })();
        """
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }

}

// MARK: - Decision

/// Whether the web view should claim the drag (else the paywall scroll keeps it). A content `own`
/// verdict — an inner scroller or `touch-action` map native can't see — wins immediately; otherwise
/// the web view's own scroll offsets in the dominant drag direction decide. `direction > 0` means
/// toward the end of the content (scrolling down / trailing), as used by the `canScroll*` closures below.
@available(iOS 15.0, *)
// swiftlint:disable:next function_parameter_count
func shouldWebViewOwnGesture(
    totalDx: CGFloat,
    totalDy: CGFloat,
    touchSlop: CGFloat,
    webContentWantsGesture: Bool?,
    canScrollHorizontally: (_ direction: Int) -> Bool,
    canScrollVertically: (_ direction: Int) -> Bool
) -> Bool {
    if webContentWantsGesture == true { return true }
    if abs(totalDx) < touchSlop && abs(totalDy) < touchSlop { return false }
    if abs(totalDy) >= abs(totalDx) {
        return canScrollVertically(totalDy < 0 ? 1 : -1)
    } else {
        return canScrollHorizontally(totalDx < 0 ? 1 : -1)
    }
}

// MARK: - Recognizer

/// Installed on the web view; makes any *ancestor* paywall scroll view wait for it to fail (via
/// ``gestureRecognizer(_:shouldBeRequiredToFailBy:)``). It recognizes — and so blocks that scroll —
/// only when the drag belongs to the web content, per ``shouldWebViewOwnGesture(...)`` fed by the
/// probe verdict and the web view's own scroll offsets. It never cancels touches, so the page still
/// receives them for panning, taps and links.
@available(iOS 15.0, *)
final class WebViewScrollOwnershipRecognizer: UIGestureRecognizer,
                                              UIGestureRecognizerDelegate,
                                              WKScriptMessageHandler {

    // Points a finger may drift before we commit to a verdict. Roughly UIKit's own pan slop.
    private static let touchSlop: CGFloat = 10

    private weak var webView: WKWebView?

    private var startLocation: CGPoint = .zero
    /// `nil` until the probe reports; `true` == content owns, `false` == release to the paywall.
    private var contentWantsGesture: Bool?
    /// Once we pick `.began` or `.failed` for a gesture we don't revisit it (UIKit can't un-fail).
    private var decided = false

    init(webView: WKWebView) {
        self.webView = webView
        super.init(target: nil, action: nil)
        self.delegate = self
        // Arbitrate only; let the web view keep every touch so JS panning, taps and links still work.
        self.cancelsTouchesInView = false
        self.delaysTouchesBegan = false
        self.delaysTouchesEnded = false
    }

    // MARK: Touch tracking

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        self.startLocation = touches.first?.location(in: self.view) ?? .zero
        self.contentWantsGesture = nil
        self.decided = false
        // Stay `.possible`: the ancestor scroll (required to fail by us) waits until we resolve.
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard !self.decided, let location = touches.first?.location(in: self.view) else { return }
        self.evaluate(
            totalDx: location.x - self.startLocation.x,
            totalDy: location.y - self.startLocation.y
        )
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        self.finish(with: self.state == .began || self.state == .changed ? .ended : .failed)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        self.finish(with: self.state == .began || self.state == .changed ? .cancelled : .failed)
    }

    override func reset() {
        super.reset()
        self.contentWantsGesture = nil
        self.decided = false
    }

    // MARK: Verdict

    /// Receives the probe verdict. May arrive a frame or two after `touchstart`; only useful while the
    /// gesture is unresolved. A late `own` after we've already failed is dropped (that gesture is lost
    /// to the paywall — the same async caveat as Android).
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.frameInfo.isMainFrame else { return }
        guard !self.decided else { return }
        let wantsGesture = (message.body as? String) == WebViewGestureProbe.verdictOwn
        self.contentWantsGesture = wantsGesture
        // An `own` verdict claims immediately, even within slop. `release` waits for movement so the
        // dominant-axis native-scroll check below can still decide.
        if wantsGesture {
            self.decided = true
            self.state = .began
        }
    }

    // MARK: Arbitration

    private func evaluate(totalDx: CGFloat, totalDy: CGFloat) {
        let owns = shouldWebViewOwnGesture(
            totalDx: totalDx,
            totalDy: totalDy,
            touchSlop: Self.touchSlop,
            webContentWantsGesture: self.contentWantsGesture,
            canScrollHorizontally: { [weak self] in self?.canScroll(horizontally: $0) ?? false },
            canScrollVertically: { [weak self] in self?.canScroll(vertically: $0) ?? false }
        )

        if owns {
            self.decided = true
            self.state = .began
        } else if abs(totalDx) >= Self.touchSlop || abs(totalDy) >= Self.touchSlop {
            // Past slop and not owned: hand the drag to the paywall.
            self.decided = true
            self.state = .failed
        }
        // Within slop and not owned yet: stay `.possible`, awaiting a verdict or more movement.
    }

    private func canScroll(vertically direction: Int) -> Bool {
        guard let scrollView = self.webView?.scrollView else { return false }
        if direction > 0 {
            return scrollView.contentOffset.y + scrollView.bounds.height < scrollView.contentSize.height - 0.5
        } else {
            return scrollView.contentOffset.y > 0.5
        }
    }

    private func canScroll(horizontally direction: Int) -> Bool {
        guard let scrollView = self.webView?.scrollView else { return false }
        if direction > 0 {
            return scrollView.contentOffset.x + scrollView.bounds.width < scrollView.contentSize.width - 0.5
        } else {
            return scrollView.contentOffset.x > 0.5
        }
    }

    private func finish(with endState: UIGestureRecognizer.State) {
        self.decided = true
        self.state = endState
    }

    // MARK: UIGestureRecognizerDelegate

    /// Make an ancestor paywall scroll view's pan wait for us: it only begins if we fail (release), so
    /// recognizing (own) blocks it. Scoped to scroll views that actually contain the web view, and not
    /// the web view's own scroll view.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard otherGestureRecognizer is UIPanGestureRecognizer,
              let scrollView = otherGestureRecognizer.view as? UIScrollView,
              let webView = self.webView,
              scrollView !== webView.scrollView,
              webView.isDescendant(of: scrollView) else {
            return false
        }
        return true
    }

    /// Coexist with the web view's own recognizers (its scroll view pan, taps); we only gate the
    /// ancestor paywall scroll, via the failure requirement above.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

}

#endif
