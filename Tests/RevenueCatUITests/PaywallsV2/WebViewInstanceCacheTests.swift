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

    private static func key(componentID: String, fitsWidth: Bool, fitsHeight: Bool) -> WebViewInstanceKey {
        return WebViewInstanceKey(
            componentID: componentID,
            url: URL(string: "https://example.com/index.html")!,
            fitsWidth: fitsWidth,
            fitsHeight: fitsHeight
        )
    }

}

#endif
