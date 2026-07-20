//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewComponentTests: TestCase {

    func testDecodesFullAndMinimalJSON() throws {
        let full = try JSONDecoder.default.decode(PaywallComponent.self, from: Data("""
        {
          "type": "web_view",
          "id": "web",
          "name": "Survey",
          "visible": false,
          "protocol_version": 2,
          "url": "https://example.com/index.html",
          "size": { "width": { "type": "fixed", "value": 320 }, "height": { "type": "fit" } },
          "unknown": true
        }
        """.utf8))

        guard case .webView(let fullComponent) = full else {
            return XCTFail("Expected web_view")
        }
        XCTAssertEqual(fullComponent.id, "web")
        XCTAssertEqual(fullComponent.name, "Survey")
        XCTAssertEqual(fullComponent.visible, false)
        XCTAssertEqual(fullComponent.protocolVersion, 2)
        XCTAssertEqual(fullComponent.url, "https://example.com/index.html")

        let minimal = try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: Data("""
        { "type": "web_view", "url": "https://example.com" }
        """.utf8))

        XCTAssertNil(minimal.id)
        XCTAssertNil(minimal.visible)
        XCTAssertEqual(minimal.protocolVersion, 1)
        XCTAssertEqual(minimal.size.width, .fill)
        XCTAssertEqual(minimal.size.height, .fit)
    }

    func testViewModelURLValidationHashingAndLocale() {
        let component = PaywallComponent.WebViewComponent(
            id: "web",
            protocolVersion: 2,
            url: "https://example.com/path",
            size: .init(width: .fill, height: .fit)
        )
        let viewModel = WebViewComponentViewModel(
            component: component,
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:])
        )

        XCTAssertEqual(viewModel.url?.absoluteString, "https://example.com/path")
        XCTAssertEqual(viewModel.componentID, "web")
        XCTAssertEqual(viewModel.protocolVersion, 2)
        XCTAssertEqual(viewModel.locale.identifier, "en_US")

        let differentID = WebViewComponentViewModel(
            component: .init(id: "other", url: "https://example.com/path"),
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:])
        )
        XCTAssertNotEqual(viewModel, differentID)

        for invalidURL in [
            "http://example.com",
            "file:///tmp/index.html",
            "custom://example.com",
            "https:///missing-host",
            "https://example.com/{{ custom.url }}"
        ] {
            let invalid = WebViewComponentViewModel(
                component: .init(url: invalidURL),
                localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:])
            )
            XCTAssertNil(invalid.url)
        }
    }

    func testViewModelWithoutIDSignalsRenderOnlyMode() {
        // A missing schema `id` puts the component in render-only mode: the view still renders
        // the (isolated) web view but installs no session/bridge. The view switches on exactly
        // these two properties, so pin them.
        let viewModel = WebViewComponentViewModel(
            component: .init(url: "https://example.com/index.html"),
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:])
        )

        XCTAssertNil(viewModel.componentID)
        XCTAssertNotNil(viewModel.url)
    }

}

#endif
