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

    /// `ViewThatFits` duplicates view values, not the component view model. The shared view model is
    /// therefore the natural owner for the loaded document and bridge state.
    func testOneViewModelReturnsTheSameInstanceToDuplicateRenderings() {
        let viewModel = Self.makeViewModel()

        let first = viewModel.webViewInstance(expectedOrigin: Self.origin)
        let second = viewModel.webViewInstance(expectedOrigin: Self.origin)

        XCTAssertTrue(first === second)
    }

    /// Separate paywall constructions create separate view-model trees, so simultaneous presentations
    /// cannot re-parent the same web view between their windows.
    func testSeparateViewModelsOwnSeparateInstances() {
        let first = Self.makeViewModel().webViewInstance(expectedOrigin: Self.origin)
        let second = Self.makeViewModel().webViewInstance(expectedOrigin: Self.origin)

        XCTAssertFalse(first === second)
    }

    // MARK: - Measured state

    func testMeasuredSizeSurvivesAccessFromAnotherRendering() {
        let viewModel = Self.makeViewModel()
        let instance = viewModel.webViewInstance(expectedOrigin: Self.origin)
        instance.session.onContentResize?(nil, 438)

        let surviving = viewModel.webViewInstance(expectedOrigin: Self.origin)
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

    func testViewModelReplacesAnUnusableInstanceForALaterRendering() {
        let viewModel = Self.makeViewModel()
        let terminated = viewModel.webViewInstance(expectedOrigin: Self.origin)
        terminated.markProcessTerminated()

        let replacement = viewModel.webViewInstance(expectedOrigin: Self.origin)

        XCTAssertFalse(replacement === terminated)
        XCTAssertFalse(replacement.isUnusable)
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

    private static func makeViewModel() -> WebViewComponentViewModel {
        return WebViewComponentViewModel(
            component: .init(
                id: "faq",
                protocolVersion: 1,
                url: "https://example.com/index.html",
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
