//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
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
        XCTAssertEqual(minimal.size.height, .fit)
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

#if canImport(WebKit) && !os(watchOS)
import WebKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewCoordinatorLifecycleTests: TestCase {

    func testDidCommitResetsConnectedSessionChannel() {
        let session = WebViewSession(
            componentID: "web",
            protocolVersion: 1,
            expectedOrigin: "https://example.com",
            localeIdentifier: "en_US",
            fitAxes: (width: false, height: false)
        )
        session.channelOpen = true
        // Simulate a connected channel without going through connect handshake helpers.
        // `channelOpen` is private(set); open it via connect.
        let data = try! JSONEncoder().encode(WebViewEnvelope.Envelope(kind: .connect, componentID: ""))
        session.handle(
            rawMessage: String(data: data, encoding: .utf8)!,
            isMainFrame: true,
            currentURL: URL(string: "https://example.com/")
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
