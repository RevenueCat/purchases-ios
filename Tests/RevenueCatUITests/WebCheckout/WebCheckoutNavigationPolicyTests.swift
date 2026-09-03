//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebCheckoutNavigationPolicyTests.swift
//
//  Created by Antonio Pallares on 3/9/26.
//

@testable import RevenueCatUI
import XCTest

#if !os(tvOS) && canImport(WebKit)
import WebKit

final class WebCheckoutNavigationPolicyTests: TestCase {

    private let checkoutURL = URL(string: "https://checkout.example.com/session/abc")!

    private func policy(additionalAllowedOrigins: [WebViewOrigin]) -> WebCheckoutNavigationPolicy {
        return WebCheckoutNavigationPolicy(
            checkoutURL: self.checkoutURL,
            additionalAllowedOrigins: additionalAllowedOrigins
        )
    }

    // MARK: - Main frame

    func testCheckoutOriginIsAllowedOnADifferentPath() {
        XCTAssertEqual(
            self.policy(additionalAllowedOrigins: []).policy(
                for: URL(string: "https://checkout.example.com/session/abc/confirm")!,
                isMainFrame: true
            ),
            .allow
        )
    }

    func testAllowlistedCrossOriginRedirectIsAllowed() {
        let provider = WebViewOrigin(string: "https://pay.provider.example")!

        XCTAssertEqual(
            self.policy(additionalAllowedOrigins: [provider]).policy(
                for: URL(string: "https://pay.provider.example/3ds/challenge")!,
                isMainFrame: true
            ),
            .allow
        )
    }

    func testOriginOutsideTheAllowlistIsCancelled() {
        XCTAssertEqual(
            self.policy(additionalAllowedOrigins: [WebViewOrigin(string: "https://pay.provider.example")!]).policy(
                for: URL(string: "https://evil.example/phish.html")!,
                isMainFrame: true
            ),
            .cancel
        )
    }

    func testSubdomainOfAnAllowedOriginIsCancelled() {
        // The allowlist matches whole origins, so it must not be widened by suffix matching.
        XCTAssertEqual(
            self.policy(additionalAllowedOrigins: []).policy(
                for: URL(string: "https://attacker.checkout.example.com/")!,
                isMainFrame: true
            ),
            .cancel
        )
    }

    func testPortMismatchWithAnAllowedOriginIsCancelled() {
        XCTAssertEqual(
            self.policy(additionalAllowedOrigins: []).policy(
                for: URL(string: "https://checkout.example.com:8443/session/abc")!,
                isMainFrame: true
            ),
            .cancel
        )
    }

    func testNonHTTPSIsCancelledEvenWhenTheHostIsAllowed() {
        XCTAssertEqual(
            self.policy(additionalAllowedOrigins: []).policy(
                for: URL(string: "http://checkout.example.com/session/abc")!,
                isMainFrame: true
            ),
            .cancel
        )
        XCTAssertEqual(
            self.policy(additionalAllowedOrigins: []).policy(
                for: URL(string: "custom://checkout.example.com/")!,
                isMainFrame: true
            ),
            .cancel
        )
    }

    func testNilURLIsCancelled() {
        XCTAssertEqual(
            self.policy(additionalAllowedOrigins: []).policy(for: nil, isMainFrame: true),
            .cancel
        )
    }

    func testNonCanonicalCaseAndDefaultPortAreAllowed() {
        XCTAssertEqual(
            self.policy(additionalAllowedOrigins: []).policy(
                for: URL(string: "HTTPS://Checkout.EXAMPLE.com:443/session/abc")!,
                isMainFrame: true
            ),
            .allow
        )
    }

    // MARK: - Allowlist construction

    func testANonHTTPSCheckoutURLAllowsNothing() {
        let policy = WebCheckoutNavigationPolicy(
            checkoutURL: URL(string: "http://checkout.example.com/session/abc")!,
            additionalAllowedOrigins: []
        )

        XCTAssertEqual(
            policy.policy(for: URL(string: "https://checkout.example.com/session/abc")!, isMainFrame: true),
            .cancel
        )
    }

    func testACheckoutURLWithoutAnOriginAllowsNothing() {
        for checkoutURL in [nil, URL(string: "checkout.example.com/session/abc")] {
            let policy = WebCheckoutNavigationPolicy(
                checkoutURL: checkoutURL,
                additionalAllowedOrigins: []
            )

            XCTAssertEqual(
                policy.policy(for: URL(string: "https://checkout.example.com/session/abc")!, isMainFrame: true),
                .cancel
            )
        }
    }

    // MARK: - Sub-frames

    func testCrossOriginSubFrameIsAllowed() {
        // A 3-D Secure challenge is served from the card issuer's domain, which cannot be enumerated.
        XCTAssertEqual(
            self.policy(additionalAllowedOrigins: []).policy(
                for: URL(string: "https://acs.some-issuing-bank.example/challenge")!,
                isMainFrame: false
            ),
            .allow
        )
    }

    func testNonHTTPSSubFrameIsAllowed() {
        // Payment providers create `about:blank` frames before assigning a source.
        XCTAssertEqual(
            self.policy(additionalAllowedOrigins: []).policy(
                for: URL(string: "about:blank")!,
                isMainFrame: false
            ),
            .allow
        )
    }

}

#endif
