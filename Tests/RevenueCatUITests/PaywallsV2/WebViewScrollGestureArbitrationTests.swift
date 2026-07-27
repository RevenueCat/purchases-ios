//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewScrollGestureArbitrationTests.swift
//
//  Created by Antonio Pallares.

@testable import RevenueCatUI
import XCTest

#if os(iOS)

import UIKit
import WebKit

@available(iOS 15.0, *)
final class WebViewScrollGestureArbitrationTests: TestCase {

    // Mirrors Android's `DragGestureArbitrationTest` touch-slop value.
    private let slop: CGFloat = 8

    // MARK: - Decision function (ported 1:1 from purchases-android DragGestureArbitrationTest)

    func testContentVerdictToOwnClaimsImmediatelyEvenWithinTouchSlop() {
        XCTAssertTrue(shouldOwn(dx: 0, dy: 1, webContentWantsGesture: true))
    }

    func testContentThatWantsGestureOwnsRegardlessOfNativeScrollability() {
        XCTAssertTrue(shouldOwn(dx: 0, dy: -50, webContentWantsGesture: true, canScrollDown: false))
    }

    func testReleaseVerdictStillYieldsToNativeRootScrollWhenThePageCanScroll() {
        XCTAssertTrue(shouldOwn(dx: 0, dy: -50, webContentWantsGesture: false, canScrollDown: true))
    }

    func testReleaseVerdictWithNothingToScrollHandsOffToThePaywall() {
        XCTAssertFalse(shouldOwn(dx: 0, dy: -50, webContentWantsGesture: false, canScrollDown: false))
    }

    func testNoVerdictYetNativeRootScrollOwnsWhileItCanScrollTheDraggedDirection() {
        XCTAssertTrue(shouldOwn(dx: 0, dy: -50, webContentWantsGesture: nil, canScrollDown: true))
    }

    func testNoVerdictYetHandsOffToThePaywallWhenTheRootCannotScroll() {
        XCTAssertFalse(shouldOwn(dx: 0, dy: -50, webContentWantsGesture: nil, canScrollDown: false))
    }

    func testMovementWithinTouchSlopDoesNotClaimWithoutAnOwnVerdict() {
        XCTAssertFalse(shouldOwn(dx: 7, dy: -7, canScrollUp: true))
    }

    func testDraggingUpAtTheBottomEdgeHandsOffToThePaywall() {
        XCTAssertFalse(shouldOwn(dx: 0, dy: -50, canScrollDown: false))
    }

    func testDraggingDownWhileTheRootCanScrollUpIsOwnedByTheWebView() {
        XCTAssertTrue(shouldOwn(dx: 0, dy: 50, canScrollUp: true))
    }

    func testHorizontalDominantDragUsesHorizontalScrollability() {
        XCTAssertTrue(shouldOwn(dx: -50, dy: 10, canScrollRight: true))
        XCTAssertFalse(shouldOwn(dx: -50, dy: 10, canScrollRight: false))
    }

    func testVerticalDominantDiagonalDragUsesVerticalScrollability() {
        XCTAssertTrue(shouldOwn(dx: 30, dy: -50, canScrollDown: true, canScrollLeft: true))
        XCTAssertFalse(shouldOwn(dx: 30, dy: -50, canScrollDown: false, canScrollLeft: true))
    }

    // MARK: - Outcome resolution (pending vs release while the probe verdict is in flight)

    func testOwnVerdictResolvesToOwnWithinTouchSlop() {
        XCTAssertEqual(resolve(dx: 0, dy: 1, webContentWantsGesture: true), .own)
    }

    func testPendingVerdictPastSlopWithNativeScrollResolvesToOwn() {
        XCTAssertEqual(resolve(dx: 0, dy: -50, webContentWantsGesture: nil, canScrollDown: true), .own)
    }

