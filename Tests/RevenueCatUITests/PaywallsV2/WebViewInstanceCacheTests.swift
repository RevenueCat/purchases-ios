//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewInstanceCacheTests.swift
//
//  Created by Antonio Pallares on 7/30/26.

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) && !os(watchOS) && canImport(WebKit)

import WebKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewInstanceCacheTests: TestCase {

    private var cache: WebViewInstanceCache!

    override func setUp() {
        super.setUp()
        self.cache = WebViewInstanceCache()
    }

    // MARK: - Identity

    func testSecondAcquireOfSameKeyReturnsSameInstance() {
        let key = Self.key(componentID: "faq", fitsWidth: false, fitsHeight: true)

        let first = self.cache.acquire(key: key, expectedOrigin: Self.origin)
        let second = self.cache.acquire(key: key, expectedOrigin: Self.origin)

        XCTAssertTrue(first === second)
    }

    func testDifferentComponentIDsGetDifferentInstances() {
        let faq = self.cache.acquire(
            key: Self.key(componentID: "faq", fitsWidth: false, fitsHeight: true),
            expectedOrigin: Self.origin
        )
        let hero = self.cache.acquire(
            key: Self.key(componentID: "hero", fitsWidth: false, fitsHeight: true),
            expectedOrigin: Self.origin
        )

        XCTAssertFalse(faq === hero)
    }

    /// Two simultaneous presentations of the same paywall (multi-window, or a paywall over a paywall)
    /// must not end up fighting over one web view.
    func testDifferentPresentationsGetDifferentInstances() {
        let first = self.cache.acquire(
            key: Self.key(presentationID: UUID(), componentID: "faq", fitsWidth: false, fitsHeight: true),
            expectedOrigin: Self.origin
        )
        let second = self.cache.acquire(
            key: Self.key(presentationID: UUID(), componentID: "faq", fitsWidth: false, fitsHeight: true),
            expectedOrigin: Self.origin
        )

        XCTAssertFalse(first === second)
    }

    func testMissingPresentationIDStillSharesWithinTheSameKey() {
        let key = Self.key(presentationID: nil, componentID: "faq", fitsWidth: false, fitsHeight: true)

        let first = self.cache.acquire(key: key, expectedOrigin: Self.origin)
        let second = self.cache.acquire(key: key, expectedOrigin: Self.origin)

        XCTAssertTrue(first === second)
    }

    /// A change to the fit axes changes the bridge handshake, so it must not reuse a loaded document.
    func testDifferentFitAxesGetDifferentInstances() {
        let fitsHeight = self.cache.acquire(
            key: Self.key(componentID: "faq", fitsWidth: false, fitsHeight: true),
            expectedOrigin: Self.origin
        )
        let fixed = self.cache.acquire(
            key: Self.key(componentID: "faq", fitsWidth: false, fitsHeight: false),
            expectedOrigin: Self.origin
        )

        XCTAssertFalse(fitsHeight === fixed)
    }

    // MARK: - Lease counting

    /// The invariant the flash fix rests on: a discarded `ViewThatFits` candidate releasing its lease
    /// must not tear down the web view that the surviving candidate is still showing.
    func testInstanceSurvivesReleaseWhileAnotherLeaseIsHeld() {
        let key = Self.key(componentID: "faq", fitsWidth: false, fitsHeight: true)

        let original = self.cache.acquire(key: key, expectedOrigin: Self.origin)
        _ = self.cache.acquire(key: key, expectedOrigin: Self.origin)
        self.cache.release(key: key)

        XCTAssertTrue(self.cache.acquire(key: key, expectedOrigin: Self.origin) === original)
    }

    func testInstanceIsDiscardedOnceLastLeaseIsReleased() {
        let key = Self.key(componentID: "faq", fitsWidth: false, fitsHeight: true)

        let original = self.cache.acquire(key: key, expectedOrigin: Self.origin)
        self.cache.release(key: key)

        XCTAssertFalse(self.cache.acquire(key: key, expectedOrigin: Self.origin) === original)
    }

    func testReleasingMoreOftenThanAcquiredDoesNotUnbalanceLaterLeases() {
        let key = Self.key(componentID: "faq", fitsWidth: false, fitsHeight: true)

        self.cache.release(key: key)

        let original = self.cache.acquire(key: key, expectedOrigin: Self.origin)
        _ = self.cache.acquire(key: key, expectedOrigin: Self.origin)
        self.cache.release(key: key)

        XCTAssertTrue(self.cache.acquire(key: key, expectedOrigin: Self.origin) === original)
    }

    // MARK: - Measured state

    /// Measured sizes live on the instance rather than the subtree, so a candidate swap no longer
    /// drops the component back to its `fit` default.
    func testMeasuredSizeSurvivesACandidateSwap() {
        let key = Self.key(componentID: "faq", fitsWidth: false, fitsHeight: true)

        let instance = self.cache.acquire(key: key, expectedOrigin: Self.origin)
        _ = self.cache.acquire(key: key, expectedOrigin: Self.origin)
        instance.session.onContentResize?(nil, 438)
        self.cache.release(key: key)

        let surviving = self.cache.acquire(key: key, expectedOrigin: Self.origin)
        XCTAssertEqual(surviving.measuredHeight, 438)
    }

    func testContentResizeOnlyOverwritesTheAxisItReports() {
        let instance = self.cache.acquire(
            key: Self.key(componentID: "faq", fitsWidth: true, fitsHeight: true),
            expectedOrigin: Self.origin
        )

        instance.session.onContentResize?(320, 438)
        instance.session.onContentResize?(nil, 512)

        XCTAssertEqual(instance.measuredWidth, 320)
        XCTAssertEqual(instance.measuredHeight, 512)
    }

    func testDocumentResetClearsMeasuredSizes() {
        let instance = self.cache.acquire(
            key: Self.key(componentID: "faq", fitsWidth: true, fitsHeight: true),
            expectedOrigin: Self.origin
        )
        instance.session.onContentResize?(320, 438)

        instance.session.onDocumentReset?()

        XCTAssertNil(instance.measuredWidth)
        XCTAssertNil(instance.measuredHeight)
    }

    // MARK: - Failure state

    func testFailureFlagsStartClearAndAreObservable() {
        let instance = self.cache.acquire(
            key: Self.key(componentID: "faq", fitsWidth: false, fitsHeight: true),
            expectedOrigin: Self.origin
        )
        XCTAssertFalse(instance.processTerminated)
        XCTAssertFalse(instance.loadFailed)

        instance.markProcessTerminated()
        instance.markLoadFailed()

        XCTAssertTrue(instance.processTerminated)
        XCTAssertTrue(instance.loadFailed)
    }

    // MARK: - Recovery from an unusable instance

    /// Before the cache existed, each subtree built its own web view, so a rebuild was a fresh attempt
    /// after a crash. Caching must not turn that into a permanent blank for the rest of the presentation.
    func testTerminatedInstanceIsReplacedOnTheNextAcquire() {
        let key = Self.key(componentID: "faq", fitsWidth: false, fitsHeight: true)

        let terminated = self.cache.acquire(key: key, expectedOrigin: Self.origin)
        terminated.markProcessTerminated()

        let replacement = self.cache.acquire(key: key, expectedOrigin: Self.origin)

        XCTAssertFalse(replacement === terminated)
        XCTAssertFalse(replacement.processTerminated)
    }

    func testFailedInstanceIsReplacedOnTheNextAcquire() {
        let key = Self.key(componentID: "faq", fitsWidth: false, fitsHeight: true)

        let failed = self.cache.acquire(key: key, expectedOrigin: Self.origin)
        failed.markLoadFailed()

        let replacement = self.cache.acquire(key: key, expectedOrigin: Self.origin)

        XCTAssertFalse(replacement === failed)
        XCTAssertFalse(replacement.loadFailed)
    }

    /// The counterpart to the two above: eviction must be limited to unusable instances, or every
    /// candidate swap would rebuild the web view and the original flash would be back.
    func testHealthyInstanceIsNotReplacedOnTheNextAcquire() {
        let key = Self.key(componentID: "faq", fitsWidth: false, fitsHeight: true)

        let original = self.cache.acquire(key: key, expectedOrigin: Self.origin)

        XCTAssertTrue(self.cache.acquire(key: key, expectedOrigin: Self.origin) === original)
    }

    func testEvictionStillLeavesLeaseCountingIntact() {
        let key = Self.key(componentID: "faq", fitsWidth: false, fitsHeight: true)

        let terminated = self.cache.acquire(key: key, expectedOrigin: Self.origin)
        terminated.markProcessTerminated()
        let replacement = self.cache.acquire(key: key, expectedOrigin: Self.origin)
        // The lease held by the subtree that saw the crash goes away.
        self.cache.release(key: key)

        XCTAssertTrue(self.cache.acquire(key: key, expectedOrigin: Self.origin) === replacement)
    }

    // MARK: - Shared sub-objects

    func testNavigationDelegateIsCreatedOnlyOnce() {
        let instance = self.cache.acquire(
            key: Self.key(componentID: "faq", fitsWidth: false, fitsHeight: true),
            expectedOrigin: Self.origin
        )
        var factoryCalls = 0
        let makeDelegate: () -> WebViewRepresentable.Coordinator = {
            factoryCalls += 1
            return WebViewRepresentable.Coordinator(expectedOrigin: Self.origin)
        }

        let first = instance.navigationDelegate(creating: makeDelegate)
        let second = instance.navigationDelegate(creating: makeDelegate)

        XCTAssertEqual(factoryCalls, 1)
        XCTAssertTrue(first === second)
    }

    // MARK: - Helpers

    private static let origin = WebViewOrigin(string: "https://example.com")!
    private static let presentation = UUID()

    private static func key(componentID: String, fitsWidth: Bool, fitsHeight: Bool) -> WebViewInstanceKey {
        return Self.key(
            presentationID: Self.presentation,
            componentID: componentID,
            fitsWidth: fitsWidth,
            fitsHeight: fitsHeight
        )
    }

    private static func key(
        presentationID: UUID?,
        componentID: String,
        fitsWidth: Bool,
        fitsHeight: Bool
    ) -> WebViewInstanceKey {
        return WebViewInstanceKey(
            presentationID: presentationID,
            componentID: componentID,
            url: URL(string: "https://example.com/index.html")!,
            fitsWidth: fitsWidth,
            fitsHeight: fitsHeight
        )
    }

}

