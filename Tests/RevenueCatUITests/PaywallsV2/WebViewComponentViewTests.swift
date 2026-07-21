//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewComponentViewTests.swift
//
//  Created by Antonio Pallares on 7/21/26.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest
// swiftlint:disable force_try

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewComponentViewTests: TestCase {

    // MARK: - Provisional fit sizing

    func testResolvedFitDimensionPrecedence() {
        XCTAssertEqual(
            WebViewSizing.resolvedDimension(measured: 420, defaultSize: 240, fallback: 300),
            420
        )
        XCTAssertEqual(
            WebViewSizing.resolvedDimension(measured: nil, defaultSize: 240, fallback: 300),
            240
        )
        XCTAssertEqual(
            WebViewSizing.resolvedDimension(measured: nil, defaultSize: nil, fallback: 300),
            300
        )
    }

    // MARK: - View model

    func testViewModelURLValidation() {
        let viewModel = WebViewComponentViewModel(
            component: .init(
                id: "web",
                protocolVersion: 2,
                url: "https://example.com/path",
                size: .init(width: .fill, height: .fit(nil))
            )
        )

        XCTAssertEqual(viewModel.url?.absoluteString, "https://example.com/path")
        XCTAssertEqual(viewModel.componentID, "web")

        for invalidURL in [
            "http://example.com",
            "file:///tmp/index.html",
            "custom://example.com",
            "https:///missing-host",
            "https://example.com/{{ custom.url }}"
        ] {
            let invalid = WebViewComponentViewModel(
                component: .init(id: "web", protocolVersion: 1, url: invalidURL)
            )
            XCTAssertNil(invalid.url)
        }
    }

    #if canImport(WebKit)
    func testViewModelResolvesOriginFromValidURL() {
        let viewModel = WebViewComponentViewModel(
            component: .init(id: "web", protocolVersion: 1, url: "https://example.com/path?q=1")
        )
        XCTAssertEqual(viewModel.origin?.value, "https://example.com")
    }

    func testViewModelHasNoOriginWhenURLIsInvalid() {
        let viewModel = WebViewComponentViewModel(
            component: .init(id: "web", protocolVersion: 1, url: "http://example.com")
        )
        XCTAssertNil(viewModel.url)
        XCTAssertNil(viewModel.origin)
    }
    #endif

    func testViewModelDefaultsToVisible() {
        XCTAssertTrue(
            WebViewComponentViewModel(component: .init(id: "web", protocolVersion: 1, url: "https://example.com"))
                .visible
        )
        XCTAssertFalse(
            WebViewComponentViewModel(
                component: .init(id: "web", visible: false, protocolVersion: 1, url: "https://example.com")
            ).visible
        )
    }

    func testViewModelEqualityAndHashingConsidersRenderedState() {
        func makeViewModel(
            id: String = "web",
            url: String = "https://example.com/path",
            visible: Bool? = nil,
            size: PaywallComponent.Size = .init(width: .fill, height: .fit(nil))
        ) -> WebViewComponentViewModel {
            WebViewComponentViewModel(
                component: .init(id: id, visible: visible, protocolVersion: 1, url: url, size: size)
            )
        }

        let base = makeViewModel()

        // Equal inputs produce equal (and identically hashing) view models.
        let same = makeViewModel()
        XCTAssertEqual(base, same)
        XCTAssertEqual(base.hashValue, same.hashValue)

        // Any rendered-state difference breaks equality.
        XCTAssertNotEqual(base, makeViewModel(id: "other"))
        XCTAssertNotEqual(base, makeViewModel(url: "https://example.com/other"))
        XCTAssertNotEqual(base, makeViewModel(visible: false))
        XCTAssertNotEqual(base, makeViewModel(size: .init(width: .fixed(320), height: .fit(nil))))
    }

}

#if canImport(WebKit) && !os(watchOS)
import WebKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewCoordinatorLifecycleTests: TestCase {

    func testDidCommitResetsConnectedSessionChannel() {
        let session = WebViewSession(
            componentID: "web",
            expectedOrigin: WebViewOrigin(string: "https://example.com")!,
            fitAxes: (width: false, height: false),
            evaluateJavaScript: { _ in },
            currentURL: { nil }
        )
        let data = try! JSONEncoder().encode(WebViewEnvelope.Envelope(kind: .connect, componentID: ""))
        session.handle(
            rawMessage: String(data: data, encoding: .utf8)!,
            isMainFrame: true,
            sourceOrigin: "https://example.com"
        )
        XCTAssertTrue(session.channelOpen)

        let coordinator = WebViewRepresentable.Coordinator(
            expectedOrigin: WebViewOrigin(string: "https://example.com")!
        )
        coordinator.session = session
        coordinator.webView(WKWebView(frame: .zero), didCommit: nil)

        XCTAssertFalse(session.channelOpen)
    }

    func testProcessTerminationInvokesCallbackOncePerCall() {
        let coordinator = WebViewRepresentable.Coordinator(
            expectedOrigin: WebViewOrigin(string: "https://example.com")!
        )
        var calls = 0
        coordinator.onProcessTerminated = { calls += 1 }

        let webView = WKWebView(frame: .zero)
        coordinator.webViewWebContentProcessDidTerminate(webView)
        coordinator.webViewWebContentProcessDidTerminate(webView)

        XCTAssertEqual(calls, 2)
    }

    // Note: the coordinator's `decidePolicyFor` is a thin delegation to
    // `WebViewNavigationPolicy.policy(for:isMainFrame:expectedOrigin:)`, which is exhaustively
    // covered (allow/cancel, origin normalization, nil URL) in WebViewNavigationPolicyTests.
    // `WKNavigationAction`/`WKFrameInfo` cannot be constructed or subclassed for a unit test, so the
    // delegation itself is not re-tested here.

}

#endif

#endif
