//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  WebViewHTTPStatusTests.swift
//

@testable import RevenueCatUI
import XCTest

final class WebViewHTTPStatusTests: TestCase {

    func testMainFrameClientAndServerErrorsAreTerminal() {
        XCTAssertTrue(WebViewHTTPStatus.isTerminalError(statusCode: 404, isMainFrame: true))
        XCTAssertTrue(WebViewHTTPStatus.isTerminalError(statusCode: 500, isMainFrame: true))
    }

    func testMainFrameSuccessAndRedirectStatusesAreNotTerminal() {
        XCTAssertFalse(WebViewHTTPStatus.isTerminalError(statusCode: 200, isMainFrame: true))
        XCTAssertFalse(WebViewHTTPStatus.isTerminalError(statusCode: 304, isMainFrame: true))
    }

    func testSubFrameErrorsAreNotTerminal() {
        // A failing sub-resource must not tear down the whole web view; only main-frame errors do.
        XCTAssertFalse(WebViewHTTPStatus.isTerminalError(statusCode: 404, isMainFrame: false))
        XCTAssertFalse(WebViewHTTPStatus.isTerminalError(statusCode: 500, isMainFrame: false))
    }

}
