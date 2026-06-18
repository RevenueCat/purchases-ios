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

        // Fallback is decoded as a normal stack with its children preserved (not stripped).
        XCTAssertNotNil(webView.fallback)
        XCTAssertEqual(webView.fallback?.components.count, 1)

        // Capabilities are decoded for fidelity (no functional behavior).
        XCTAssertEqual(webView.capabilities?.networkAccess?.allowedDomains, ["api.segment.io"])
        XCTAssertEqual(webView.capabilities?.camera, false)

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
        XCTAssertNil(webView.fallback)
        XCTAssertNil(webView.capabilities)
    }

    func testFallbackChildrenArePreservedThroughRoundTrip() throws {
        let component = PaywallComponent.WebViewComponent(
            url: "https://example.com",
            fallback: .init(components: [
                .text(.init(text: "id_1", color: .init(light: .hex("#000000")))),
                .text(.init(text: "id_2", color: .init(light: .hex("#000000"))))
            ])
        )

        let decoded = try component.encodeAndDecode()

        XCTAssertEqual(decoded.fallback?.components.count, 2)
        XCTAssertEqual(decoded, component)
    }

}
