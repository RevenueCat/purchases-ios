//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebCheckoutViewModelTests.swift
//
//  Created by Antonio Pallares on 8/9/26.
//

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if os(iOS) && canImport(WebKit)

import WebKit

@available(iOS 15.0, *)
@MainActor
final class WebCheckoutViewModelTests: TestCase {

    private static let endpoint = "https://api.example.com/rcbilling/v1/hosted-checkout-return"

    private static let failure = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)

    // MARK: - Loading

    func testWaitsForTheHostBeforeLoadingAnything() {
        let viewModel = Self.makeViewModel()

        XCTAssertEqual(viewModel.loadState, .idle)
        XCTAssertTrue(viewModel.loadState.isWaitingForFirstPaint)
    }

    func testWaitsForTheFirstPaintOnceLoading() {
        let viewModel = Self.makeViewModel()

        viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.loadState, .loading)
        XCTAssertTrue(viewModel.loadState.isWaitingForFirstPaint)
    }

    func testStopsWaitingWhenThePageHasPainted() {
        let viewModel = Self.makeViewModel()

        viewModel.loadIfNeeded()
        viewModel.webView(viewModel.webView, didFinish: nil)

        XCTAssertEqual(viewModel.loadState, .loaded)
        XCTAssertFalse(viewModel.loadState.isWaitingForFirstPaint)
    }

    func testKeepsThePaintedPageOnScreenWhileTheProviderNavigates() {
        let viewModel = Self.makeViewModel()

        viewModel.webView(viewModel.webView, didFinish: nil)
        viewModel.webView(viewModel.webView, didStartProvisionalNavigation: nil)

        XCTAssertEqual(viewModel.loadState, .navigating)
        XCTAssertFalse(viewModel.loadState.isWaitingForFirstPaint)
    }

    // MARK: - Failures

    func testFailsWhenTheFirstLoadDoesNotArrive() {
        let viewModel = Self.makeViewModel()

        viewModel.loadIfNeeded()
        viewModel.webView(viewModel.webView, didFailProvisionalNavigation: nil, withError: Self.failure)

        XCTAssertEqual(viewModel.loadState, .failed)
    }

    func testWaitsAgainWhenAFailedPageStartsOver() {
        let viewModel = Self.makeViewModel()

        viewModel.webView(viewModel.webView, didFail: nil, withError: Self.failure)
        viewModel.webView(viewModel.webView, didStartProvisionalNavigation: nil)

        XCTAssertEqual(viewModel.loadState, .loading)
    }

    // MARK: - Returning

    func testCancelsTheReturnNavigationRatherThanLoadingIt() throws {
        let viewModel = Self.makeViewModel()

        let policy = try Self.navigate(viewModel, to: "\(Self.endpoint)?status=success")

        XCTAssertEqual(policy, .cancel)
        XCTAssertEqual(viewModel.loadState, .finished)
    }

    func testReportsTheReturnedStatusOnlyOnce() throws {
        let viewModel = Self.makeViewModel()
        var reported: [WebCheckoutReturnStatus] = []
        viewModel.onFinished = { reported.append($0) }

        _ = try Self.navigate(viewModel, to: "\(Self.endpoint)?status=success")
        _ = try Self.navigate(viewModel, to: "\(Self.endpoint)?status=cancel")

        XCTAssertEqual(reported, [.success])
    }

    func testIgnoresWhatArrivesAfterTheCheckoutReturned() throws {
        let viewModel = Self.makeViewModel()

        _ = try Self.navigate(viewModel, to: "\(Self.endpoint)?status=success")
        viewModel.webView(viewModel.webView, didFail: nil, withError: Self.failure)
        viewModel.webViewWebContentProcessDidTerminate(viewModel.webView)
        viewModel.webView(viewModel.webView, didStartProvisionalNavigation: nil)

        XCTAssertEqual(viewModel.loadState, .finished)
    }

}

@available(iOS 15.0, *)
private extension WebCheckoutViewModelTests {

    /// Loads `about:blank`, so that nothing here reaches the network.
    static func makeViewModel() -> WebCheckoutViewModel {
        return WebCheckoutViewModel(
            checkoutURL: URL(string: "about:blank")!,
            successURL: URL(string: "\(Self.endpoint)?status=success")!,
            cancelURL: URL(string: "\(Self.endpoint)?status=cancel")!,
            dataStoreIdentifierStore: WebViewDataStoreIdentifierStore(
                userDefaults: UserDefaults(suiteName: "com.revenuecat.tests.webCheckoutViewModel")!
            )
        )
    }

    static func navigate(
        _ viewModel: WebCheckoutViewModel,
        to url: String
    ) throws -> WKNavigationActionPolicy {
        var policy: WKNavigationActionPolicy?

        viewModel.webView(
            viewModel.webView,
            decidePolicyFor: MainFrameNavigationAction(url: URL(string: url)!),
            decisionHandler: { policy = $0 }
        )

        return try XCTUnwrap(policy)
    }

}

/// A navigation to `url` in the main frame, which `WebKit` offers no way to build.
private final class MainFrameNavigationAction: WKNavigationAction {

    private let url: URL

    init(url: URL) {
        self.url = url

        super.init()
    }

    override var request: URLRequest {
        return URLRequest(url: self.url)
    }

}

#endif
