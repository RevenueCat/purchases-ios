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

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewComponentTests: TestCase {

    // MARK: - JSON decoding

    private static let webViewJSON = """
    {
      "id": "promo_web_view",
      "type": "web_view",
      "protocol_version": 1,
      "url": "https://example.com",
      "size": {
        "width": { "type": "fill" },
        "height": { "type": "fit" }
      },
      "visible": true,
      "name": "Promo web component"
    }
    """

    func testDecodeWebViewComponent() throws {
        let component = try JSONDecoder.default.decode(
            PaywallComponent.self,
            from: Self.webViewJSON.data(using: .utf8)!
        )

        guard case .webView(let webView) = component else {
            XCTFail("Expected .webView component, got \(component)")
            return
        }

        XCTAssertEqual(webView.id, "promo_web_view")
        XCTAssertEqual(webView.name, "Promo web component")
        XCTAssertEqual(webView.visible, true)
        XCTAssertEqual(webView.protocolVersion, 1)
        XCTAssertEqual(webView.url, "https://example.com")
        XCTAssertEqual(webView.size, .init(width: .fill, height: .fit))
    }

    func testDecodeWebViewComponentRoundTrip() throws {
        let component = try JSONDecoder.default.decode(
            PaywallComponent.WebViewComponent.self,
            from: Self.webViewJSON.data(using: .utf8)!
        )
        let encoded = try JSONEncoder().encode(component)
        let decoded = try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: encoded)

        XCTAssertEqual(component, decoded)
        XCTAssertEqual(decoded.url, "https://example.com")
        XCTAssertEqual(decoded.protocolVersion, 1)
        XCTAssertEqual(decoded.size, .init(width: .fill, height: .fit))
        XCTAssertEqual(decoded.visible, true)
    }

    func testDecodeUnknownKeyIsIgnored() throws {
        let json = """
        {
          "id": "wv",
          "type": "web_view",
          "url": "https://example.com",
          "future_field": "yes"
        }
        """
        // An unknown key must be ignored, not rejected.
        let component = try JSONDecoder.default.decode(
            PaywallComponent.WebViewComponent.self,
            from: json.data(using: .utf8)!
        )
        XCTAssertEqual(component.url, "https://example.com")
    }

    func testDecodeWebViewComponentWithFixedHeightSize() throws {
        let json = """
        {
          "type": "web_view",
          "url": "https://example.com",
          "size": {
            "width": { "type": "fill" },
            "height": { "type": "fixed", "value": 320 }
          }
        }
        """.data(using: .utf8)!

        let webView = try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: json)

        XCTAssertEqual(webView.size.width, .fill)
        XCTAssertEqual(webView.size.height, .fixed(320))
    }

    func testDecodeWebViewComponentNotVisible() throws {
        let json = """
        {
          "type": "web_view",
          "url": "https://example.com",
          "visible": false,
          "size": { "width": { "type": "fill" }, "height": { "type": "fit" } }
        }
        """.data(using: .utf8)!

        let webView = try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: json)

        XCTAssertEqual(webView.visible, false)

        // The view model surfaces visibility the same way other components do.
        let viewModel = Self.makeViewModel(component: webView)
        XCTAssertFalse(viewModel.visible)
    }

    // MARK: - URL validation

    func testURLReturnsValidHTTPSURL() {
        let viewModel = Self.makeViewModel(url: "https://example.com/page.html")

        XCTAssertEqual(viewModel.url?.absoluteString, "https://example.com/page.html")
    }

    func testURLRejectsHTTPURL() {
        let viewModel = Self.makeViewModel(url: "http://example.com/page.html")

        XCTAssertNil(viewModel.url)
    }

    func testURLRejectsFileURL() {
        let viewModel = Self.makeViewModel(url: "file:///tmp/page.html")

        XCTAssertNil(viewModel.url)
    }

    func testURLRejectsCustomSchemeURL() {
        let viewModel = Self.makeViewModel(url: "custom-scheme://example.com/page.html")

        XCTAssertNil(viewModel.url)
    }

    func testURLRejectsURLWithoutHost() {
        let viewModel = Self.makeViewModel(url: "https:/page.html")

        XCTAssertNil(viewModel.url)
    }

    func testURLRejectsTemplateURLContainingBraces() {
        let viewModel = Self.makeViewModel(url: "https://example.com/{{ custom.animal }}.html")

        XCTAssertNil(viewModel.url)
    }

    // MARK: - Component ID, locale, protocol version

    func testViewModelExposesSchemaComponentID() {
        let viewModel = Self.makeViewModel(
            component: .init(id: "promo_web_view", url: "https://example.com")
        )

        XCTAssertEqual(viewModel.componentID, "promo_web_view")
    }

    func testViewModelComponentIDIsNilWhenSchemaOmitsID() {
        let viewModel = Self.makeViewModel(component: .init(url: "https://example.com"))

        XCTAssertNil(viewModel.componentID)
    }

    func testViewModelExposesLocale() {
        let viewModel = Self.makeViewModel(url: "https://example.com")

        XCTAssertEqual(viewModel.locale, Locale(identifier: "en_US"))
    }

    func testViewModelDefaultsProtocolVersionToOne() {
        let viewModel = Self.makeViewModel(component: .init(url: "https://example.com"))

        XCTAssertEqual(viewModel.protocolVersion, 1)
    }

    func testViewModelExposesDecodedProtocolVersion() {
        let viewModel = Self.makeViewModel(
            component: .init(protocolVersion: 2, url: "https://example.com")
        )

        XCTAssertEqual(viewModel.protocolVersion, 2)
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WebViewComponentTests {

    static func makeViewModel(url: String) -> WebViewComponentViewModel {
        return makeViewModel(component: .init(url: url))
    }

    static func makeViewModel(
        component: PaywallComponent.WebViewComponent
    ) -> WebViewComponentViewModel {
        return WebViewComponentViewModel(
            component: component,
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:])
        )
    }

}

#endif
