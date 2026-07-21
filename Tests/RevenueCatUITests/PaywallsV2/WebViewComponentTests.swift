//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest
// swiftlint:disable force_try

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewComponentTests: TestCase {

    // MARK: - Schema decoding

    func testDecodesMinimalJSONAndIgnoresUnknownKeys() throws {
        let minimal = try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: Data("""
        {
          "type": "web_view",
          "id": "web",
          "protocol_version": 1,
          "url": "https://example.com",
          "size": { "width": { "type": "fill" }, "height": { "type": "fit" } },
          "unknown": true
        }
        """.utf8))

        XCTAssertEqual(minimal.id, "web")
        XCTAssertNil(minimal.name)
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
          "id": "web",
          "protocol_version": 1,
          "url": "https://example.com/index.html",
          "size": { "width": { "type": "fill" }, "height": { "type": "fit" } },
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

        XCTAssertEqual(
            component,
            PaywallComponent.WebViewComponent(id: "web", protocolVersion: 1, url: "https://example.com/index.html")
        )
    }

    func testDecodesTemplateURLVerbatim() throws {
        // Template placeholders in the URL are resolved elsewhere; decoding must preserve them as-is.
        let component = try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: Data("""
        {
          "type": "web_view",
          "id": "web",
          "protocol_version": 1,
          "url": "https://example.com/{{ custom.animal }}.html",
          "size": { "width": { "type": "fill" }, "height": { "type": "fit" } }
        }
        """.utf8))

        XCTAssertEqual(component.url, "https://example.com/{{ custom.animal }}.html")
        XCTAssertEqual(
            component,
            PaywallComponent.WebViewComponent(
                id: "web",
                protocolVersion: 1,
                url: "https://example.com/{{ custom.animal }}.html"
            )
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
            {
              "type": "web_view",
              "id": "web",
              "protocol_version": 1,
              "size": { "width": { "type": "fill" }, "height": { "type": "fit" } }
            }
            """.utf8))
        )
    }

    func testDecodingWithoutIDThrows() {
        XCTAssertThrowsError(
            try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: Data("""
            {
              "type": "web_view",
              "protocol_version": 1,
              "url": "https://example.com",
              "size": { "width": { "type": "fill" }, "height": { "type": "fit" } }
            }
            """.utf8))
        )
    }

    func testDecodingWithoutProtocolVersionThrows() {
        XCTAssertThrowsError(
            try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: Data("""
            {
              "type": "web_view",
              "id": "web",
              "url": "https://example.com",
              "size": { "width": { "type": "fill" }, "height": { "type": "fit" } }
            }
            """.utf8))
        )
    }

    func testDecodingWithoutSizeThrows() {
        XCTAssertThrowsError(
            try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: Data("""
            { "type": "web_view", "id": "web", "protocol_version": 1, "url": "https://example.com" }
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

    // MARK: - Provisional fit sizing

    func testDecodesFitLoadingDefaults() throws {
        let component = try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: Data("""
        {
          "type": "web_view",
          "id": "web",
          "protocol_version": 1,
          "url": "https://example.com",
          "size": {
            "width": { "type": "fit", "default": 320 },
            "height": { "type": "fit", "default": 180 }
          }
        }
        """.utf8))

        XCTAssertEqual(component.size.width, .fit(320))
        XCTAssertEqual(component.size.height, .fit(180))
    }

    func testResolvedFitDimensionPrecedence() {
        XCTAssertEqual(
            WebViewSizing.resolvedDimension(measured: 420, defaultSize: 240, fallback: 300),
            420
        )
        XCTAssertEqual(
            WebViewSizing.resolvedDimension(measured: nil, defaultSize: 240, fallback: 300),
            240
        )
        XCTAssertEqual(
            WebViewSizing.resolvedDimension(measured: nil, defaultSize: nil, fallback: 300),
            300
        )
    }

    // MARK: - View model

    func testViewModelURLValidationAndHashing() {
        let component = PaywallComponent.WebViewComponent(
            id: "web",
            protocolVersion: 2,
            url: "https://example.com/path",
            size: .init(width: .fill, height: .fit(nil))
        )
        let viewModel = WebViewComponentViewModel(
            component: component,
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:])
        )

        XCTAssertEqual(viewModel.url?.absoluteString, "https://example.com/path")
        XCTAssertEqual(viewModel.componentID, "web")

        let differentID = WebViewComponentViewModel(
            component: .init(id: "other", protocolVersion: 1, url: "https://example.com/path"),
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
                component: .init(id: "web", protocolVersion: 1, url: invalidURL),
                localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:])
            )
            XCTAssertNil(invalid.url)
        }
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

#if canImport(WebKit) && !os(watchOS)
import WebKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewCoordinatorLifecycleTests: TestCase {

    func testDidCommitResetsConnectedSessionChannel() {
        let session = WebViewSession(
            componentID: "web",
            expectedOrigin: "https://example.com",
            fitAxes: (width: false, height: false),
            evaluateJavaScript: { _ in },
            currentURL: { nil }
        )
        let data = try! JSONEncoder().encode(WebViewEnvelope.Envelope(kind: .connect, componentID: ""))
        session.handle(
            rawMessage: String(data: data, encoding: .utf8)!,
            isMainFrame: true,
            sourceOrigin: "https://example.com"
        )
        XCTAssertTrue(session.channelOpen)

        let coordinator = WebViewRepresentable.Coordinator(expectedOrigin: "https://example.com")
        coordinator.session = session
        coordinator.webView(WKWebView(frame: .zero), didCommit: nil)

        XCTAssertFalse(session.channelOpen)
    }

    func testProcessTerminationInvokesCallbackOncePerCall() {
        let coordinator = WebViewRepresentable.Coordinator(expectedOrigin: "https://example.com")
        var calls = 0
        coordinator.onProcessTerminated = { calls += 1 }

        let webView = WKWebView(frame: .zero)
        coordinator.webViewWebContentProcessDidTerminate(webView)
        coordinator.webViewWebContentProcessDidTerminate(webView)

        XCTAssertEqual(calls, 2)
    }

}

#endif

#endif
