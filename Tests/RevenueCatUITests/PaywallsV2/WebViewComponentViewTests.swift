//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewComponentViewTests.swift
//
//  Created by Antonio Pallares on 7/21/26.

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest
// swiftlint:disable force_try

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewComponentViewTests: TestCase {

    // MARK: - Provisional fit sizing

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

    func testViewModelURLValidation() {
        let viewModel = WebViewComponentViewModel(
            component: .init(
                id: "web",
                protocolVersion: 2,
                url: "https://example.com/path",
                size: .init(width: .fill, height: .fit(nil))
            )
        )

        XCTAssertEqual(viewModel.url?.absoluteString, "https://example.com/path")
        XCTAssertEqual(viewModel.componentID, "web")

        for invalidURL in [
            "http://example.com",
            "file:///tmp/index.html",
            "custom://example.com",
            "https:///missing-host",
            "https://example.com/{{ custom.url }}"
        ] {
            let invalid = WebViewComponentViewModel(
                component: .init(id: "web", protocolVersion: 1, url: invalidURL)
            )
            XCTAssertNil(invalid.url)
        }
    }

    func testViewModelFactoryBuildsWebViewViewModel() throws {
        let component = try JSONDecoder.default.decode(PaywallComponent.self, from: Data("""
        {
          "type": "web_view",
          "id": "web",
          "protocol_version": 1,
          "url": "https://example.com/index.html",
          "size": { "width": { "type": "fill" }, "height": { "type": "fit" } }
        }
        """.utf8))

        let uiConfigJSON = Data("""
        {
          "app": { "colors": {}, "fonts": {} },
          "localizations": {},
          "variable_config": {
            "variable_compatibility_map": {},
            "function_compatibility_map": {}
          }
        }
        """.utf8)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let uiConfig = try decoder.decode(UIConfig.self, from: uiConfigJSON)

        let result = try ViewModelFactory().toViewModel(
            component: component,
            packageValidator: PackageValidator(),
            offering: .init(
                identifier: "test_offering",
                serverDescription: "Test Offering",
                metadata: [:],
                availablePackages: [],
                webCheckoutUrl: nil
            ),
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:]),
            uiConfigProvider: UIConfigProvider(uiConfig: uiConfig),
            colorScheme: .light
        )

        guard case .webView(let built) = result else {
            return XCTFail("Expected .webView view model")
        }
        XCTAssertEqual(built.componentID, "web")
        XCTAssertEqual(built.url?.absoluteString, "https://example.com/index.html")
    }

    #if canImport(WebKit)
    func testViewModelResolvesOriginFromValidURL() {
        let viewModel = WebViewComponentViewModel(
            component: .init(id: "web", protocolVersion: 1, url: "https://example.com/path?q=1")
        )
        XCTAssertEqual(viewModel.origin?.value, "https://example.com")
    }

    func testViewModelHasNoOriginWhenURLIsInvalid() {
        let viewModel = WebViewComponentViewModel(
            component: .init(id: "web", protocolVersion: 1, url: "http://example.com")
        )
        XCTAssertNil(viewModel.url)
        XCTAssertNil(viewModel.origin)
    }

    func testViewModelIsRenderableGating() {
        // Fully valid: visible, non-empty id, resolvable HTTPS origin.
        XCTAssertTrue(
            WebViewComponentViewModel(component: .init(id: "web", protocolVersion: 1, url: "https://example.com"))
                .isRenderable
        )

        // An empty component id must not render: the bridge keys every frame on it.
        XCTAssertFalse(
            WebViewComponentViewModel(component: .init(id: "", protocolVersion: 1, url: "https://example.com"))
                .isRenderable
        )

        // Invalid URL (hence no origin) must not render.
        XCTAssertFalse(
            WebViewComponentViewModel(component: .init(id: "web", protocolVersion: 1, url: "http://example.com"))
                .isRenderable
        )

        // Intentionally-hidden components are not renderable.
        XCTAssertFalse(
            WebViewComponentViewModel(
                component: .init(id: "web", visible: false, protocolVersion: 1, url: "https://example.com")
            ).isRenderable
        )
    }
    #endif

    func testViewModelDefaultsToVisible() {
        XCTAssertTrue(
            WebViewComponentViewModel(component: .init(id: "web", protocolVersion: 1, url: "https://example.com"))
                .visible
        )
        XCTAssertFalse(
            WebViewComponentViewModel(
                component: .init(id: "web", visible: false, protocolVersion: 1, url: "https://example.com")
            ).visible
        )
    }

    func testViewModelEqualityAndHashingConsidersRenderedState() {
        func makeViewModel(
            id: String = "web",
            url: String = "https://example.com/path",
            visible: Bool? = nil,
            size: PaywallComponent.Size = .init(width: .fill, height: .fit(nil))
        ) -> WebViewComponentViewModel {
            WebViewComponentViewModel(
                component: .init(id: id, visible: visible, protocolVersion: 1, url: url, size: size)
            )
        }

        let base = makeViewModel()

        // Equal inputs produce equal (and identically hashing) view models.
        let same = makeViewModel()
        XCTAssertEqual(base, same)
        XCTAssertEqual(base.hashValue, same.hashValue)

        // Any rendered-state difference breaks equality.
        XCTAssertNotEqual(base, makeViewModel(id: "other"))
        XCTAssertNotEqual(base, makeViewModel(url: "https://example.com/other"))
        XCTAssertNotEqual(base, makeViewModel(visible: false))
        XCTAssertNotEqual(base, makeViewModel(size: .init(width: .fixed(320), height: .fit(nil))))
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
            expectedOrigin: WebViewOrigin(string: "https://example.com")!,
            fitAxes: (width: false, height: false),
            evaluateJavaScript: { _ in true },
            currentURL: { nil }
        )
        let data = try! JSONEncoder().encode(WebViewEnvelope.Envelope(kind: .connect, componentID: ""))
        session.handle(
            rawMessage: String(data: data, encoding: .utf8)!,
            isMainFrame: true,
            sourceOrigin: "https://example.com"
        )
        XCTAssertTrue(session.channelOpen)

        let coordinator = WebViewRepresentable.Coordinator(
            expectedOrigin: WebViewOrigin(string: "https://example.com")!
        )
        coordinator.session = session
        coordinator.webView(WKWebView(frame: .zero), didCommit: nil)

        XCTAssertFalse(session.channelOpen)
    }

    func testConfigurationAllowsMediaPlaybackWithoutUserGesture() {
        let configuration = WebViewRepresentable.makeConfiguration(session: nil)
        XCTAssertTrue(configuration.mediaTypesRequiringUserActionForPlayback.isEmpty)
    }

    func testProcessTerminationInvokesCallbackOncePerCall() {
        let coordinator = WebViewRepresentable.Coordinator(
            expectedOrigin: WebViewOrigin(string: "https://example.com")!
        )
        var calls = 0
        coordinator.onProcessTerminated = { calls += 1 }

        let webView = WKWebView(frame: .zero)
        coordinator.webViewWebContentProcessDidTerminate(webView)
        coordinator.webViewWebContentProcessDidTerminate(webView)

        XCTAssertEqual(calls, 2)
    }

    func testTerminalLoadFailureInvokesCallback() {
        let coordinator = WebViewRepresentable.Coordinator(
            expectedOrigin: WebViewOrigin(string: "https://example.com")!
        )
        var calls = 0
        coordinator.onLoadFailed = { calls += 1 }

        // An SSL/server-trust failure surfaces as a provisional navigation failure.
        let sslError = NSError(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateUntrusted)
        coordinator.webView(WKWebView(frame: .zero), didFailProvisionalNavigation: nil, withError: sslError)

        let genericError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost)
        coordinator.webView(WKWebView(frame: .zero), didFail: nil, withError: genericError)

        XCTAssertEqual(calls, 2)
    }

    func testCancellationsAreNotTreatedAsLoadFailures() {
        let coordinator = WebViewRepresentable.Coordinator(
            expectedOrigin: WebViewOrigin(string: "https://example.com")!
        )
        var calls = 0
        coordinator.onLoadFailed = { calls += 1 }

        // Cancelling a cross-origin navigation in `decidePolicyFor` surfaces here; not a real failure.
        let cancelled = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
        let policyChange = NSError(domain: "WebKitErrorDomain", code: 102)
        coordinator.webView(WKWebView(frame: .zero), didFailProvisionalNavigation: nil, withError: cancelled)
        coordinator.webView(WKWebView(frame: .zero), didFailProvisionalNavigation: nil, withError: policyChange)

        XCTAssertEqual(calls, 0)
    }

    // Note: the coordinator's `decidePolicyFor` methods are thin delegations to `WebViewNavigationPolicy`
    // (`policy(for:isMainFrame:expectedOrigin:)` for navigation actions, `isTerminalHTTPError(...)` for
    // navigation responses), both exhaustively covered in WebViewNavigationPolicyTests. `WKNavigationAction`
    // and `WKNavigationResponse` cannot be constructed or safely subclassed for a unit test, so the
    // delegation itself is not re-tested here.

}

#endif

#endif
