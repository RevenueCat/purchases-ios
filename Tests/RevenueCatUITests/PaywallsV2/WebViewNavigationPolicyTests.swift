//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@testable import RevenueCatUI
import XCTest

#if !os(tvOS) && canImport(WebKit)
import WebKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewNavigationPolicyTests: TestCase {

    private let expectedOrigin = WebViewOrigin(string: "https://example.com")!

    func testSameOriginMainFrameDifferentPathIsAllowed() {
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "https://example.com/promo/step-two.html")!,
                isMainFrame: true,
                expectedOrigin: self.expectedOrigin
            ),
            .allow
        )
    }

    func testCrossOriginMainFrameIsCancelled() {
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "https://evil.example/phish.html")!,
                isMainFrame: true,
                expectedOrigin: self.expectedOrigin
            ),
            .cancel
        )
    }

    func testMainFramePortMismatchIsCancelled() {
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "https://example.com:8443/next")!,
                isMainFrame: true,
                expectedOrigin: self.expectedOrigin
            ),
            .cancel
        )
    }

    func testNonHttpsIsCancelledOnAnyFrame() {
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "http://example.com/promo/index.html")!,
                isMainFrame: false,
                expectedOrigin: self.expectedOrigin
            ),
            .cancel
        )
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "custom://example.com/")!,
                isMainFrame: true,
                expectedOrigin: self.expectedOrigin
            ),
            .cancel
        )
    }

    func testCrossOriginHttpsSubFrameIsAllowed() {
        // Sub-frame isolation is expected from the server-provided CSP, not this navigation policy.
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "https://other.example.com/frame.html")!,
                isMainFrame: false,
                expectedOrigin: self.expectedOrigin
            ),
            .allow
        )
    }

    func testNilURLMainFrameIsCancelled() {
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: nil,
                isMainFrame: true,
                expectedOrigin: self.expectedOrigin
            ),
            .cancel
        )
    }

    func testNonCanonicalTargetCaseAndDefaultPortIsAllowed() {
        // The navigated URL is normalized before comparison, so case and explicit default port match.
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "HTTPS://Example.COM:443/promo/index.html")!,
                isMainFrame: true,
                expectedOrigin: self.expectedOrigin
            ),
            .allow
        )
    }

    func testNonCanonicalExpectedOriginIsAllowed() {
        // The expected origin is normalized at construction, so a non-canonical spelling still matches.
        let expectedOrigin = WebViewOrigin(string: "https://Example.COM:443")!
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "https://example.com/promo/index.html")!,
                isMainFrame: true,
                expectedOrigin: expectedOrigin
            ),
            .allow
        )
    }

    // MARK: - HTTP status handling

    func testMainFrameClientAndServerErrorsAreTerminal() {
        XCTAssertTrue(WebViewNavigationPolicy.isTerminalHTTPError(statusCode: 404, isMainFrame: true))
        XCTAssertTrue(WebViewNavigationPolicy.isTerminalHTTPError(statusCode: 500, isMainFrame: true))
    }

    func testMainFrameSuccessAndRedirectStatusesAreNotTerminal() {
        XCTAssertFalse(WebViewNavigationPolicy.isTerminalHTTPError(statusCode: 200, isMainFrame: true))
        XCTAssertFalse(WebViewNavigationPolicy.isTerminalHTTPError(statusCode: 304, isMainFrame: true))
    }

    func testSubFrameErrorsAreNotTerminal() {
        // A failing sub-resource must not remove the whole component; only main-frame errors do.
        XCTAssertFalse(WebViewNavigationPolicy.isTerminalHTTPError(statusCode: 404, isMainFrame: false))
        XCTAssertFalse(WebViewNavigationPolicy.isTerminalHTTPError(statusCode: 500, isMainFrame: false))
    }

}

#endif
