//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InMemoryHTMLFileRepositoryTests.swift
//
//  Created by RevenueCat.
//

@_spi(Internal) @testable import RevenueCat
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
final class InMemoryHTMLFileRepositoryTests: TestCase {

    func test_generateOrGetCachedFileURL_rejectsNonHTTPSURLs() async throws {
        let repository = InMemoryHTMLFileRepository(networkService: MockHTMLNetworkService())

        do {
            _ = try await repository.generateOrGetCachedFileURL(
                for: URL(string: "http://example.com/index.html").unsafelyUnwrapped
            )
            XCTFail("Expected non-HTTPS URLs to be rejected")
        } catch InMemoryHTMLFileRepository.Error.invalidURLScheme {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_generateOrGetCachedFileURL_rewritesHTMLAndCSSAssetsToPurchasesHTMLURLs() async throws {
        let networkService = MockHTMLNetworkService()
        let htmlURL = Self.htmlURL("index")
        let stylesheetURL = URL(string: "https://example.com/style.css").unsafelyUnwrapped
        let scriptURL = URL(string: "https://cdn.example.com/app.js").unsafelyUnwrapped
        let imageURL = URL(string: "https://example.com/pages/images/logo.png").unsafelyUnwrapped
        let backgroundURL = URL(string: "https://example.com/bg.png").unsafelyUnwrapped
        let importedStylesheetURL = URL(string: "https://example.com/fonts.css").unsafelyUnwrapped

        networkService.stub(
            url: htmlURL,
            data: """
            <html>
              <head>
                <link rel="stylesheet" href="/style.css">
                <script src="https://cdn.example.com/app.js"></script>
              </head>
              <body>
                <img src="images/logo.png">
              </body>
            </html>
            """
        )
        networkService.stub(
            url: stylesheetURL,
            data: """
            @import "fonts.css";
            body { background-image: url('/bg.png'); }
            """
        )
        networkService.stub(url: scriptURL, data: "console.log('cached');")
        networkService.stub(url: imageURL, data: "image-data")
        networkService.stub(url: backgroundURL, data: "background-data")
        networkService.stub(url: importedStylesheetURL, data: "body { color: red; }")

        let repository = InMemoryHTMLFileRepository(networkService: networkService)
        let cachedURL = try await repository.generateOrGetCachedFileURL(for: htmlURL)
        let html = try await Self.string(from: cachedURL)

        XCTAssertEqual(cachedURL.scheme, "purchaseshtml")
        XCTAssertFalse(html.contains(#"href="/style.css""#))
        XCTAssertFalse(html.contains("https://cdn.example.com/app.js"))
        XCTAssertFalse(html.contains(#"src="images/logo.png""#))

        let cachedStylesheetURL = try XCTUnwrap(Self.attribute("href", inFirst: "link", html: html))
        let cachedScriptURL = try XCTUnwrap(Self.attribute("src", inFirst: "script", html: html))
        let cachedImageURL = try XCTUnwrap(Self.attribute("src", inFirst: "img", html: html))

        XCTAssertEqual(cachedStylesheetURL.scheme, "purchaseshtml")
        XCTAssertEqual(cachedScriptURL.scheme, "purchaseshtml")
        XCTAssertEqual(cachedImageURL.scheme, "purchaseshtml")

        let css = try await Self.string(from: cachedStylesheetURL)
        XCTAssertFalse(css.contains("url('/bg.png')"))
        XCTAssertFalse(css.contains(#"@import "fonts.css""#))
        XCTAssertEqual(Self.purchasesHTMLURLCount(in: css), 2)

        XCTAssertEqual(
            Set(networkService.invocations),
            [
                htmlURL,
                stylesheetURL,
                scriptURL,
                imageURL,
                backgroundURL,
                importedStylesheetURL
            ]
        )
    }

    func test_generateOrGetCachedFileURL_leavesFailedAssetsUnchangedAndSucceeds() async throws {
        let networkService = MockHTMLNetworkService()
        let htmlURL = Self.htmlURL("fallback")
        let cachedImageURL = URL(string: "https://example.com/pages/cached.png").unsafelyUnwrapped
        let missingImageURL = URL(string: "https://example.com/pages/missing.png").unsafelyUnwrapped

        networkService.stub(
            url: htmlURL,
            data: """
            <html>
              <body>
                <img src="cached.png">
                <img src="missing.png">
              </body>
            </html>
            """
        )
        networkService.stub(url: cachedImageURL, data: "image-data")
        networkService.stub(url: missingImageURL, error: SampleError())

        let repository = InMemoryHTMLFileRepository(networkService: networkService)
        let cachedURL = try await repository.generateOrGetCachedFileURL(for: htmlURL)
        let html = try await Self.string(from: cachedURL)

        XCTAssertTrue(html.contains("purchaseshtml:"))
        XCTAssertTrue(html.contains(#"src="missing.png""#))
    }

    func test_generateOrGetCachedFileURL_rewritesSrcsetAndDoesNotRewriteDataSrc() async throws {
        let networkService = MockHTMLNetworkService()
        let htmlURL = Self.htmlURL("srcset")
        let dataSourceURL = URL(string: "https://example.com/pages/lazy.png").unsafelyUnwrapped
        let imageURL = URL(string: "https://example.com/pages/real.png").unsafelyUnwrapped
        let smallImageURL = URL(string: "https://example.com/pages/small.png").unsafelyUnwrapped
        let missingImageURL = URL(string: "https://example.com/pages/missing-srcset.png").unsafelyUnwrapped

        networkService.stub(
            url: htmlURL,
            data: """
            <html>
              <body>
                <img data-src="lazy.png" src="real.png" srcset="small.png 1x, missing-srcset.png 2x">
              </body>
            </html>
            """
        )
        networkService.stub(url: dataSourceURL, error: SampleError())
        networkService.stub(url: imageURL, data: "real-image")
        networkService.stub(url: smallImageURL, data: "small-image")
        networkService.stub(url: missingImageURL, error: SampleError())

        let repository = InMemoryHTMLFileRepository(networkService: networkService)
        let cachedURL = try await repository.generateOrGetCachedFileURL(for: htmlURL)
        let html = try await Self.string(from: cachedURL)

        XCTAssertTrue(html.contains(#"data-src="lazy.png""#))
        XCTAssertFalse(html.contains(#"src="real.png""#))
        XCTAssertFalse(html.contains(#"srcset="small.png 1x"#))
        XCTAssertTrue(html.contains("missing-srcset.png 2x"))
        XCTAssertFalse(networkService.invocations.contains(dataSourceURL))
    }

    func test_generateOrGetCachedFileURL_rewritesImportURLAsStylesheet() async throws {
        let networkService = MockHTMLNetworkService()
        let htmlURL = Self.htmlURL("import-url")
        let stylesheetURL = URL(string: "https://example.com/style-with-import.css").unsafelyUnwrapped
        let importedStylesheetURL = URL(string: "https://example.com/theme.css").unsafelyUnwrapped
        let nestedImageURL = URL(string: "https://example.com/nested.png").unsafelyUnwrapped

        networkService.stub(
            url: htmlURL,
            data: #"<html><head><link rel="stylesheet" href="/style-with-import.css"></head></html>"#
        )
        networkService.stub(url: stylesheetURL, data: #"@import url("theme.css");"#)
        networkService.stub(url: importedStylesheetURL, data: #"body { background: url("nested.png"); }"#)
        networkService.stub(url: nestedImageURL, data: "nested-image")

        let repository = InMemoryHTMLFileRepository(networkService: networkService)
        let cachedURL = try await repository.generateOrGetCachedFileURL(for: htmlURL)
        let html = try await Self.string(from: cachedURL)
        let cachedStylesheetURL = try XCTUnwrap(Self.attribute("href", inFirst: "link", html: html))
        let css = try await Self.string(from: cachedStylesheetURL)

        XCTAssertFalse(css.contains(#"url("theme.css")"#))
        XCTAssertTrue(Set(networkService.invocations).contains(nestedImageURL))
    }

    func test_generateOrGetCachedFileURL_returnsCachedURLWithoutRecalculating() async throws {
        let networkService = MockHTMLNetworkService()
        let htmlURL = Self.htmlURL("dedupe")
        networkService.stub(url: htmlURL, data: "<html><body>Hello</body></html>")

        let repository = InMemoryHTMLFileRepository(networkService: networkService)
        let firstURL = try await repository.generateOrGetCachedFileURL(for: htmlURL)
        let secondURL = try await repository.generateOrGetCachedFileURL(for: htmlURL)

        XCTAssertEqual(firstURL, secondURL)
        XCTAssertEqual(networkService.invocations, [htmlURL])
    }

    private static func htmlURL(_ name: String) -> URL {
        return URL(string: "https://example.com/pages/\(name).html").unsafelyUnwrapped
    }

    private static func string(from url: URL) async throws -> String {
        let configuration = InMemoryHTMLFileRepository.makeURLSessionConfiguration()
        let session = URLSession(configuration: configuration)
        let (data, _) = try await session.data(from: url)

        return try XCTUnwrap(String(data: data, encoding: .utf8))
    }

    private static func attribute(_ attribute: String, inFirst tag: String, html: String) -> URL? {
        guard let tagRange = html.range(of: "<\(tag)", options: .caseInsensitive),
              let tagEndRange = html[tagRange.lowerBound...].range(of: ">") else {
            return nil
        }

        let tagText = String(html[tagRange.lowerBound...tagEndRange.lowerBound])
        guard let attributeRange = tagText.range(of: "\(attribute)=", options: .caseInsensitive) else {
            return nil
        }

        let valueStart = tagText.index(attributeRange.upperBound, offsetBy: 1)
        let value = tagText[valueStart...].prefix { $0 != "\"" }

        return URL(string: String(value))
    }

    private static func purchasesHTMLURLCount(in string: String) -> Int {
        return string.components(separatedBy: "purchaseshtml:").count - 1
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
private final class MockHTMLNetworkService: SimpleNetworkServiceType, @unchecked Sendable {

    private let lock = NSLock()
    private var responses: [URL: Result<Data, Swift.Error>] = [:]
    private(set) var invocations: [URL] = []

    func bytes(from url: URL) async throws -> AsyncThrowingStream<UInt8, Swift.Error> {
        let response = try self.lock.withLock {
            self.invocations.append(url)
            return try XCTUnwrap(self.responses[url])
        }

        switch response {
        case .success(let data):
            return AsyncThrowingStream { continuation in
                for byte in data {
                    continuation.yield(byte)
                }
                continuation.finish()
            }
        case .failure(let error):
            throw error
        }
    }

    func stub(url: URL, data: String) {
        self.stub(url: url, data: data.asData)
    }

    func stub(url: URL, data: Data) {
        self.lock.withLock {
            self.responses[url] = .success(data)
        }
    }

    func stub(url: URL, error: Swift.Error) {
        self.lock.withLock {
            self.responses[url] = .failure(error)
        }
    }

}

private struct SampleError: Swift.Error {}
