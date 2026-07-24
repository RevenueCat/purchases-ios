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

}

#endif
