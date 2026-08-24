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

    func testStyleURLValidation() {
        let style = Self.defaultStyle(
            Self.makeViewModel(
                url: "https://example.com/path",
                size: .init(width: .fill, height: .fit(nil))
            )
        )

        XCTAssertEqual(style.url?.absoluteString, "https://example.com/path")
        XCTAssertEqual(style.componentID, "web")

        for invalidURL in [
            "http://example.com",
            "file:///tmp/index.html",
            "custom://example.com",
            "https:///missing-host",
            "https://example.com/{{ custom.url }}"
        ] {
            let invalid = Self.defaultStyle(Self.makeViewModel(url: invalidURL))
            XCTAssertNil(invalid.url)
        }
    }

    func testViewModelFactoryBuildsWebViewViewModel() throws {
        let result = try Self.viewModel(decodedFrom: """
        {
          "type": "web_view",
          "id": "web",
          "protocol_version": 1,
          "url": "https://example.com/index.html",
          "size": { "width": { "type": "fill" }, "height": { "type": "fit" } },
          "fallback": \(Self.fallbackStackJSON)
        }
        """)

        #if canImport(WebKit) && !os(watchOS)
        guard case .webView(let built) = result else {
            return XCTFail("Expected .webView view model")
        }
        XCTAssertEqual(built.componentID, "web")
        XCTAssertEqual(Self.defaultStyle(built).url?.absoluteString, "https://example.com/index.html")
        #else
        // Web views are unserviceable here, so decoding yields the author's fallback and the factory
        // must build a view model for that instead.
        guard case .stack = result else {
            return XCTFail("Expected fallback .stack view model, got \(result)")
        }
        #endif
    }

    func testViewModelFactoryPreservesOverrides() throws {
        // End-to-end guard for the factory seam: overrides declared in JSON must survive decoding and
        // the ViewModelFactory so they still resolve at render time. Injecting overrides directly into
        // the view model (as the resolution tests do) would pass even if the factory dropped them.
        let result = try Self.viewModel(decodedFrom: """
        {
          "type": "web_view",
          "id": "web",
          "visible": true,
          "protocol_version": 1,
          "url": "https://example.com/index.html",
          "size": { "width": { "type": "fill" }, "height": { "type": "fit" } },
          "overrides": [
            {
              "conditions": [{ "type": "selected" }],
              "properties": { "visible": false }
            }
          ],
          "fallback": \(Self.fallbackStackJSON)
        }
        """)

        #if canImport(WebKit) && !os(watchOS)
        guard case .webView(let built) = result else {
            return XCTFail("Expected .webView view model")
        }

        // Default state keeps the base (visible) value; the selected override only applies when selected.
        XCTAssertTrue(Self.defaultStyle(built).visible)
        XCTAssertFalse(Self.defaultStyle(built, state: .selected).visible)
        #else
        // The web view overrides are moot here: the author's fallback is rendered instead.
        guard case .stack = result else {
            return XCTFail("Expected fallback .stack view model, got \(result)")
        }
        #endif
    }

    #if canImport(WebKit)
    func testStyleResolvesOriginFromValidURL() {
        let style = Self.defaultStyle(Self.makeViewModel(url: "https://example.com/path?q=1"))
        XCTAssertEqual(style.origin?.value, "https://example.com")
    }

    func testStyleHasNoOriginWhenURLIsInvalid() {
        let style = Self.defaultStyle(Self.makeViewModel(url: "http://example.com"))
        XCTAssertNil(style.url)
        XCTAssertNil(style.origin)
    }

    func testStyleIsRenderableGating() {
        // Fully valid: visible, non-empty id, resolvable HTTPS origin.
        XCTAssertTrue(Self.defaultStyle(Self.makeViewModel(url: "https://example.com")).isRenderable)

        // An empty component id must not render: the bridge keys every frame on it.
        XCTAssertFalse(Self.defaultStyle(Self.makeViewModel(id: "", url: "https://example.com")).isRenderable)

        // Invalid URL (hence no origin) must not render.
        XCTAssertFalse(Self.defaultStyle(Self.makeViewModel(url: "http://example.com")).isRenderable)

        // Intentionally-hidden components are not renderable.
        XCTAssertFalse(
            Self.defaultStyle(Self.makeViewModel(url: "https://example.com", visible: false)).isRenderable
        )
    }
    #endif

    func testStyleDefaultsToVisible() {
        XCTAssertTrue(Self.defaultStyle(Self.makeViewModel(url: "https://example.com")).visible)
        XCTAssertFalse(Self.defaultStyle(Self.makeViewModel(url: "https://example.com", visible: false)).visible)
    }

    // MARK: - Overrides

    func testStyleAppliesSelectedVisibilityOverride() {
        let viewModel = Self.makeViewModel(
            url: "https://example.com",
            visible: false,
            overrides: [
                .init(conditions: [.selected], properties: .init(visible: true))
            ]
        )

        // Default state keeps the base (hidden) value.
        XCTAssertFalse(Self.defaultStyle(viewModel).visible)

        // Selected state applies the override.
        XCTAssertTrue(Self.defaultStyle(viewModel, state: .selected).visible)
    }

    func testStyleAppliesSizeClassVisibilityOverride() {
        let viewModel = Self.makeViewModel(
            url: "https://example.com",
            visible: true,
            overrides: [
                .init(conditions: [.expanded], properties: .init(visible: false))
            ]
        )

        // Compact keeps the base (visible) value; expanded hides it.
        XCTAssertTrue(Self.defaultStyle(viewModel, condition: .compact).visible)
        XCTAssertFalse(Self.defaultStyle(viewModel, condition: .expanded).visible)
    }

    func testStyleDoesNotOverrideURLOrSize() {
        // Only `visible` is overridable: the resolved URL and size always come from the base component,
        // regardless of the presentation context.
        let viewModel = Self.makeViewModel(
            url: "https://example.com/base",
            size: .init(width: .fill, height: .fit(nil)),
            overrides: [
                .init(conditions: [.expanded], properties: .init(visible: false))
            ]
        )

        let expanded = Self.defaultStyle(viewModel, condition: .expanded)
        XCTAssertEqual(expanded.urlString, "https://example.com/base")
        XCTAssertEqual(expanded.size.width, .fill)
        XCTAssertEqual(expanded.size.height, .fit(nil))
    }

    func testViewModelEqualityAndHashingConsidersComponent() {
        let base = Self.makeViewModel(url: "https://example.com/path")

        // Equal inputs produce equal (and identically hashing) view models.
        let same = Self.makeViewModel(url: "https://example.com/path")
        XCTAssertEqual(base, same)
        XCTAssertEqual(base.hashValue, same.hashValue)

        // Any component difference breaks equality.
        XCTAssertNotEqual(base, Self.makeViewModel(id: "other", url: "https://example.com/path"))
        XCTAssertNotEqual(base, Self.makeViewModel(url: "https://example.com/other"))
        XCTAssertNotEqual(base, Self.makeViewModel(url: "https://example.com/path", visible: false))
        XCTAssertNotEqual(
            base,
            Self.makeViewModel(url: "https://example.com/path", size: .init(width: .fixed(320), height: .fit(nil)))
        )
        XCTAssertNotEqual(
            base,
            Self.makeViewModel(
                url: "https://example.com/path",
                overrides: [.init(conditions: [.selected], properties: .init(visible: false))]
            )
        )
    }

    // MARK: - Rule discarding

    func testDiscardRulesStripsRuleBasedWebViewOverrides() {
        // Rule-based overrides (here a selected-package rule) apply normally, but are stripped once the
        // paywall discards rules because an unsupported condition was found somewhere.
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialWebViewComponent> = [
            .init(
                extendedConditions: [.selectedPackage(operator: .in, packages: ["monthly"])],
                properties: .init(visible: false)
            )
        ]

        func visibleWhenMonthlySelected(discardRules: Bool) -> Bool {
            Self.makeViewModel(
                url: "https://example.com",
                visible: true,
                overrides: overrides,
                discardRules: discardRules
            ).style(
                state: .default,
                condition: .compact,
                isEligibleForIntroOffer: false,
                isEligibleForPromoOffer: false,
                selectedPackageId: "monthly",
                customVariables: [:]
            ).visible
        }

        // Honored: selecting the package hides the web view.
        XCTAssertFalse(visibleWhenMonthlySelected(discardRules: false))
        // Discarded: the rule is stripped, so the base (visible) value stands.
        XCTAssertTrue(visibleWhenMonthlySelected(discardRules: true))
    }

    // MARK: - Helpers

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

    /// Decodes a component from `json` and runs it through the real `ViewModelFactory`, exercising the
    /// full decode-to-view-model seam.
    private static func viewModel(decodedFrom json: String) throws -> PaywallComponentViewModel {
        let component = try JSONDecoder.default.decode(PaywallComponent.self, from: Data(json.utf8))

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

        return try ViewModelFactory().toViewModel(
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
    }

    private static func makeViewModel(
        id: String = "web",
        url: String,
        visible: Bool? = nil,
        size: PaywallComponent.Size = .init(width: .fill, height: .fit(nil)),
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialWebViewComponent>? = nil,
        discardRules: Bool = false
    ) -> WebViewComponentViewModel {
        WebViewComponentViewModel(
            component: .init(
                id: id,
                visible: visible,
                protocolVersion: 1,
                url: url,
                size: size,
                overrides: overrides
            ),
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
            discardRules: discardRules
        )
    }

    private static func defaultStyle(
        _ viewModel: WebViewComponentViewModel,
        state: ComponentViewState = .default,
        condition: ScreenCondition = .compact
    ) -> WebViewComponentStyle {
        viewModel.style(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            selectedPackageId: nil,
            customVariables: [:]
        )
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
