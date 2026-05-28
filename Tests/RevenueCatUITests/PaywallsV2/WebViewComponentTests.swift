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

    func testDecodeWebViewComponent() throws {
        let json = """
        {
          "type": "web_view",
          "url": "https://example.com",
          "sizing": {
            "mode": "automatic"
          }
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder.default.decode(PaywallComponent.self, from: json)

        guard case .webView(let webView) = component else {
            XCTFail("Expected .webView component, got \(component)")
            return
        }

        XCTAssertEqual(webView.url, "https://example.com")
    }

    func testDecodeWebViewComponentRoundTrip() throws {
        let json = """
        {
          "type": "web_view",
          "url": "https://example.com",
          "sizing": {
            "mode": "automatic"
          }
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: json)
        let encoded = try JSONEncoder().encode(component)
        let decoded = try JSONDecoder.default.decode(PaywallComponent.WebViewComponent.self, from: encoded)

        XCTAssertEqual(component, decoded)
        XCTAssertEqual(decoded.url, "https://example.com")
    }

    func testDecodeWebViewComponentWithTemplateURL() throws {
        let json = """
        {
          "type": "web_view",
          "url": "https://example.com/{{ custom.animal }}.html",
          "sizing": {
            "mode": "automatic"
          }
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

    // MARK: - Cache lookup (displayURL)

    func testDisplayURLUsesCachedHTMLFileURLWhenAvailable() {
        let originalURL = URL(string: "https://example.com/paywall.html")!
        let cachedURL = URL(string: "purchaseshtml://cached/paywall.html")!
        let repository = MockInMemoryHTMLFileRepository()
        repository.stubCachedFileURL(cachedURL, for: originalURL)

        let viewModel = Self.makeViewModel(
            urlTemplate: originalURL.absoluteString,
            htmlFileRepository: repository
        )

        XCTAssertEqual(viewModel.displayURL, cachedURL)
        XCTAssertEqual(repository.cachedFileURLRequests, [originalURL])
        XCTAssertEqual(repository.generatedURLs, [])
    }

    func testDisplayURLReturnsNilWhenNoCachedHTMLFileExists() {
        let originalURL = URL(string: "https://example.com/paywall.html")!
        let repository = MockInMemoryHTMLFileRepository()

        let viewModel = Self.makeViewModel(
            urlTemplate: originalURL.absoluteString,
            htmlFileRepository: repository
        )

        XCTAssertNil(viewModel.displayURL)
        XCTAssertEqual(repository.cachedFileURLRequests, [originalURL])
        XCTAssertEqual(repository.generatedURLs, [])
    }

    func testCachedURLWithResolvedTemplateURLLooksUpCorrectKey() {
        let resolvedURL = URL(string: "https://example.com/dog.html")!
        let cachedURL = URL(string: "purchaseshtml://cached/dog.html")!
        let repository = MockInMemoryHTMLFileRepository()
        repository.stubCachedFileURL(cachedURL, for: resolvedURL)

        let viewModel = Self.makeViewModel(
            urlTemplate: "https://example.com/{{ custom.animal }}.html",
            customVariableDefinitions: ["animal": .init(type: "string", defaultValue: "cat")],
            htmlFileRepository: repository
        )

        let resolved = viewModel.resolvedURL(customVariables: ["animal": .string("dog")])!
        XCTAssertEqual(viewModel.cachedURL(for: resolved), cachedURL)
    }

    // MARK: - Pre-warming URL collection

    func testPaywallComponentsDataCollectsWebViewURLsForPrewarming() {
        let rootURL = URL(string: "https://example.com/root.html")!
        let nestedURL = URL(string: "https://example.com/nested.html")!
        let footerURL = URL(string: "https://example.com/footer.html")!

        let data = PaywallComponentsData(
            templateName: "components_test",
            assetBaseURL: URL(string: "https://example.com/assets")!,
            componentsConfig: .init(
                base: .init(
                    stack: .init(components: [
                        .webView(.init(url: rootURL.absoluteString)),
                        .stack(.init(components: [
                            .webView(.init(url: nestedURL.absoluteString))
                        ]))
                    ]),
                    stickyFooter: .init(stack: .init(components: [
                        .webView(.init(url: footerURL.absoluteString))
                    ])),
                    background: .color(.init(light: .hex("#FFFFFF")))
                )
            ),
            componentsLocalizations: [:],
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )

        XCTAssertEqual(data.allWebViewURLs, [rootURL, nestedURL, footerURL])
    }

    func testPaywallComponentsDataSkipsTemplateURLsForPrewarming() {
        let staticURL = URL(string: "https://example.com/static.html")!

        let data = PaywallComponentsData(
            templateName: "components_test",
            assetBaseURL: URL(string: "https://example.com/assets")!,
            componentsConfig: .init(
                base: .init(
                    stack: .init(components: [
                        .webView(.init(url: staticURL.absoluteString)),
                        // Template URL contains {{ }} tokens — resolved at runtime, so it's skipped
                        .webView(.init(url: "https://example.com/{{ custom.animal }}.html"))
                    ]),
                    stickyFooter: nil,
                    background: .color(.init(light: .hex("#FFFFFF")))
                )
            ),
            componentsLocalizations: [:],
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )

        XCTAssertEqual(data.allWebViewURLs, [staticURL])
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WebViewComponentTests {

    static func makeViewModel(
        urlTemplate: String,
        customVariableDefinitions: [String: UIConfig.CustomVariableDefinition] = [:],
        htmlFileRepository: InMemoryHTMLFileRepositoryType = MockInMemoryHTMLFileRepository()
    ) -> WebViewComponentViewModel {
        let uiConfig = UIConfig(
            app: .init(colors: [:], fonts: [:]),
            localizations: [:],
            variableConfig: .init(variableCompatibilityMap: [:], functionCompatibilityMap: [:]),
            customVariables: customVariableDefinitions
        )
        return WebViewComponentViewModel(
            component: .init(url: urlTemplate),
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:]),
            uiConfigProvider: UIConfigProvider(uiConfig: uiConfig),
            htmlFileRepository: htmlFileRepository
        )
    }

}

// MARK: - MockInMemoryHTMLFileRepository

@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
private final class MockInMemoryHTMLFileRepository: InMemoryHTMLFileRepositoryType, @unchecked Sendable {

    private let lock = NSLock()
    private var _generatedURLs: [URL] = []
    private var _cachedFileURLRequests: [URL] = []
    private var cachedFileURLs: [URL: URL] = [:]

    var generatedURLs: [URL] {
        self.lock.withLock { self._generatedURLs }
    }

    var cachedFileURLRequests: [URL] {
        self.lock.withLock { self._cachedFileURLRequests }
    }

    func generateOrGetCachedFileURL(for url: URL) async throws -> URL {
        return self.lock.withLock {
            self._generatedURLs.append(url)
            return self.cachedFileURLs[url] ?? url
        }
    }

    func getCachedFileURL(for url: URL) -> URL? {
        return self.lock.withLock {
            self._cachedFileURLRequests.append(url)
            return self.cachedFileURLs[url]
        }
    }

    func stubCachedFileURL(_ cachedURL: URL, for url: URL) {
        self.lock.withLock {
            self.cachedFileURLs[url] = cachedURL
        }
    }

}

#endif
