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

    /// Runs at document start in the main frame. On the first finger of a `touchstart` it walks from the
    /// touched element up its ancestors and posts `own` when one declares `touch-action: none` (JS
    /// panning, e.g. a map) or is an *inner* overflowing `auto`/`scroll` scroller — the per-element
    /// signals the native scroll-offset checks can't see — otherwise `release`. The root scroller is
    /// left to those native checks. Passive, so it never blocks the page's own handling.
    static var userScript: WKUserScript {
        let source = """
        (function () {
          function isRootScroller(n) {
            return n === document.scrollingElement || n === document.documentElement || n === document.body;
          }
          function consumesGesture(el) {
            var ELEMENT_NODE = Node.ELEMENT_NODE;
            var node = el && el.nodeType === ELEMENT_NODE ? el : (el ? el.parentElement : null);
            for (var n = node; n && n.nodeType === ELEMENT_NODE; n = n.parentElement) {
              var s = getComputedStyle(n);
              // Only `none` means the browser won't pan this element at all (JS owns every axis, e.g. a
              // map). `pan-x`/`pan-y` still let the browser scroll natively on an axis — visible to the
              // `canScroll*` checks — so claiming them would wrongly block the paywall at the scroll edge.
              if (s.touchAction === 'none') return true;
              // Skip the root scroller: it *is* the web view's scroll view, which the native `canScroll*`
              // checks already track and hand off to the paywall at the edges. Only inner scrollers are
              // invisible to them, so claiming the root here would trap the paywall at the content edge.
              if (isRootScroller(n)) continue;
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
            // Only the first finger of a sequence: the recognizer tracks the primary touch, so a second
            // finger's verdict must not overwrite the primary's while the gesture is still undecided.
            if (event.touches.length > 1) return;
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

/// The recognizer's resolution for the current movement.
enum WebViewGestureOutcome: Equatable {
    /// The web view claims the drag (block the paywall scroll).
    case own
    /// Hand the drag to the paywall scroll.
    case release
    /// Not enough information yet — keep waiting for more movement or the probe verdict.
    case pending
}

/// Resolves the current movement into an outcome. `own` follows ``shouldWebViewOwnGesture``. Otherwise
/// we only `release` once the probe verdict has arrived (`webContentWantsGesture != nil`): while it is
/// still `nil` a fast drag past slop stays `pending` rather than releasing, so a late `own` verdict on
/// JS-panned content (which has no native root scroll to reveal it) isn't preempted by an early hand-off.
@available(iOS 15.0, *)
// swiftlint:disable:next function_parameter_count
func webViewGestureOutcome(
    totalDx: CGFloat,
    totalDy: CGFloat,
    touchSlop: CGFloat,
    webContentWantsGesture: Bool?,
    canScrollHorizontally: (_ direction: Int) -> Bool,
    canScrollVertically: (_ direction: Int) -> Bool
) -> WebViewGestureOutcome {
    let owns = shouldWebViewOwnGesture(
        totalDx: totalDx,
        totalDy: totalDy,
        touchSlop: touchSlop,
        webContentWantsGesture: webContentWantsGesture,
        canScrollHorizontally: canScrollHorizontally,
        canScrollVertically: canScrollVertically
    )
    if owns { return .own }

    let pastSlop = abs(totalDx) >= touchSlop || abs(totalDy) >= touchSlop
    // A definitive `release` verdict (or a `nil` verdict that native scrollability already resolved)
    // lets us hand off; a still-pending verdict must wait so JS-panned content can claim it.
    if pastSlop && webContentWantsGesture != nil { return .release }
    return .pending
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

    var startLocation: CGPoint = .zero
    /// `nil` until the probe reports; `true` == content owns, `false` == release to the paywall.
    var contentWantsGesture: Bool?
    /// Once we pick `.began` or `.failed` for a gesture we don't revisit it (UIKit can't un-fail).
    var decided = false
    /// `true` while a single touch sequence is being arbitrated: set on the first finger down and
    /// cleared once the gesture resolves or resets. Guards a second finger from re-initializing state
    /// mid-gesture, and a late/stale probe verdict from applying between gestures.
    var isTracking = false
    /// The latest drag translation of the current sequence, kept so a probe verdict arriving after the
    /// finger has already moved can be re-evaluated against where it is now.
    var latestTranslation: CGSize = .zero
    /// The finger that started the sequence. Arbitration follows only this touch, so a secondary finger
    /// moving, lifting, or being cancelled can't corrupt the deltas or end the gesture early. Weak: a
    /// `UITouch` is owned by UIKit and reused, so it must never be retained past its sequence.
    private weak var trackedTouch: UITouch?
    /// The arbitration commit for the current sequence (`own` -> `.began`, `release` -> `.failed`), `nil`
    /// while undecided. Mirrors the intent behind `state`, which UIKit only honors on a recognizer inside
    /// a live touch cycle — so `state` is unreliable to observe outside one (notably in tests).
    private(set) var committedDecision: WebViewGestureOutcome?

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
        // Only the first finger starts a sequence; a second finger landing mid-gesture is ignored.
        guard !self.isTracking, let touch = touches.first else { return }
        self.trackedTouch = touch
        self.beginSequence(at: touch.location(in: self.view))
        // Stay `.possible`: the ancestor scroll (required to fail by us) waits until we resolve.
    }

    /// Initialize arbitration state for a new touch sequence. Only the first finger takes effect: a
    /// second finger landing mid-gesture must not reset `decided` (which could force an illegal
    /// `.began` -> `.failed` transition) nor re-anchor `startLocation` (which corrupts the drag deltas).
    func beginSequence(at location: CGPoint) {
        guard !self.isTracking else { return }
        self.isTracking = true
        self.startLocation = location
        self.latestTranslation = .zero
        self.contentWantsGesture = nil
        self.decided = false
        self.committedDecision = nil
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        // Follow only the tracked finger, measured from its own start, so a second finger can't skew
        // the deltas.
        guard !self.decided, let touch = self.trackedTouch, touches.contains(touch) else { return }
        let location = touch.location(in: self.view)
        self.latestTranslation = CGSize(
            width: location.x - self.startLocation.x,
            height: location.y - self.startLocation.y
        )
        self.evaluate()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        // Resolve only when the tracked finger lifts; a secondary finger lifting must not end the drag.
        guard let touch = self.trackedTouch, touches.contains(touch) else { return }
        self.finish(with: self.state == .began || self.state == .changed ? .ended : .failed)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        guard let touch = self.trackedTouch, touches.contains(touch) else { return }
        self.finish(with: self.state == .began || self.state == .changed ? .cancelled : .failed)
    }

    override func reset() {
        super.reset()
        self.isTracking = false
        self.trackedTouch = nil
        self.contentWantsGesture = nil
        self.decided = false
        self.committedDecision = nil
    }

    // MARK: Verdict

    /// Receives the probe verdict. May arrive a frame or two after `touchstart`, so `applyProbeVerdict`
    /// decides whether it's still relevant to the live gesture.
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.frameInfo.isMainFrame else { return }
        self.applyProbeVerdict(isOwn: (message.body as? String) == WebViewGestureProbe.verdictOwn)
    }

    /// Apply a probe verdict to the live gesture. Ignored unless a sequence is actively being
    /// arbitrated and still undecided, so a verdict that arrives after the gesture ended (or was
    /// handed to the paywall) can't retroactively claim it or leak into the next gesture.
    func applyProbeVerdict(isOwn: Bool) {
        guard self.isTracking, !self.decided else { return }
        self.contentWantsGesture = isOwn
        // An `own` verdict claims immediately, even within slop. A `release` verdict resolves the
        // pending state, so re-evaluate against the latest movement to hand off promptly if the finger
        // has already dragged past slop (a fast drag may have moved before the verdict landed).
        if isOwn {
            self.claimGesture()
        } else {
            self.evaluate()
        }
    }

    // MARK: Arbitration

    func evaluate() {
        switch webViewGestureOutcome(
            totalDx: self.latestTranslation.width,
            totalDy: self.latestTranslation.height,
            touchSlop: Self.touchSlop,
            webContentWantsGesture: self.contentWantsGesture,
            canScrollHorizontally: { [weak self] in self?.canScroll(horizontally: $0) ?? false },
            canScrollVertically: { [weak self] in self?.canScroll(vertically: $0) ?? false }
        ) {
        case .own:
            self.claimGesture()
        case .release:
            self.releaseGesture()
        case .pending:
            // Within slop, or past slop while the probe verdict is still pending: stay `.possible`,
            // awaiting the verdict or more movement rather than releasing prematurely.
            break
        }
    }

    /// The web view claims the drag: recognize (`.began`) so the required-to-fail ancestor scroll is
    /// blocked for this sequence.
    private func claimGesture() {
        self.decided = true
        self.committedDecision = .own
        self.state = .began
    }

    /// Hand the drag to the paywall: fail so the ancestor scroll, which was required to fail by us, is
    /// free to begin.
    private func releaseGesture() {
        self.decided = true
        self.committedDecision = .release
        self.state = .failed
    }

    private func canScroll(vertically direction: Int) -> Bool {
        guard let scrollView = self.webView?.scrollView else { return false }
        // `adjustedContentInset` widens the offset range (safe area, keyboard, WebKit adjustments): the
        // resting top offset is `-inset.top` and the max bottom offset gains `inset.bottom`.
        let inset = scrollView.adjustedContentInset
        if direction > 0 {
            let maxOffsetY = scrollView.contentSize.height + inset.bottom - scrollView.bounds.height
            return scrollView.contentOffset.y < maxOffsetY - 0.5
        } else {
            return scrollView.contentOffset.y > -inset.top + 0.5
        }
    }

    private func canScroll(horizontally direction: Int) -> Bool {
        guard let scrollView = self.webView?.scrollView else { return false }
        let inset = scrollView.adjustedContentInset
        if direction > 0 {
            let maxOffsetX = scrollView.contentSize.width + inset.right - scrollView.bounds.width
            return scrollView.contentOffset.x < maxOffsetX - 0.5
        } else {
            return scrollView.contentOffset.x > -inset.left + 0.5
        }
    }

    private func finish(with endState: UIGestureRecognizer.State) {
        self.isTracking = false
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
