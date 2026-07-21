//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@testable import RevenueCatUI
import XCTest

#if !os(tvOS) && canImport(WebKit)
import WebKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewNavigationPolicyTests: TestCase {

    func testSameOriginMainFrameDifferentPathIsAllowed() {
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "https://example.com/promo/step-two.html")!,
                isMainFrame: true,
                expectedOrigin: "https://example.com"
            ),
            .allow
        )
    }

    func testCrossOriginMainFrameIsCancelled() {
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "https://evil.example/phish.html")!,
                isMainFrame: true,
                expectedOrigin: "https://example.com"
            ),
            .cancel
        )
    }

    func testMainFramePortMismatchIsCancelled() {
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "https://example.com:8443/next")!,
                isMainFrame: true,
                expectedOrigin: "https://example.com"
            ),
            .cancel
        )
    }

    func testNonHttpsIsCancelledOnAnyFrame() {
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "http://example.com/promo/index.html")!,
                isMainFrame: false,
                expectedOrigin: "https://example.com"
            ),
            .cancel
        )
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "custom://example.com/")!,
                isMainFrame: true,
                expectedOrigin: "https://example.com"
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
                expectedOrigin: "https://example.com"
            ),
            .allow
        )
    }

    func testNilURLMainFrameIsCancelled() {
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: nil,
                isMainFrame: true,
                expectedOrigin: "https://example.com"
            ),
            .cancel
        )
    }

    func testHostlessExpectedOriginMainFrameIsCancelled() {
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "https://example.com/next")!,
                isMainFrame: true,
                expectedOrigin: "https:///no-host"
            ),
            .cancel
        )
    }

    func testNonCanonicalExpectedOriginCaseAndDefaultPortIsAllowed() {
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "https://example.com/promo/index.html")!,
                isMainFrame: true,
                expectedOrigin: "https://Example.COM:443"
            ),
            .allow
        )
    }

    func testOriginStripsDefaultPortKeepsNonDefaultAndNormalizesCase() {
        XCTAssertEqual(
            URL(string: "https://Example.COM:443/path")!.webViewOrigin,
            "https://example.com"
        )
        XCTAssertEqual(
            URL(string: "http://Example.COM:80/path")!.webViewOrigin,
            "http://example.com"
        )
        XCTAssertEqual(
            URL(string: "HTTPS://Example.COM:8443/path")!.webViewOrigin,
            "https://example.com:8443"
        )
        XCTAssertNil(URL(string: "https:///no-host")!.webViewOrigin)
    }

}

#endif
