//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@_spi(Internal) @testable import RevenueCat
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewComponentTests: TestCase {

    func testDecodesMinimalJSONDefaultsAndIgnoresUnknownKeys() throws {
        let minimal = try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: Data("""
        { "type": "web_view", "url": "https://example.com", "unknown": true }
        """.utf8))

        XCTAssertNil(minimal.id)
        XCTAssertNil(minimal.visible)
        XCTAssertEqual(minimal.protocolVersion, 1)
        XCTAssertEqual(minimal.size.width, .fill)
        XCTAssertEqual(minimal.size.height, .fit(nil))
        XCTAssertEqual(minimal.url, "https://example.com")
        XCTAssertEqual(minimal.type, "web_view")
    }

    func testDecodesExplicitFields() throws {
        let component = try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: Data("""
        {
          "type": "web_view",
          "id": "web",
          "name": "Survey",
          "visible": false,
          "protocol_version": 2,
          "url": "https://example.com/index.html",
          "size": { "width": { "type": "fixed", "value": 320 }, "height": { "type": "fit" } }
        }
        """.utf8))

        XCTAssertEqual(component.id, "web")
        XCTAssertEqual(component.name, "Survey")
        XCTAssertEqual(component.visible, false)
        XCTAssertEqual(component.protocolVersion, 2)
        XCTAssertEqual(component.url, "https://example.com/index.html")
    }

    func testIgnoresCapabilitiesDeclaredByTheSchema() throws {
        // Isolation from external sources is expected from the server-provided CSP, so any
        // schema-declared capabilities are decoded-and-ignored rather than failing to parse.
        let component = try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: Data("""
        {
          "type": "web_view",
          "url": "https://example.com/index.html",
          "capabilities": {
            "network_access": { "allowed_domains": ["api.segment.io"] },
            "camera": true,
            "microphone": true,
            "clipboard_write": true,
            "clipboard_read": true,
            "geolocation": true
          }
        }
        """.utf8))

        XCTAssertEqual(component, PaywallComponent.WebViewComponent(url: "https://example.com/index.html"))
    }

    func testDecodesTemplateURLVerbatim() throws {
        // Template placeholders in the URL are resolved elsewhere; decoding must preserve them as-is.
        let component = try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: Data("""
        {
          "type": "web_view",
          "protocol_version": 1,
          "url": "https://example.com/{{ custom.animal }}.html"
        }
        """.utf8))

        XCTAssertEqual(component.url, "https://example.com/{{ custom.animal }}.html")
        XCTAssertEqual(
            component,
            PaywallComponent.WebViewComponent(protocolVersion: 1, url: "https://example.com/{{ custom.animal }}.html")
        )
    }

    func testEncodeDecodeRoundTripUsesSnakeCaseWireKeys() throws {
        let component = PaywallComponent.WebViewComponent(
            id: "web",
            name: "Survey",
            visible: true,
            protocolVersion: 2,
            url: "https://example.com/index.html"
        )

        let data = try JSONEncoder.default.encode(component)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"protocol_version\""))
        XCTAssertTrue(json.contains("\"web_view\""))

        let decoded = try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: data)
        XCTAssertEqual(decoded, component)
    }

    func testDecodingWithoutURLThrows() {
        XCTAssertThrowsError(
            try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: Data("""
            { "type": "web_view" }
            """.utf8))
        )
    }

    func testPaywallComponentTreatsWebViewAsUnknownAndUsesFallback() throws {
        let decoded = try JSONDecoder.default.decode(PaywallComponent.self, from: Data("""
        {
            "type": "web_view",
            "url": "https://example.com",
            "fallback": \(Self.fallbackStackJSON)
        }
        """.utf8))

        guard case .stack = decoded else {
            return XCTFail("web_view should be unknown to PaywallComponent and fall back to the stack")
        }
    }

    func testPaywallComponentWebViewWithoutFallbackThrows() {
        XCTAssertThrowsError(
            try JSONDecoder.default.decode(PaywallComponent.self, from: Data("""
            { "type": "web_view", "url": "https://example.com" }
            """.utf8))
        )
    }

    private static let fallbackStackJSON = """
    {
        "type": "stack",
        "dimension": { "type": "vertical", "alignment": "center", "distribution": "start" },
        "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
        "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
        "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
        "components": []
    }
    """

}

#endif
