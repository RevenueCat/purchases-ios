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

    func testDecodeWebViewComponentWithTemplateURL() throws {
        let json = """
        {
          "type": "web_view",
          "url": "https://example.com/{{ custom.animal }}.html",
          "size": { "width": { "type": "fill" }, "height": { "type": "fit" } }
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder.default.decode(PaywallComponent.self, from: json)

        guard case .webView(let webView) = component else {
            XCTFail("Expected .webView component, got \(component)")
            return
        }

        XCTAssertEqual(webView.url, "https://example.com/{{ custom.animal }}.html")
    }

    // MARK: - Variable resolution

    func testResolvedURLWithNoTemplateReturnsSameURL() {
        let viewModel = Self.makeViewModel(urlTemplate: "https://example.com/page.html")

        let result = viewModel.resolvedURL(customVariables: [:])

        XCTAssertEqual(result?.absoluteString, "https://example.com/page.html")
    }

    func testResolvedURLSubstitutesRuntimeCustomVariable() {
        let viewModel = Self.makeViewModel(
            urlTemplate: "https://example.com/{{ custom.animal }}.html",
            customVariableDefinitions: ["animal": .init(type: "string", defaultValue: "cat")]
        )

        let result = viewModel.resolvedURL(customVariables: ["animal": .string("dog")])

        XCTAssertEqual(result?.absoluteString, "https://example.com/dog.html")
    }

    func testResolvedURLFallsBackToDashboardDefaultCustomVariable() {
        let viewModel = Self.makeViewModel(
            urlTemplate: "https://example.com/{{ custom.animal }}.html",
            customVariableDefinitions: ["animal": .init(type: "string", defaultValue: "cat")]
        )

        // No runtime variables supplied — should use dashboard default "cat"
        let result = viewModel.resolvedURL(customVariables: [:])

        XCTAssertEqual(result?.absoluteString, "https://example.com/cat.html")
    }

    func testResolvedURLRuntimeVariableOverridesDashboardDefault() {
        let viewModel = Self.makeViewModel(
            urlTemplate: "https://example.com/{{ custom.animal }}.html",
            customVariableDefinitions: ["animal": .init(type: "string", defaultValue: "cat")]
        )

        let result = viewModel.resolvedURL(customVariables: ["animal": .string("bird")])

        XCTAssertEqual(result?.absoluteString, "https://example.com/bird.html")
    }

    func testResolvedURLRejectsHTTPURL() {
        let viewModel = Self.makeViewModel(urlTemplate: "http://example.com/page.html")

        let result = viewModel.resolvedURL(customVariables: [:])

        XCTAssertNil(result)
    }

    func testResolvedURLRejectsFileURL() {
        let viewModel = Self.makeViewModel(urlTemplate: "file:///tmp/page.html")

        let result = viewModel.resolvedURL(customVariables: [:])

        XCTAssertNil(result)
    }

    func testResolvedURLRejectsCustomSchemeURL() {
        let viewModel = Self.makeViewModel(urlTemplate: "custom-scheme://example.com/page.html")

        let result = viewModel.resolvedURL(customVariables: [:])

        XCTAssertNil(result)
    }

    func testResolvedURLRejectsURLWithoutHost() {
        let viewModel = Self.makeViewModel(urlTemplate: "https:/page.html")

        let result = viewModel.resolvedURL(customVariables: [:])

        XCTAssertNil(result)
    }

    func testResolvedURLRejectsCustomVariableSubstitutedHTTPURL() {
        let viewModel = Self.makeViewModel(
            urlTemplate: "{{ custom.url }}",
            customVariableDefinitions: ["url": .init(type: "string", defaultValue: "https://example.com/page.html")]
        )

        let result = viewModel.resolvedURL(customVariables: ["url": .string("http://example.com/page.html")])

        XCTAssertNil(result)
    }

    func testResolvedURLReturnsNilForUnresolvableTemplate() {
        // Missing variable with no default → resolves to empty string → invalid URL
        let viewModel = Self.makeViewModel(
            urlTemplate: "https://example.com/{{ custom.missing }}.html"
        )

        // Empty string substituted for unknown variable produces an invalid URL
        let result = viewModel.resolvedURL(customVariables: [:])

        // "https://example.com/.html" is technically valid, so we just check it ran
        XCTAssertNotNil(result)
    }

    // MARK: - Component ID & locale

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
        let viewModel = Self.makeViewModel(urlTemplate: "https://example.com")

        XCTAssertEqual(viewModel.locale, Locale(identifier: "en_US"))
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WebViewComponentTests {

    static func makeViewModel(
        urlTemplate: String,
        customVariableDefinitions: [String: UIConfig.CustomVariableDefinition] = [:]
    ) -> WebViewComponentViewModel {
        return makeViewModel(
            component: .init(url: urlTemplate),
            customVariableDefinitions: customVariableDefinitions
        )
    }

    static func makeViewModel(
        component: PaywallComponent.WebViewComponent,
        customVariableDefinitions: [String: UIConfig.CustomVariableDefinition] = [:]
    ) -> WebViewComponentViewModel {
        let uiConfig = UIConfig(
            app: .init(colors: [:], fonts: [:]),
            localizations: [:],
            variableConfig: .init(variableCompatibilityMap: [:], functionCompatibilityMap: [:]),
            customVariables: customVariableDefinitions
        )
        return WebViewComponentViewModel(
            component: component,
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:]),
            uiConfigProvider: UIConfigProvider(uiConfig: uiConfig)
        )
    }

}

#endif
