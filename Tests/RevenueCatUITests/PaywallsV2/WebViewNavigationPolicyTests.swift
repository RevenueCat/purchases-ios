//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@testable import RevenueCatUI
import XCTest

#if !os(tvOS) && canImport(WebKit)
import WebKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewNavigationPolicyTests: TestCase {

    func testMainFrameSameOriginAllowedCrossOriginCancelledSubFrameAllowed() {
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "https://example.com/next")!,
                isMainFrame: true,
                expectedOrigin: "https://example.com"
            ),
            .allow
        )
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "https://evil.example/next")!,
                isMainFrame: true,
                expectedOrigin: "https://example.com"
            ),
            .cancel
        )
        XCTAssertEqual(
            WebViewNavigationPolicy.policy(
                for: URL(string: "https://evil.example/next")!,
                isMainFrame: false,
                expectedOrigin: "https://example.com"
            ),
            .allow
        )
    }

}

#endif
