//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallCacheWarmingTests.swift
//
//  Created by Nacho Soto on 8/7/23.

import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
final class PaywallCacheWarmingTests: TestCase {

    private var eligibilityChecker: MockTrialOrIntroPriceEligibilityChecker!
    private var cache: PaywallCacheWarmingType!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.eligibilityChecker = .init()
        self.cache = PaywallCacheWarming(introEligibiltyChecker: self.eligibilityChecker)
    }

    func testOfferingsWithNoPaywallsDoesNotCheckEligibility() async throws {
        await self.cache.warmUpEligibilityCache(
            offerings: try Self.createOfferings([
                Self.createOffering(
                    identifier: Self.offeringIdentifier,
                    paywall: nil,
                    products: [
                        (.monthly, "product_1")
                    ]
                )
            ])
        )

        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore) == false
    }

    func testWarmsUpEligibilityCacheForCurrentOffering() async throws {
        let paywall = try Self.loadPaywall("PaywallData-Sample1")
        let offerings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: paywall,
                products: [
                    (.monthly, "product_1"),
                    (.weekly, "product_2")
                ]
            ),
            Self.createOffering(
                identifier: "offering_2",
                paywall: paywall,
                products: [
                    (.annual, "product_3")
                ]
            )
        ])

        // Paywall filters packages so only `monthly` and `annual` is used.
        // `product_3` is not part of the current offering, so that is ignored too.
        let expectedProducts: Set<String> = ["product_1"]

        await self.cache.warmUpEligibilityCache(offerings: offerings)

        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore) == true
        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 1

        expect(
            self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParameters
        ) == expectedProducts

        self.logger.verifyMessageWasLogged(
            Strings.paywalls.warming_up_eligibility_cache(products: expectedProducts),
            level: .debug
        )
    }

    func testOnlyWarmsUpEligibilityCacheOnce() async throws {
        let paywall = try Self.loadPaywall("PaywallData-Sample1")
        let offerings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: paywall,
                products: [
                    (.monthly, "product_1")
                ]
            )
        ])

        await self.cache.warmUpEligibilityCache(offerings: offerings)
        await self.cache.warmUpEligibilityCache(offerings: offerings)

        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore) == true
        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 1

        self.logger.verifyMessageWasLogged(
            Strings.paywalls.warming_up_eligibility_cache(products: ["product_1"]),
            level: .debug,
            expectedCount: 1
        )
    }

#if !os(tvOS) // For Paywalls V2

    func testWarmUpPaywallImagesCacheWarmsUpWebViewHTMLFiles() async throws {
        let webViewURL = URL(string: "https://example.com/paywall.html")!
        let htmlFileRepository = MockInMemoryHTMLFileRepository()
        let paywallComponents = Offering.PaywallComponents(
            uiConfig: try Self.createUIConfig(),
            data: Self.createPaywallComponentsData(
                stack: .init(components: [.webView(.init(url: webViewURL.absoluteString))])
            )
        )

        let cache = PaywallCacheWarming(
            introEligibiltyChecker: self.eligibilityChecker,
            htmlFileRepository: htmlFileRepository
        )

        let offerings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: nil,
                paywallComponents: paywallComponents,
                products: []
            )
        ])

        await cache.warmUpPaywallImagesCache(offerings: offerings)

        let generatedURLs = await htmlFileRepository.generatedURLs
        expect(generatedURLs) == [webViewURL]
    }

    func testTriggerFontDownload_DeduplicatesConcurrentDownloads() async throws {
        let font = DownloadableFont(
            name: "MockFont",
            fontFamily: "fontFamily",
            url: URL(string: "https://example.com/font.ttf")!,
            hash: "abc123"
        )

        let fontsManager = MockFontsManager(installDelayInSeconds: 1.0)

        let cache = PaywallCacheWarming(
            introEligibiltyChecker: self.eligibilityChecker,
            fontsManager: fontsManager
        )

        // Launch two tasks installing the same font concurrently
        let fontsConfig = UIConfig.FontsConfig(
            ios: UIConfig.FontInfo(
                name: font.name,
                webFontInfo: UIConfig.WebFontInfo(url: font.url.absoluteString, hash: font.hash)
            )
        )

        async let firstCall: () = cache.triggerFontDownloadIfNeeded(fontsConfig: fontsConfig)
        async let secondCall: () = cache.triggerFontDownloadIfNeeded(fontsConfig: fontsConfig)
        _ = await (firstCall, secondCall)

        let callCount = await fontsManager.installCallCount
        XCTAssertEqual(callCount, 1, "Expected only one font installation")

        self.logger.verifyMessageWasLogged(
            PaywallsStrings.font_download_already_in_progress(name: font.name, fontURL: font.url),
            level: .debug,
            expectedCount: 1
        )
    }

