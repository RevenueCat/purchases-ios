//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewInstanceTests.swift
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
final class WebViewInstanceTests: TestCase {

    func testOneViewModelReturnsTheSameInstanceToDuplicateRenderings() {
        let viewModel = Self.makeViewModel()

        let first = viewModel.webViewInstance()
        let second = viewModel.webViewInstance()

        XCTAssertNotNil(first)
        XCTAssertTrue(first === second)
    }

    func testSeparateViewModelsOwnSeparateInstances() {
        let first = Self.makeViewModel().webViewInstance()
        let second = Self.makeViewModel().webViewInstance()

        XCTAssertNotNil(first)
        XCTAssertFalse(first === second)
    }

    /// The origin gates every bridge message, so a component whose URL can't resolve one must not get
    /// a web view at all.
    func testNoInstanceIsCreatedWithoutAResolvableOrigin() {
        XCTAssertNil(Self.makeViewModel(url: "not-a-url").webViewInstance())
    }

    // MARK: - Measured state

    func testMeasuredSizeSurvivesAccessFromAnotherRendering() throws {
        let viewModel = Self.makeViewModel()
        let instance = try XCTUnwrap(viewModel.webViewInstance())
        instance.session.onContentResize?(nil, 438)

        let surviving = try XCTUnwrap(viewModel.webViewInstance())
        XCTAssertEqual(surviving.measuredHeight, 438)
    }

    func testContentResizeOnlyOverwritesTheAxisItReports() {
        let instance = Self.makeInstance(fitsWidth: true, fitsHeight: true)

        instance.session.onContentResize?(320, 438)
        instance.session.onContentResize?(nil, 512)

        XCTAssertEqual(instance.measuredWidth, 320)
        XCTAssertEqual(instance.measuredHeight, 512)
    }

    func testDocumentResetClearsMeasuredSizes() {
        let instance = Self.makeInstance(fitsWidth: true, fitsHeight: true)
        instance.session.onContentResize?(320, 438)

        instance.session.onDocumentReset?()

        XCTAssertNil(instance.measuredWidth)
        XCTAssertNil(instance.measuredHeight)
    }

    // MARK: - Failure state

    func testFailureFlagsStartClearAndAreObservable() {
        let instance = Self.makeInstance()
        XCTAssertFalse(instance.processTerminated)
        XCTAssertFalse(instance.loadFailed)

        instance.markProcessTerminated()
        instance.markLoadFailed()

        XCTAssertTrue(instance.processTerminated)
        XCTAssertTrue(instance.loadFailed)
    }

    func testViewModelReplacesAnUnusableInstanceForALaterRendering() throws {
        let viewModel = Self.makeViewModel()
        let terminated = try XCTUnwrap(viewModel.webViewInstance())
        terminated.markProcessTerminated()

        let replacement = try XCTUnwrap(viewModel.webViewInstance())

        XCTAssertFalse(replacement === terminated)
        XCTAssertFalse(replacement.isUnusable)
    }

    // MARK: - Ownership

    /// The view model is the only owner, and the navigation delegate is stored *on* the instance, so a
    /// strong capture in `makeCoordinator` would keep the instance and its web view alive for the
    /// lifetime of the process.
    func testDroppingTheViewModelReleasesTheInstanceAndItsWebView() throws {
        weak var instance: WebViewInstance?
        weak var webView: WKWebView?
        let uuid = UUID().uuidString
        let defaults = UserDefaults(suiteName: uuid).unsafelyUnwrapped
        let store = WebViewDataStoreIdentifierStore(userDefaults: defaults)

        addTeardownBlock {
            defaults.removePersistentDomain(forName: uuid)
        }
        try autoreleasepool {
            let viewModel = Self.makeViewModel()
            let owned = try XCTUnwrap(viewModel.webViewInstance())
            let ownedWebView = owned.webView { WKWebView(frame: .zero) }
            // Built through the real representable so the coordinator's captures are the shipping ones.
            _ = WebViewRepresentable(url: Self.url, instance: owned, idStore: store).makeCoordinator()

            instance = owned
            webView = ownedWebView
        }

        XCTAssertNil(instance)

        // WebKit defers the web view's own dealloc past the end of the pool by a runloop turn.
        let deadline = Date().addingTimeInterval(2)
        while webView != nil, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        XCTAssertNil(webView)
    }

    // MARK: - Shared sub-objects

