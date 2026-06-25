//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewComponentTests.swift

import Foundation
@_spi(Internal) @testable import RevenueCat
import XCTest

class WebViewComponentTests: TestCase {

    func testCodable() throws {
        let jsonData = try JsonLoader.data(for: "WebViewComponent")

        let webView: PaywallComponent.WebViewComponent = try JSONDecoder.default
            .decode(PaywallComponent.WebViewComponent.self, from: jsonData)

        let webView2 = try webView.encodeAndDecode()

        XCTAssertEqual(webView.id, "promo_web_view")
        XCTAssertEqual(webView.name, "Promo web component")
        XCTAssertEqual(webView.visible, true)
        XCTAssertEqual(webView.protocolVersion, 1)
        XCTAssertEqual(webView.url, "https://example.com")
        XCTAssertEqual(webView.size, .init(width: .fill, height: .fit))

        // Round-trip preserves everything.
        XCTAssertEqual(webView, webView2)
    }

    func testDecodeAsPaywallComponent() throws {
        let jsonData = try JsonLoader.data(for: "WebViewComponent")

        let component = try JSONDecoder.default
            .decode(PaywallComponent.self, from: jsonData)

        guard case .webView(let webView) = component else {
            XCTFail("Expected .webView component, got \(component)")
            return
        }

        XCTAssertEqual(webView.url, "https://example.com")
        XCTAssertEqual(webView.protocolVersion, 1)
    }

    func testDecodeDefaultsProtocolVersionAndSizeWhenAbsent() throws {
        let json = """
        {
          "type": "web_view",
          "url": "https://example.com"
        }
        """.data(using: .utf8)!

        let webView = try JSONDecoder.default
            .decode(PaywallComponent.WebViewComponent.self, from: json)

        XCTAssertEqual(webView.protocolVersion, 1)
        XCTAssertEqual(webView.size, .init(width: .fill, height: .fit))
    }

    func testDecodeUnknownKeyIsIgnored() throws {
        let json = """
        {
          "type": "web_view",
          "url": "https://example.com",
          "future_field": "yes"
        }
        """.data(using: .utf8)!

        let webView = try JSONDecoder.default
            .decode(PaywallComponent.WebViewComponent.self, from: json)

        XCTAssertEqual(webView.url, "https://example.com")
    }

}
