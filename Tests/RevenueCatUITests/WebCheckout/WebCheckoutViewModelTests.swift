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

    func testKeepsThePaintedPageOnScreenWhenALaterStepFailsToLoad() {
        let viewModel = Self.makeViewModel()

        viewModel.webView(viewModel.webView, didFinish: nil)
        viewModel.webView(viewModel.webView, didStartProvisionalNavigation: nil)
        viewModel.webView(viewModel.webView, didFailProvisionalNavigation: nil, withError: Self.failure)

        XCTAssertEqual(viewModel.loadState, .loaded)
    }

    // MARK: - Process termination

    func testReloadsThePageWhenItsProcessEnds() {
        let viewModel = Self.makeViewModel()

        viewModel.webView(viewModel.webView, didFinish: nil)
        viewModel.webViewWebContentProcessDidTerminate(viewModel.webView)

        XCTAssertEqual(viewModel.loadState, .loading)
    }

    func testFailsWhenTheProcessEndsAgainBeforeTheReloadPaints() {
        let viewModel = Self.makeViewModel()

        viewModel.webView(viewModel.webView, didFinish: nil)
        viewModel.webViewWebContentProcessDidTerminate(viewModel.webView)
        viewModel.webViewWebContentProcessDidTerminate(viewModel.webView)

        XCTAssertEqual(viewModel.loadState, .failed)
    }

    func testReloadsAgainWhenTheProcessEndsAfterTheReloadPainted() {
        let viewModel = Self.makeViewModel()

        viewModel.webView(viewModel.webView, didFinish: nil)
        viewModel.webViewWebContentProcessDidTerminate(viewModel.webView)
        viewModel.webView(viewModel.webView, didFinish: nil)
        viewModel.webViewWebContentProcessDidTerminate(viewModel.webView)

        XCTAssertEqual(viewModel.loadState, .loading)
    }

    // MARK: - Links to apps

    func testHandsALinkToAnAppToTheHost() throws {
        let viewModel = Self.makeViewModel()
        var openedURLs: [URL] = []
        viewModel.onOpenExternalURL = { openedURLs.append($0) }
        viewModel.webView(viewModel.webView, didFinish: nil)

        let policy = try Self.navigate(viewModel, to: "klarna://pay?session=1")

        XCTAssertEqual(policy, .cancel)
        XCTAssertEqual(openedURLs, [URL(string: "klarna://pay?session=1")!])
        XCTAssertEqual(viewModel.loadState, .loaded)
    }

    func testLoadsWebPagesInPlace() throws {
        let viewModel = Self.makeViewModel()
        var openedURLs: [URL] = []
        viewModel.onOpenExternalURL = { openedURLs.append($0) }

        for url in ["https://checkout.stripe.com/c/pay/session_1", "HTTPS://checkout.paddle.com", "about:blank",
                    "javascript:void(0)"] {
            XCTAssertEqual(try Self.navigate(viewModel, to: url), .allow, url)
        }
        XCTAssertEqual(openedURLs, [])
    }

    // MARK: - Returning

    func testCancelsTheReturnNavigationRatherThanLoadingIt() throws {
        let viewModel = Self.makeViewModel()

        let policy = try Self.navigate(viewModel, to: "\(Self.endpoint)?status=success")

        XCTAssertEqual(policy, .cancel)
        XCTAssertEqual(viewModel.loadState, .finished)
    }

    func testReportsTheReturnOnlyOnce() throws {
        let viewModel = Self.makeViewModel()
        var finished = 0
        viewModel.onFinished = { finished += 1 }

        _ = try Self.navigate(viewModel, to: "\(Self.endpoint)?status=success")
        _ = try Self.navigate(viewModel, to: "\(Self.endpoint)?status=maybe")

        XCTAssertEqual(finished, 1)
        XCTAssertEqual(viewModel.returnStatus, .success)
    }

    /// The checkout still ends, but as if the customer had closed it, for the backend to settle.
    func testFinishesWithoutAStatusWhenTheReturnCannotBeRead() throws {
        let viewModel = Self.makeViewModel()
        var finished = 0
        viewModel.onFinished = { finished += 1 }

        let policy = try Self.navigate(viewModel, to: "\(Self.endpoint)?status=cancel")

        XCTAssertEqual(policy, .cancel)
        XCTAssertEqual(finished, 1)
        XCTAssertEqual(viewModel.loadState, .finished)
        XCTAssertNil(viewModel.returnStatus)
    }

    /// Loading can begin before the sheet is presented, and with it the handler assigned.
    func testKeepsTheReturnedStatusWhenNothingWasListening() throws {
        let viewModel = Self.makeViewModel()

        _ = try Self.navigate(viewModel, to: "\(Self.endpoint)?status=success")

        XCTAssertEqual(viewModel.returnStatus, .success)
    }

    /// The status is there to be read, so a host that arrives late is not called about a return it
    /// missed: it would have nothing to do with a dismissal it never presented.
    func testTellsNothingToAHandlerAssignedAfterTheReturn() throws {
        let viewModel = Self.makeViewModel()
        var finished = 0

        _ = try Self.navigate(viewModel, to: "\(Self.endpoint)?status=success")
        viewModel.onFinished = { finished += 1 }

        XCTAssertEqual(finished, 0)
        XCTAssertEqual(viewModel.returnStatus, .success)
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
final class MainFrameNavigationAction: WKNavigationAction {

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