/// Covers which host owns the shared web view. Two `ViewThatFits` candidates can be mounted at once, so
/// the rule matters: without it they could take turns re-parenting the web view on every update pass.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewInstanceHostAttachmentTests: TestCase {

    /// Nothing else retains a window, and a host's `window` goes nil the moment its window is released.
    private var windows: [AnyObject] = []

    override func tearDown() {
        self.windows.removeAll()
        super.tearDown()
    }

    func testWebViewAttachesToAHostInAWindow() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let host = self.makeWindowedHost()

        instance.attachWebView(to: host)

        XCTAssertTrue(webView.superview === host)
    }

    func testReattachingTheSameHostLeavesTheWebViewInPlace() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let host = self.makeWindowedHost()

        instance.attachWebView(to: host)
        instance.attachWebView(to: host)

        XCTAssertTrue(webView.superview === host)
        XCTAssertEqual(host.subviews.count, 1)
    }

    func testSecondHostCannotTakeTheWebViewWhileTheFirstIsStillInAWindow() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let displayed = self.makeWindowedHost()
        let other = self.makeWindowedHost()

        instance.attachWebView(to: displayed)
        instance.attachWebView(to: other)

        XCTAssertTrue(webView.superview === displayed)
    }

    /// The flip side: ownership has to be releasable, or a candidate swap would leave the web view behind
    /// in the host that just went away and the component would render empty.
    func testSecondHostTakesTheWebViewOnceTheFirstLeavesItsWindow() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let outgoing = self.makeWindowedHost()
        let incoming = self.makeWindowedHost()

        instance.attachWebView(to: outgoing)
        outgoing.removeFromSuperview()
        instance.attachWebView(to: incoming)

        XCTAssertTrue(webView.superview === incoming)
    }

    func testTearDownReleasesTheWebViewFromItsHost() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let host = self.makeWindowedHost()
        instance.attachWebView(to: host)

        instance.tearDown()

        XCTAssertNil(webView.superview)
    }

    // MARK: - Helpers

    private static func makeInstance() -> WebViewInstance {
        return WebViewInstance(
            key: WebViewInstanceKey(
                presentationID: UUID(),
                componentID: "faq",
                url: URL(string: "https://example.com/index.html")!,
                fitsWidth: false,
                fitsHeight: true
            ),
            expectedOrigin: WebViewOrigin(string: "https://example.com")!
        )
    }

    private func makeWindowedHost() -> WebViewHostView {
        let host = WebViewHostView()

        #if os(macOS)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 480),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView?.addSubview(host)
        #else
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.addSubview(host)
        #endif

        self.windows.append(window)
        return host
    }

}

#endif