    func testPendingVerdictPastSlopWithoutNativeScrollStaysPending() {
        // The race the recognizer must not lose: a fast drag on JS-panned content (no native root
        // scroll) before the `own` verdict lands must wait, not release to the paywall.
        XCTAssertEqual(resolve(dx: 0, dy: -50, webContentWantsGesture: nil, canScrollDown: false), .pending)
    }

    func testReleaseVerdictPastSlopWithoutNativeScrollResolvesToRelease() {
        XCTAssertEqual(resolve(dx: 0, dy: -50, webContentWantsGesture: false, canScrollDown: false), .release)
    }

    func testWithinTouchSlopWithoutVerdictStaysPending() {
        XCTAssertEqual(resolve(dx: 7, dy: -7, webContentWantsGesture: nil), .pending)
    }

    func testReleaseVerdictWithinTouchSlopStaysPending() {
        XCTAssertEqual(resolve(dx: 3, dy: 3, webContentWantsGesture: false), .pending)
    }

    // MARK: - Recognizer failure-requirement wiring

    @MainActor
    func testAncestorPaywallScrollViewIsRequiredToFailByTheRecognizer() {
        let scrollView = UIScrollView()
        let webView = WKWebView()
        scrollView.addSubview(webView)
        let recognizer = WebViewScrollOwnershipRecognizer(webView: webView)

        XCTAssertTrue(
            recognizer.gestureRecognizer(recognizer, shouldBeRequiredToFailBy: scrollView.panGestureRecognizer)
        )
    }

    @MainActor
    func testWebViewsOwnScrollViewIsNotGated() {
        let webView = WKWebView()
        let recognizer = WebViewScrollOwnershipRecognizer(webView: webView)

        XCTAssertFalse(
            recognizer.gestureRecognizer(recognizer, shouldBeRequiredToFailBy: webView.scrollView.panGestureRecognizer)
        )
    }

    @MainActor
    func testScrollViewNotContainingTheWebViewIsNotGated() {
        let unrelatedScrollView = UIScrollView()
        let webView = WKWebView()
        let recognizer = WebViewScrollOwnershipRecognizer(webView: webView)

        XCTAssertFalse(
            recognizer.gestureRecognizer(recognizer, shouldBeRequiredToFailBy: unrelatedScrollView.panGestureRecognizer)
        )
    }

    @MainActor
    func testNonPanRecognizerOnAncestorScrollViewIsNotGated() {
        let scrollView = UIScrollView()
        let webView = WKWebView()
        scrollView.addSubview(webView)
        let tap = UITapGestureRecognizer()
        scrollView.addGestureRecognizer(tap)
        let recognizer = WebViewScrollOwnershipRecognizer(webView: webView)

        XCTAssertFalse(recognizer.gestureRecognizer(recognizer, shouldBeRequiredToFailBy: tap))
    }

    @MainActor
    func testPanRecognizerOnANonScrollViewIsNotGated() {
        let container = UIView()
        let webView = WKWebView()
        container.addSubview(webView)
        let pan = UIPanGestureRecognizer()
        container.addGestureRecognizer(pan)
        let recognizer = WebViewScrollOwnershipRecognizer(webView: webView)

        XCTAssertFalse(recognizer.gestureRecognizer(recognizer, shouldBeRequiredToFailBy: pan))
    }

    @MainActor
    func testRecognizesSimultaneouslyWithOtherRecognizers() {
        let scrollView = UIScrollView()
        let webView = WKWebView()
        scrollView.addSubview(webView)
        let recognizer = WebViewScrollOwnershipRecognizer(webView: webView)

        XCTAssertTrue(
            recognizer.gestureRecognizer(recognizer, shouldRecognizeSimultaneouslyWith: scrollView.panGestureRecognizer)
        )
    }

    // MARK: - Touch-sequence tracking (multi-touch + stale-verdict hardening)

