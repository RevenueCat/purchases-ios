//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewOriginTests.swift
//
//  Created by Antonio Pallares on 7/21/26.

@testable import RevenueCatUI
import XCTest

#if !os(tvOS) && canImport(WebKit)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewOriginTests: TestCase {

    // MARK: - Construction from URL

    func testInitFromURLCanonicalizesCaseAndStripsPathAndDefaultPort() {
        XCTAssertEqual(WebViewOrigin(url: URL(string: "https://Example.COM:443/path?q=1#frag")!)?.value,
                       "https://example.com")
        XCTAssertEqual(WebViewOrigin(url: URL(string: "HTTPS://Example.COM/path")!)?.value,
                       "https://example.com")
        XCTAssertEqual(WebViewOrigin(url: URL(string: "http://Example.COM:80/path")!)?.value,
                       "http://example.com")
    }

    func testInitFromURLKeepsNonDefaultPort() {
        XCTAssertEqual(WebViewOrigin(url: URL(string: "https://example.com:8443/path")!)?.value,
                       "https://example.com:8443")
        XCTAssertEqual(WebViewOrigin(url: URL(string: "http://example.com:8080")!)?.value,
                       "http://example.com:8080")
        // 80 is only the default for http, so it is preserved on https.
        XCTAssertEqual(WebViewOrigin(url: URL(string: "https://example.com:80")!)?.value,
                       "https://example.com:80")
    }

    func testInitFromURLReturnsNilWithoutSchemeOrHost() {
        XCTAssertNil(WebViewOrigin(url: nil))
        XCTAssertNil(WebViewOrigin(url: URL(string: "https:///no-host")!))
        XCTAssertNil(WebViewOrigin(url: URL(string: "/relative/path")!))
    }

    func testInitFromURLKeepsNonHTTPSchemes() {
        XCTAssertEqual(WebViewOrigin(url: URL(string: "custom://example.com/")!)?.value,
                       "custom://example.com")
    }

    // MARK: - Construction from string

    func testInitFromStringAcceptsFullURLAndBareOrigin() {
        XCTAssertEqual(WebViewOrigin(string: "https://example.com")?.value, "https://example.com")
        XCTAssertEqual(WebViewOrigin(string: "https://Example.com:443/paywall/index.html")?.value,
                       "https://example.com")
        XCTAssertEqual(WebViewOrigin(string: "https://example.com:8443")?.value,
                       "https://example.com:8443")
    }

    func testInitFromStringReturnsNilForUnresolvableInput() {
        XCTAssertNil(WebViewOrigin(string: nil))
        XCTAssertNil(WebViewOrigin(string: ""))
        XCTAssertNil(WebViewOrigin(string: "not a valid origin"))
        XCTAssertNil(WebViewOrigin(string: "https:///no-host"))
    }

    // MARK: - isHTTPS

    func testIsHTTPS() {
        XCTAssertTrue(WebViewOrigin(string: "https://example.com")!.isHTTPS)
        XCTAssertFalse(WebViewOrigin(string: "http://example.com")!.isHTTPS)
        XCTAssertFalse(WebViewOrigin(string: "custom://example.com")!.isHTTPS)
    }

    // MARK: - Equatable

    func testEquatableComparesCanonicalValues() {
        XCTAssertEqual(WebViewOrigin(string: "https://Example.COM:443")!,
                       WebViewOrigin(url: URL(string: "https://example.com/other")!)!)
        XCTAssertNotEqual(WebViewOrigin(string: "https://example.com")!,
                          WebViewOrigin(string: "https://example.com:8443")!)
        XCTAssertNotEqual(WebViewOrigin(string: "https://example.com")!,
                          WebViewOrigin(string: "http://example.com")!)
    }

    // MARK: - matches(url:)

    func testMatchesURL() {
        let origin = WebViewOrigin(string: "https://example.com")!
        XCTAssertTrue(origin.matches(url: URL(string: "https://example.com/promo/step-two.html")!))
        XCTAssertTrue(origin.matches(url: URL(string: "HTTPS://Example.COM:443/x")!))
        XCTAssertFalse(origin.matches(url: URL(string: "https://evil.example/phish.html")!))
        XCTAssertFalse(origin.matches(url: URL(string: "https://example.com:8443/x")!))
        XCTAssertFalse(origin.matches(url: nil))
        XCTAssertFalse(origin.matches(url: URL(string: "https:///no-host")!))
    }

    // MARK: - matches(originString:)

    func testMatchesOriginString() {
        let origin = WebViewOrigin(string: "https://example.com")!
        XCTAssertTrue(origin.matches(originString: "https://example.com"))
        XCTAssertTrue(origin.matches(originString: "https://Example.COM:443/some/path"))
        XCTAssertFalse(origin.matches(originString: "https://evil.example.org"))
        XCTAssertFalse(origin.matches(originString: "https://example.com:8443"))
        XCTAssertFalse(origin.matches(originString: nil))
        XCTAssertFalse(origin.matches(originString: "not a valid origin"))
    }

}

#endif
