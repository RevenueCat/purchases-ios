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
@testable import RevenueCat
import XCTest

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
final class PaywallCacheWarmingTests: TestCase {

    private var eligibilityChecker: MockTrialOrIntroPriceEligibilityChecker!
    private var imageFetcher: MockPaywallImageFetcher!
    private var cache: PaywallCacheWarmingType!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.eligibilityChecker = .init()
        self.imageFetcher = .init()
        self.cache = PaywallCacheWarming(introEligibiltyChecker: self.eligibilityChecker,
                                         imageFetcher: self.imageFetcher)
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

    func testWarmsUpImagesForCurrentOffering() async throws {
        let offerings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: try Self.loadPaywall("PaywallData-Sample1"),
                products: []
            ),
            Self.createOffering(
                identifier: "another offering",
                paywall: try Self.loadPaywall("PaywallData-missing_current_locale"),
                products: []
            )
        ])

        let expectedURLs: Set<String> = [
            "https://rc-paywalls.s3.amazonaws.com/header.heic",
            "https://rc-paywalls.s3.amazonaws.com/background.jpg",
            "https://rc-paywalls.s3.amazonaws.com/icon.heic"
        ]

        await self.cache.warmUpPaywallImagesCache(offerings: offerings)

        expect(self.imageFetcher.images) == expectedURLs
        expect(self.imageFetcher.imageDownloadRequestCount.value) == expectedURLs.count
    }

    func testWarmsUpImagesByTier() async throws {
        let offerings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: try Self.loadPaywall("PaywallData-multitier1"),
                products: []
            )
        ])

        let expectedURLs: Set<String> = [
            "https://rc-paywalls.s3.amazonaws.com/954459_1703109702.png",
            "https://rc-paywalls.s3.amazonaws.com/header.heic"
        ]

        await self.cache.warmUpPaywallImagesCache(offerings: offerings)

        expect(self.imageFetcher.images) == expectedURLs
        expect(self.imageFetcher.imageDownloadRequestCount.value) == expectedURLs.count
    }

    func testOnlyWarmsUpImagesOnce() async throws {
        let paywall = try Self.loadPaywall("PaywallData-Sample1")
        let offerings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: paywall,
                products: []
            )
        ])

        await self.cache.warmUpPaywallImagesCache(offerings: offerings)
        await self.cache.warmUpPaywallImagesCache(offerings: offerings)

        expect(self.imageFetcher.imageDownloadRequestCount.value) == 3
    }

    func testDownloadFont_PerformsExpectedActions() async throws {
        let mockSession = MockSession()
        let mockFileManager = MockFileManager()
        let mockRegistrar = MockRegistrar()

        let sut = DefaultPaywallFontsManager(
            fileManager: mockFileManager,
            session: mockSession,
            registrar: mockRegistrar
        )

        let url = URL(string: "https://example.com/font.ttf")!
        mockFileManager.fileExistsAtPath = false

        try await sut.installFont(from: url, hash: "abc123")

        expect(mockSession.didCallDataFrom).to(beTrue())
        expect(mockFileManager.didWriteData).to(beTrue())
        expect(mockRegistrar.didRegister).to(beTrue())
    }

    func testDownloadFont_SkipsCopyIfFileExists() async throws {
        let mockSession = MockSession()
        let mockFileManager = MockFileManager()
        mockFileManager.fileExistsAtPath = true
        let mockRegistrar = MockRegistrar()

        let sut = DefaultPaywallFontsManager(
            fileManager: mockFileManager,
            session: mockSession,
            registrar: mockRegistrar
        )

        let url = URL(string: "https://example.com/font.ttf")!
        try await sut.installFont(from: url, hash: "abc123")

        expect(mockSession.didCallDataFrom).to(beFalse())
        expect(mockFileManager.didWriteData).to(beFalse())
        expect(mockRegistrar.didRegister).to(beTrue())
    }

    func testDownloadFont_ThrowsHashValidationError() async {
        let mockSession = MockSession()
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
        do {
            try await sut.installFont(from: url, hash: "expectedhash")
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

    func testDownloadFont_ThrowsRegistrationError() async {
        let validData = Data("valid data".utf8)
        let mockSession = MockSession()
        mockSession.dataFromURL = validData

        let mockFileManager = MockFileManager()
        mockFileManager.fileExistsAtPath = false

        let mockRegistrar = MockRegistrar()
        mockRegistrar.shouldThrow = true

        let sut = DefaultPaywallFontsManager(
            fileManager: mockFileManager,
            session: mockSession,
            registrar: mockRegistrar
        )

        let url = URL(string: "https://example.com/font.ttf")!
        do {
            try await sut.installFont(from: url, hash: validData.md5String)
            fail("Expected to throw registrationError")
        } catch let error as DefaultPaywallFontsManager.FontsManagerError {
            guard case .registrationError(let innerError) = error else {
                fail("Expected registrationError, got \(error)")
                return
            }
            expect(innerError?.localizedDescription).to(equal("registration failed"))
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testInstallFont_DownloadsOnce_RegistersTwice() async throws {
        let fontData = Data("valid font".utf8)
        let hash = fontData.md5String

        let session = MockSession()
        session.dataFromURL = fontData

        let fileManager = MockFileManager()
        fileManager.fileExistsAtPath = false

        let registrar = MockRegistrar()

        let sut = DefaultPaywallFontsManager(
            fileManager: fileManager,
            session: session,
            registrar: registrar
        )

        let url = URL(string: "https://example.com/font.ttf")!

        // First install: should download, write, register
        try await sut.installFont(from: url, hash: hash)

        // Second install: should skip download/write, but still register
        try await sut.installFont(from: url, hash: hash)

        expect(session.dataFromURLCallCount).to(equal(1))
        expect(registrar.registerFontCallCount).to(equal(2))
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private extension PaywallCacheWarmingTests {

    static func createOffering(
        identifier: String,
        paywall: PaywallData?,
        products: [(PackageType, String)]
    ) throws -> Offering {
        return Offering(
            identifier: identifier,
            serverDescription: identifier,
            paywall: paywall,
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
            response: offeringsResponse
        )
    }

    static func loadPaywall(_ name: String) throws -> PaywallData {
        let paywallURL = try XCTUnwrap(Self.bundle.url(forResource: name,
                                                       withExtension: "json",
                                                       subdirectory: "Fixtures"))

        return try PaywallData.create(with: XCTUnwrap(Data(contentsOf: paywallURL)))
    }

    static let bundle = Bundle(for: PaywallCacheWarmingTests.self)
    static let offeringIdentifier = "offering"

}

private final class MockPaywallImageFetcher: PaywallImageFetcherType {

    let downloadedImages: Atomic<Set<URL>> = .init([])
    let imageDownloadRequestCount: Atomic<Int> = .init(0)

    var images: Set<String> {
        return Set(self.downloadedImages.value.map(\.absoluteString))
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func downloadImage(_ url: URL) async throws {
        self.downloadedImages.modify { $0.insert(url) }
        self.imageDownloadRequestCount.modify { $0 += 1 }
    }

}

private final class MockSession: FontDownloadSession {

    var didCallDataFrom = false
    var dataFromURL: Data?
    var dataFromURLCallCount = 0
    func data(from url: URL) async throws -> (Data, URLResponse) {
        didCallDataFrom = true
        dataFromURLCallCount += 1
        return (dataFromURL ?? Data(), URLResponse())
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
            throw NSError(domain: "mock", code: 42, userInfo: [NSLocalizedDescriptionKey: "registration failed"])
        }
        didRegister = true
    }
}