    @MainActor
    func testBeginSequenceInitializesTrackingState() {
        let recognizer = WebViewScrollOwnershipRecognizer(webView: WKWebView())

        recognizer.beginSequence(at: CGPoint(x: 4, y: 9))

        XCTAssertTrue(recognizer.isTracking)
        XCTAssertEqual(recognizer.startLocation, CGPoint(x: 4, y: 9))
        XCTAssertFalse(recognizer.decided)
    }

    @MainActor
    func testSecondFingerDoesNotResetAnOngoingSequence() {
        let recognizer = WebViewScrollOwnershipRecognizer(webView: WKWebView())
        recognizer.beginSequence(at: CGPoint(x: 4, y: 9))
        recognizer.decided = true // pretend a verdict already committed

        recognizer.beginSequence(at: CGPoint(x: 40, y: 90)) // a second finger lands mid-gesture

        XCTAssertTrue(recognizer.decided, "A mid-gesture second finger must not clear the decision")
        XCTAssertEqual(
            recognizer.startLocation,
            CGPoint(x: 4, y: 9),
            "startLocation must stay anchored to the first finger"
        )
    }

    @MainActor
    func testProbeVerdictIsIgnoredWhenNoSequenceIsBeingTracked() {
        let recognizer = WebViewScrollOwnershipRecognizer(webView: WKWebView())

        recognizer.applyProbeVerdict(isOwn: true) // stale verdict arriving between gestures

        XCTAssertEqual(recognizer.state, .possible)
        XCTAssertFalse(recognizer.decided)
        XCTAssertNil(recognizer.contentWantsGesture)
    }

    @MainActor
    func testReleaseVerdictWhileTrackingRecordsWithoutClaiming() {
        let recognizer = WebViewScrollOwnershipRecognizer(webView: WKWebView())
        recognizer.beginSequence(at: .zero)

        recognizer.applyProbeVerdict(isOwn: false)

        XCTAssertEqual(recognizer.contentWantsGesture, false)
        XCTAssertFalse(recognizer.decided, "A release verdict defers to the movement/scroll check")
        XCTAssertEqual(recognizer.state, .possible)
    }

    @MainActor
    func testResetClearsTrackingSoLaterVerdictsAreIgnored() {
        let recognizer = WebViewScrollOwnershipRecognizer(webView: WKWebView())
        recognizer.beginSequence(at: .zero)

        recognizer.reset()
        recognizer.applyProbeVerdict(isOwn: true)

        XCTAssertFalse(recognizer.isTracking)
        XCTAssertFalse(recognizer.decided)
        XCTAssertNil(recognizer.contentWantsGesture)
    }

    @MainActor
    func testFastDragPastSlopDoesNotReleaseWhileTheVerdictIsPending() {
        // A default WKWebView has no scrollable content, so `canScroll` is false in every direction.
        let recognizer = WebViewScrollOwnershipRecognizer(webView: WKWebView())
        recognizer.beginSequence(at: .zero)
        recognizer.latestTranslation = CGSize(width: 0, height: -50) // fast flick up, well past slop

        recognizer.evaluate()

        XCTAssertFalse(recognizer.decided, "Must await the probe verdict instead of releasing early")
        XCTAssertNil(recognizer.committedDecision)
    }

    @MainActor
    func testOwnVerdictClaimsTheGesture() {
        let recognizer = WebViewScrollOwnershipRecognizer(webView: WKWebView())
        recognizer.beginSequence(at: .zero)

        recognizer.applyProbeVerdict(isOwn: true)

        XCTAssertTrue(recognizer.decided)
        XCTAssertEqual(recognizer.committedDecision, .own)
    }

    @MainActor
    func testReleaseVerdictAfterAFastDragHandsOffToThePaywall() {
        let recognizer = WebViewScrollOwnershipRecognizer(webView: WKWebView())
        recognizer.beginSequence(at: .zero)
        recognizer.latestTranslation = CGSize(width: 0, height: -50)

        recognizer.applyProbeVerdict(isOwn: false)

        XCTAssertTrue(recognizer.decided)
        XCTAssertEqual(recognizer.committedDecision, .release)
    }