#endif

    func testDownloadFont_PerformsExpectedActions() async throws {
        let mockSession = MockSession()
        mockSession.urlResponse = HTTPURLResponse(
            url: URL(string: "https://example.com/font.ttf")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        let mockFileManager = MockFileManager()
        let mockRegistrar = MockRegistrar()

        let string = "abc123"
        let data = string.data(using: .utf8)!
        mockSession.dataFromURL = data
        let hash = data.md5String

        let sut = DefaultPaywallFontsManager(
            fileManager: mockFileManager,
            session: mockSession,
            registrar: mockRegistrar
        )

        let url = URL(string: "https://example.com/font.ttf")!
        mockFileManager.fileExistsAtPath = false
        let font = DownloadableFont(name: "font-bold", fontFamily: "font", url: url, hash: hash)

        try await sut.installFont(font)

        expect(mockSession.didCallDataFrom).to(beTrue())
        expect(mockFileManager.didWriteData).to(beTrue())
        expect(mockRegistrar.didRegister).to(beTrue())
    }

    func testDownloadFont_ThrowsHashValidationError() async {
        let mockSession = MockSession()
        mockSession.urlResponse = HTTPURLResponse(
            url: URL(string: "https://example.com/font.ttf")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        mockSession.dataFromURL = Data("bad font".utf8)

        let mockFileManager = MockFileManager()
        mockFileManager.fileExistsAtPath = false

        let mockRegistrar = MockRegistrar()

        let sut = DefaultPaywallFontsManager(
            fileManager: mockFileManager,
            session: mockSession,
            registrar: mockRegistrar
        )

        let url = URL(string: "https://example.com/font.ttf")!
        let font = DownloadableFont(name: "font-bold", fontFamily: "font", url: url, hash: "expectedhash")
        do {
            try await sut.installFont(font)
            fail("Expected to throw hashValidationError")
        } catch let error as DefaultPaywallFontsManager.FontsManagerError {
            guard case .hashValidationError(let expected, let actual) = error else {
                fail("Expected hashValidationError, got \(error)")
                return
            }
            expect(expected).to(equal("expectedhash"))
            expect(actual).to(equal(mockSession.dataFromURL!.md5String))
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testInstallFont_DownloadsOnce_RegistersTwice() async throws {
        let fontData = Data("valid font".utf8)
        let hash = fontData.md5String

        let session = MockSession()
        session.dataFromURL = fontData
        session.urlResponse = HTTPURLResponse(
            url: URL(string: "https://example.com/font.ttf")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let fileManager = MockFileManager()
        let registrar = MockRegistrar()

        let sut = DefaultPaywallFontsManager(
            fileManager: fileManager,
            session: session,
            registrar: registrar
        )

        let url = URL(string: "https://example.com/font.ttf")!
        let font = DownloadableFont(name: "font-bold", fontFamily: "font", url: url, hash: hash)

        // First install: should download, write, register
        try await sut.installFont(font)
        fileManager.fileExistsAtPath = true

        // Second install: should skip download/write, but still register
        try await sut.installFont(font)

        expect(session.dataFromURLCallCount).to(equal(1))
        expect(registrar.registerFontCallCount).to(equal(2))
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private extension PaywallCacheWarmingTests {

    static func createOffering(
        identifier: String,
        paywall: PaywallData?,
        paywallComponents: Offering.PaywallComponents? = nil,
        products: [(PackageType, String)]
    ) throws -> Offering {
        return Offering(
            identifier: identifier,
            serverDescription: identifier,
            paywall: paywall,
            paywallComponents: paywallComponents,
            availablePackages: products.map { packageType, productID in
                    .init(
                        identifier: Package.string(from: packageType)!,
                        packageType: packageType,
                        storeProduct: StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: productID)),
                        offeringIdentifier: identifier,
                        webCheckoutUrl: nil
                    )
            },
            webCheckoutUrl: nil
        )
    }

    static func createOfferings(_ offerings: [Offering]) throws -> Offerings {
        let offeringsURL = try XCTUnwrap(Self.bundle.url(forResource: "Offerings",
                                                         withExtension: "json",
                                                         subdirectory: "Fixtures"))

        let offeringsResponse = try OfferingsResponse.create(with: XCTUnwrap(Data(contentsOf: offeringsURL)))

        return .init(
            offerings: Set(offerings).dictionaryWithKeys(\.identifier),
            currentOfferingID: Self.offeringIdentifier,
            placements: nil,
            targeting: nil,
            contents: Offerings.Contents(response: offeringsResponse,
                                         httpResponseOriginalSource: .mainServer),
            loadedFromDiskCache: false
        )
    }

    static func loadPaywall(_ name: String) throws -> PaywallData {
        let paywallURL = try XCTUnwrap(Self.bundle.url(forResource: name,
                                                       withExtension: "json",
                                                       subdirectory: "Fixtures"))

        return try PaywallData.create(with: XCTUnwrap(Data(contentsOf: paywallURL)))
    }

    #if !os(tvOS) // For Paywalls V2

    static func createPaywallComponentsData(
        stack: PaywallComponent.StackComponent
    ) -> PaywallComponentsData {
        return PaywallComponentsData(
            templateName: "components_test",
            assetBaseURL: URL(string: "https://example.com/assets")!,
            componentsConfig: .init(
                base: .init(
                    stack: stack,
                    stickyFooter: nil,
                    background: .color(.init(light: .hex("#FFFFFF")))
                )
            ),
            componentsLocalizations: [:],
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )
    }

    static func createUIConfig() throws -> UIConfig {
        let json = """
        {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(UIConfig.self, from: data)
    }

    #endif

    static let bundle = Bundle(for: PaywallCacheWarmingTests.self)
    static let offeringIdentifier = "offering"

}

private final class MockSession: FontDownloadSession {

    var didCallDataFrom = false

    var dataFromURL: Data?
    var dataFromURLCallCount = 0

    var urlResponse: URLResponse?

    func data(from url: URL) async throws -> (Data, URLResponse) {
        didCallDataFrom = true
        dataFromURLCallCount += 1
        return (dataFromURL ?? Data(), urlResponse ?? URLResponse())
    }
}

private final class MockFileManager: FontsFileManaging {
    func cachesDirectory() throws -> URL {
        return URL(fileURLWithPath: "/tmp/RevenueCatTestSupport", isDirectory: true)
    }

    var fileExistsAtPath = false
    func fileExists(atPath path: String) -> Bool {
        fileExistsAtPath
    }

    func createDirectory(at url: URL) throws {}

    var didWriteData = false
    var didWriteDataToURL: URL?
    func write(_ data: Data, to url: URL) throws {
        didWriteData = true
        didWriteDataToURL = url
    }
}

private final class MockRegistrar: FontRegistrar {

    var didRegister = false
    var shouldThrow = false
    var registerFontCallCount = 0
    func registerFont(at url: URL) throws {
        registerFontCallCount += 1
        guard !shouldThrow else {
            throw DefaultPaywallFontsManager.FontsManagerError.registrationError(NSError(domain: "", code: 0))
        }
        didRegister = true
    }
}

final actor MockFontsManager: PaywallFontManagerType {
    private(set) var installCallCount = 0
    var installDelayInSeconds: TimeInterval = 0

    init(installDelayInSeconds: TimeInterval, fontIsAlreadyInstalled: Bool = false) {
        self.installDelayInSeconds = installDelayInSeconds
        self.fontIsAlreadyInstalled = fontIsAlreadyInstalled
    }

    let fontIsAlreadyInstalled: Bool

    nonisolated func fontIsAlreadyInstalled(fontName: String, fontFamily: String?) -> Bool {
        return self.fontIsAlreadyInstalled
    }

    func installFont(_ font: RevenueCat.DownloadableFont) async throws {
        installCallCount += 1

        let duration = UInt64(installDelayInSeconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
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