    func testNavigationDelegateIsCreatedOnlyOnce() {
        let instance = Self.makeInstance()
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
    private static let url = URL(string: "https://example.com/index.html")!

    private static func makeViewModel(url: String = "https://example.com/index.html") -> WebViewComponentViewModel {
        return WebViewComponentViewModel(
            component: .init(
                id: "faq",
                protocolVersion: 1,
                url: url,
                size: .init(width: .fill, height: .fit(nil))
            ),
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make())
        )
    }

    private static func makeInstance(
        fitsWidth: Bool = false,
        fitsHeight: Bool = true
    ) -> WebViewInstance {
        return WebViewInstance(
            componentID: "faq",
            expectedOrigin: Self.origin,
            fitsWidth: fitsWidth,
            fitsHeight: fitsHeight
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewInstanceHostAttachmentTests: TestCase {

    private var windows: [AnyObject] = []

    override func tearDown() {
        self.windows.removeAll()
        super.tearDown()
    }

    func testWebViewAttachesToAHostInAWindow() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let host = self.makeWindowedHost()

        instance.hostDidEnterWindow(host)

        XCTAssertTrue(webView.superview === host)
    }

    func testReattachingTheSameHostLeavesTheWebViewInPlace() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let host = self.makeWindowedHost()

        instance.hostDidEnterWindow(host)
        instance.updateHost(host)

        XCTAssertTrue(webView.superview === host)
        XCTAssertEqual(host.subviews.count, 1)
    }

    func testSecondHostCannotTakeTheWebViewWhileTheFirstIsStillInAWindow() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let displayed = self.makeWindowedHost()
        let other = self.makeWindowedHost()

        instance.hostDidEnterWindow(displayed)
        instance.hostDidEnterWindow(other)

        XCTAssertTrue(webView.superview === displayed)
    }

    /// SwiftUI may mount the incoming representable before unmounting the outgoing one. The incoming
    /// request must complete when the outgoing host leaves without requiring another update callback.
    func testPendingHostTakesTheWebViewWhenTheCurrentHostLeavesItsWindow() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let outgoing = self.makeWindowedHost()
        let incoming = self.makeWindowedHost()

        instance.hostDidEnterWindow(outgoing)
        instance.hostDidEnterWindow(incoming)
        XCTAssertTrue(webView.superview === outgoing)

        outgoing.removeFromSuperview()
        instance.hostDidLeaveWindow(outgoing)