    // MARK: - Probe user script

    @MainActor
    func testProbeUserScriptRunsAtDocumentStartOnTheMainFrameOnly() {
        let script = WebViewGestureProbe.userScript

        XCTAssertEqual(script.injectionTime, .atDocumentStart)
        XCTAssertTrue(script.isForMainFrameOnly)
    }

    @MainActor
    func testProbeUserScriptPostsVerdictsToTheDedicatedHandler() {
        let source = WebViewGestureProbe.userScript.source

        XCTAssertTrue(source.contains("messageHandlers.\(WebViewGestureProbe.messageHandlerName)"))
        XCTAssertTrue(source.contains("touchstart"))
        XCTAssertTrue(source.contains("'\(WebViewGestureProbe.verdictOwn)'"))
        XCTAssertTrue(source.contains("'\(WebViewGestureProbe.verdictRelease)'"))
    }

    @MainActor
    func testProbeUserScriptOnlyClaimsTouchActionNone() {
        let source = WebViewGestureProbe.userScript.source

        // Only `none` should claim: `pan-x`/`pan-y` still scroll natively and must defer to the
        // `canScroll*` checks, otherwise the paywall gets stuck at the web view's scroll edge.
        XCTAssertTrue(source.contains("s.touchAction === 'none'"))
        XCTAssertFalse(source.contains("!== 'manipulation'"))
    }

    @MainActor
    func testProbeUserScriptSkipsTheRootScrollerAndSecondaryTouches() {
        let source = WebViewGestureProbe.userScript.source

        // The root scroller is the web view's own scroll view (tracked by `canScroll*`), so the probe
        // must skip it and only claim inner scrollers.
        XCTAssertTrue(source.contains("document.scrollingElement"))
        XCTAssertTrue(source.contains("document.documentElement"))
        XCTAssertTrue(source.contains("document.body"))
        // Only the primary finger's verdict is posted so a second finger can't poison the decision.
        XCTAssertTrue(source.contains("event.touches.length > 1"))
    }

    // MARK: - Helpers

    // swiftlint:disable identifier_name
    private func shouldOwn(
        dx: CGFloat,
        dy: CGFloat,
        webContentWantsGesture: Bool? = nil,
        canScrollUp: Bool = false,
        canScrollDown: Bool = false,
        canScrollLeft: Bool = false,
        canScrollRight: Bool = false
    ) -> Bool {
        // swiftlint:enable identifier_name
        shouldWebViewOwnGesture(
            totalDx: dx,
            totalDy: dy,
            touchSlop: self.slop,
            webContentWantsGesture: webContentWantsGesture,
            // direction > 0 == toward the end (right/bottom), < 0 == toward the start (left/top).
            canScrollHorizontally: { direction in direction > 0 ? canScrollRight : canScrollLeft },
            canScrollVertically: { direction in direction > 0 ? canScrollDown : canScrollUp }
        )
    }

    // swiftlint:disable identifier_name
    private func resolve(
        dx: CGFloat,
        dy: CGFloat,
        webContentWantsGesture: Bool? = nil,
        canScrollUp: Bool = false,
        canScrollDown: Bool = false,
        canScrollLeft: Bool = false,
        canScrollRight: Bool = false
    ) -> WebViewGestureOutcome {
        // swiftlint:enable identifier_name
        webViewGestureOutcome(
            totalDx: dx,
            totalDy: dy,
            touchSlop: self.slop,
            webContentWantsGesture: webContentWantsGesture,
            canScrollHorizontally: { direction in direction > 0 ? canScrollRight : canScrollLeft },
            canScrollVertically: { direction in direction > 0 ? canScrollDown : canScrollUp }
        )
    }

}

#endif
