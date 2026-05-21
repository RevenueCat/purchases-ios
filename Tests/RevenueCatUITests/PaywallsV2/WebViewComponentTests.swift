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

        XCTAssertEqual(webView.url.absoluteString, "https://example.com")
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
        XCTAssertEqual(decoded.url.absoluteString, "https://example.com")
    }

    func testDisplayURLUsesCachedHTMLFileURLWhenAvailable() async {
        let originalURL = URL(string: "https://example.com/paywall.html")!
        let cachedURL = URL(string: "purchaseshtml://cached/paywall.html")!
        let repository = MockInMemoryHTMLFileRepository()
        await repository.stubCachedFileURL(cachedURL, for: originalURL)

        let viewModel = WebViewComponentViewModel(
            component: .init(url: originalURL),
            htmlFileRepository: repository
        )

        let displayURL = await viewModel.displayURL()
        let cachedFileURLRequests = await repository.cachedFileURLRequests
        let generatedURLs = await repository.generatedURLs

        XCTAssertEqual(displayURL, cachedURL)
        XCTAssertEqual(cachedFileURLRequests, [originalURL])
        XCTAssertEqual(generatedURLs, [])
    }

    func testDisplayURLFallsBackToOriginalURLWhenNoCachedHTMLFileExists() async {
        let originalURL = URL(string: "https://example.com/paywall.html")!
        let repository = MockInMemoryHTMLFileRepository()
        let viewModel = WebViewComponentViewModel(
            component: .init(url: originalURL),
            htmlFileRepository: repository
        )

        let displayURL = await viewModel.displayURL()
        let cachedFileURLRequests = await repository.cachedFileURLRequests
        let generatedURLs = await repository.generatedURLs

        XCTAssertEqual(displayURL, originalURL)
        XCTAssertEqual(cachedFileURLRequests, [originalURL])
        XCTAssertEqual(generatedURLs, [])
    }

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
                        .webView(.init(url: rootURL)),
                        .stack(.init(components: [
                            .webView(.init(url: nestedURL))
                        ]))
                    ]),
                    stickyFooter: .init(stack: .init(components: [
                        .webView(.init(url: footerURL))
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

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
private final actor MockInMemoryHTMLFileRepository: InMemoryHTMLFileRepositoryType {

    private(set) var generatedURLs: [URL] = []
    private(set) var cachedFileURLRequests: [URL] = []
    private var cachedFileURLs: [URL: URL] = [:]

    func generateOrGetCachedFileURL(for url: URL) async throws -> URL {
        self.generatedURLs.append(url)
        return self.cachedFileURLs[url] ?? url
    }

    func getCachedFileURL(for url: URL) async -> URL? {
        self.cachedFileURLRequests.append(url)
        return self.cachedFileURLs[url]
    }

    func stubCachedFileURL(_ cachedURL: URL, for url: URL) {
        self.cachedFileURLs[url] = cachedURL
    }

}

#endif