        XCTAssertTrue(webView.superview === incoming)
    }

    func testPendingHostIsForgottenIfItLeavesBeforeTheCurrentHost() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let displayed = self.makeWindowedHost()
        let pending = self.makeWindowedHost()

        instance.hostDidEnterWindow(displayed)
        instance.hostDidEnterWindow(pending)
        pending.removeFromSuperview()
        instance.hostDidLeaveWindow(pending)
        displayed.removeFromSuperview()
        instance.hostDidLeaveWindow(displayed)

        XCTAssertTrue(webView.superview === displayed)
    }

    // MARK: - Carousel copies

    /// In a looping carousel the off-screen copy at the start of the strip enters the window first; the
    /// copy the user is looking at must win regardless.
    func testActiveCarouselPageTakesTheWebViewFromAnEarlierOffscreenCopy() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let offscreenCopy = self.makeWindowedHost(carouselDistance: 3)
        let activeCopy = self.makeWindowedHost(carouselDistance: 0)

        instance.hostDidEnterWindow(offscreenCopy)
        XCTAssertTrue(webView.superview === offscreenCopy)

        instance.hostDidEnterWindow(activeCopy)

        XCTAssertTrue(webView.superview === activeCopy)
    }

    func testFartherCarouselCopyCannotTakeTheWebViewFromTheActivePage() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let activeCopy = self.makeWindowedHost(carouselDistance: 0)
        let neighborCopy = self.makeWindowedHost(carouselDistance: 1)

        instance.hostDidEnterWindow(activeCopy)
        instance.hostDidEnterWindow(neighborCopy)
        instance.updateHost(neighborCopy)

        XCTAssertTrue(webView.superview === activeCopy)
    }

    /// Swiping changes every copy's distance without any host leaving the window.
    func testWebViewFollowsTheActivePageWhenTheCarouselMoves() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let firstCopy = self.makeWindowedHost(carouselDistance: 0)
        let secondCopy = self.makeWindowedHost(carouselDistance: 2)

        instance.hostDidEnterWindow(firstCopy)
        instance.hostDidEnterWindow(secondCopy)
        XCTAssertTrue(webView.superview === firstCopy)

        firstCopy.carouselDistance = 2
        instance.updateHost(firstCopy)

        secondCopy.carouselDistance = 0
        instance.updateHost(secondCopy)

        XCTAssertTrue(webView.superview === secondCopy)
        XCTAssertFalse(instance.isMediaPlaybackSuspended)
    }

    /// A 2-page loop peeks both neighbours at equal distance; the holder must not bounce between them.
    func testEquallyDistantCopiesDoNotStealTheWebViewFromEachOther() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let leftNeighbor = self.makeWindowedHost(carouselDistance: 1)
        let rightNeighbor = self.makeWindowedHost(carouselDistance: 1)

        instance.hostDidEnterWindow(leftNeighbor)
        instance.hostDidEnterWindow(rightNeighbor)
        instance.updateHost(rightNeighbor)
        instance.updateHost(leftNeighbor)

        XCTAssertTrue(webView.superview === leftNeighbor)
    }

    func testWebViewFallsBackToTheClosestRemainingCopyWhenTheActiveOneLeaves() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let farCopy = self.makeWindowedHost(carouselDistance: 3)
        let activeCopy = self.makeWindowedHost(carouselDistance: 0)
        let nearCopy = self.makeWindowedHost(carouselDistance: 1)

        instance.hostDidEnterWindow(farCopy)
        instance.hostDidEnterWindow(activeCopy)
        instance.hostDidEnterWindow(nearCopy)

        activeCopy.removeFromSuperview()
        instance.hostDidLeaveWindow(activeCopy)

        XCTAssertTrue(webView.superview === nearCopy)
    }

    // MARK: - Media playback

    /// The web view outlives the subtree now, so a hidden component would otherwise keep playing.
    func testMediaIsSuspendedOnceNoHostIsShowingTheWebView() {
        let instance = Self.makeInstance()
        _ = instance.webView { WKWebView(frame: .zero) }
        let host = self.makeWindowedHost()

        instance.hostDidEnterWindow(host)
        XCTAssertFalse(instance.isMediaPlaybackSuspended)

        host.removeFromSuperview()
        instance.hostDidLeaveWindow(host)

        XCTAssertTrue(instance.isMediaPlaybackSuspended)
    }

    func testMediaIsSuspendedUntilCarouselPageIsActiveOrNeighboring() {
        let instance = Self.makeInstance()
        _ = instance.webView { WKWebView(frame: .zero) }
        let host = self.makeWindowedHost(carouselDistance: 2)

        instance.hostDidEnterWindow(host)
        XCTAssertTrue(instance.isMediaPlaybackSuspended)

        host.carouselDistance = 1
        instance.updateHost(host)

        XCTAssertFalse(instance.isMediaPlaybackSuspended)
    }

    func testMediaResumesWhenTheComponentIsShownAgain() {
        let instance = Self.makeInstance()
        _ = instance.webView { WKWebView(frame: .zero) }
        let host = self.makeWindowedHost()

        instance.hostDidEnterWindow(host)
        host.removeFromSuperview()
        instance.hostDidLeaveWindow(host)

        instance.hostDidEnterWindow(self.makeWindowedHost())

        XCTAssertFalse(instance.isMediaPlaybackSuspended)
    }

    /// A redraw hands the web view straight over to the new host, so playback must not be interrupted.
    func testHandoffBetweenCandidatesDoesNotSuspendMedia() {
        let instance = Self.makeInstance()
        _ = instance.webView { WKWebView(frame: .zero) }
        let outgoing = self.makeWindowedHost()
        let incoming = self.makeWindowedHost()

        instance.hostDidEnterWindow(outgoing)
        instance.hostDidEnterWindow(incoming)
        outgoing.removeFromSuperview()
        instance.hostDidLeaveWindow(outgoing)

        XCTAssertFalse(instance.isMediaPlaybackSuspended)
    }

    func testTearDownReleasesTheWebViewFromItsHost() {
        let instance = Self.makeInstance()
        let webView = instance.webView { WKWebView(frame: .zero) }
        let host = self.makeWindowedHost()
        instance.hostDidEnterWindow(host)

        instance.tearDown()

        XCTAssertNil(webView.superview)
    }

    // MARK: - Helpers

    private static func makeInstance() -> WebViewInstance {
        return WebViewInstance(
            componentID: "faq",
            expectedOrigin: WebViewOrigin(string: "https://example.com")!,
            fitsWidth: false,
            fitsHeight: true
        )
    }

    private func makeWindowedHost(carouselDistance: Int = 0) -> WebViewHostView {
        let host = WebViewHostView()
        host.carouselDistance = carouselDistance

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
