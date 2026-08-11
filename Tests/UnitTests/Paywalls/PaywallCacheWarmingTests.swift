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

    func testOfferingsWithNoProductsDoesNotCheckEligibility() async throws {
        await self.cache.warmUpEligibilityCache(
            offerings: try Self.createOfferings([
                Self.createOffering(
                    identifier: Self.offeringIdentifier,
                    paywall: nil,
                    products: []
                )
            ])
        )

        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore) == false
    }

    func testWarmsUpEligibilityCacheForCurrentOfferingFirstThenRest() async throws {
        let offerings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: nil,
                products: [
                    (.monthly, "product_1"),
                    (.weekly, "product_2")
                ]
            ),
            Self.createOffering(
                identifier: "offering_2",
                paywall: nil,
                products: [
                    (.annual, "product_3")
                ]
            )
        ])

        let expectedCurrent: Set<String> = ["product_1", "product_2"]
        let expectedRemaining: Set<String> = ["product_3"]

        await self.cache.warmUpEligibilityCache(offerings: offerings)

        // Two staggered calls: the current offering's products first, then the rest.
        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore) == true
        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 2

        let invocations = self.eligibilityChecker
            .invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList
        expect(invocations.first) == expectedCurrent
        expect(invocations.last) == expectedRemaining

        self.logger.verifyMessageWasLogged(
            Strings.paywalls.warming_up_eligibility_cache(products: expectedCurrent),
            level: .debug
        )
        self.logger.verifyMessageWasLogged(
            Strings.paywalls.warming_up_eligibility_cache(products: expectedRemaining),
            level: .debug
        )
    }

    func testWarmsUpEligibilityCacheOnlyOnceForSameOfferings() async throws {
        let offerings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: nil,
                products: [
                    (.monthly, "product_1")
                ]
            )
        ])

        await self.cache.warmUpEligibilityCache(offerings: offerings)
        await self.cache.warmUpEligibilityCache(offerings: offerings)

        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore) == true
        // Only one call for the current offering; the second `warmUpEligibilityCache` is a no-op
        // because all products are already in the warmed set.
        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 1

        self.logger.verifyMessageWasLogged(
            Strings.paywalls.warming_up_eligibility_cache(products: ["product_1"]),
            level: .debug,
            expectedCount: 1
        )
    }

    func testWarmsUpEligibilityCacheIncrementallyForNewProducts() async throws {
        let firstOfferings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: nil,
                products: [
                    (.monthly, "product_1")
                ]
            )
        ])

        let secondOfferings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: nil,
                products: [
                    (.monthly, "product_1"),
                    (.weekly, "product_2")
                ]
            ),
            Self.createOffering(
                identifier: "offering_2",
                paywall: nil,
                products: [
                    (.annual, "product_3")
                ]
            )
        ])

        await self.cache.warmUpEligibilityCache(offerings: firstOfferings)
        await self.cache.warmUpEligibilityCache(offerings: secondOfferings)

        // The second call should only warm up products that haven't been warmed yet.
        // Current offering already had `product_1`, so only `product_2` is new there.
        // Then the remaining offering's `product_3` is warmed.
        let invocations = self.eligibilityChecker
            .invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList
        expect(invocations) == [
            ["product_1"],
            ["product_2"],
            ["product_3"]
        ]
    }

    func testClearEligibilityCacheAllowsRewarming() async throws {
        let offerings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: nil,
                products: [
                    (.monthly, "product_1")
                ]
            )
        ])

        await self.cache.warmUpEligibilityCache(offerings: offerings)
        await self.cache.clearEligibilityCache()
        await self.cache.warmUpEligibilityCache(offerings: offerings)

        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 2

        let invocations = self.eligibilityChecker
            .invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList
        expect(invocations) == [["product_1"], ["product_1"]]
    }

#if !os(tvOS) // For Paywalls V2

    func testCollectsLeafAssetsOverridesAndLocalizations() {
        let image = PaywallComponent.ImageComponent(
            source: Self.image("image", dark: true),
            overrides: [
                .init(conditions: [.compact], properties: .init(source: Self.image("image-override")))
            ]
        )
        let icon = Self.icon(
            "icon",
            overrides: [
                .init(
                    conditions: [.compact],
                    properties: .init(formats: Self.iconFormats("icon-override"))
                )
            ]
        )
        let video = PaywallComponent.VideoComponent(
            source: Self.video("video", dark: true, darkHasLowRes: false),
            fallbackSource: Self.image("video-fallback"),
            overrides: [
                .init(conditions: [.compact], properties: .init(source: Self.video("video-override")))
            ]
        )
        let validWebView = PaywallComponent.WebViewComponent(
            id: "valid",
            protocolVersion: 1,
            url: "https://example.com/cache"
        )
        let invalidWebView = PaywallComponent.WebViewComponent(
            id: "invalid",
            protocolVersion: 1,
            url: "http://example.com/not-secure"
        )
        let data = Self.data(
            components: [
                .image(image),
                .icon(icon),
                .video(video),
                .webView(validWebView),
                .webView(invalidWebView)
            ],
            localizations: [
                "en_US": ["localized-image": .image(Self.image("localized", dark: true))]
            ]
        )

        let assets = data.allCacheAssets

        XCTAssertEqual(
            Set(assets.images),
            Set(
                Self.imageMedia("image", dark: true) +
                Self.imageMedia("image-override") +
                Self.iconMedia(["icon", "icon-override"]) +
                Self.imageMedia("video-fallback") +
                Self.imageMedia("localized", dark: true)
            )
        )
        XCTAssertEqual(
            Set(assets.videos),
            Set(
                Self.videoMedia("video", dark: true, darkHasLowRes: false) +
                Self.videoMedia("video-override")
            )
        )
        XCTAssertEqual(
            assets.webBundles,
            [.init(url: Self.url("https://example.com/cache"), checksum: nil)]
        )

        XCTAssertEqual(
            Set(data.allImageURLs),
            Set(assets.images.map { ($0.lowResURL ?? $0.highResURL).url })
        )
        XCTAssertEqual(
            Set(data.allLowResVideoUrls),
            Set(assets.videos.compactMap(\.lowResURL))
        )
    }

    func testTraversesContainersAndMarksSheetAssetsForSynchronousRendering() {
        let sheetImage = Self.imageComponent("sheet")
        let sheetVideo = PaywallComponent.VideoComponent(source: Self.video("sheet-video"))
        let sheet = PaywallComponent.ButtonComponent.Sheet(
            id: "sheet",
            name: nil,
            stack: .init(components: [.image(sheetImage), .video(sheetVideo)]),
            backgroundBlur: false,
            size: nil
        )
        let sheetButton = PaywallComponent.ButtonComponent(
            action: .navigateTo(destination: .sheet(sheet: sheet)),
            stack: .init(components: [.image(Self.imageComponent("sheet-button"))])
        )
        let tabs = PaywallComponent.TabsComponent(
            control: .init(
                type: .buttons,
                stack: .init(components: [.video(.init(source: Self.video("tab-control")))])
            ),
            tabs: [
                .init(id: "tab", stack: .init(components: [.image(Self.imageComponent("tab"))]))
            ]
        )
        let countdown = PaywallComponent.CountdownComponent(
            style: .date(Date(timeIntervalSince1970: 0)),
            countFrom: .hours,
            countdownStack: .init(components: [.image(Self.imageComponent("countdown"))]),
            endStack: .init(components: [.image(Self.imageComponent("countdown-end"))]),
            fallback: .init(components: [.image(Self.imageComponent("countdown-fallback"))])
        )
        let data = Self.data(components: [
            .image(Self.imageComponent("outside")),
            .button(sheetButton),
            .stack(.init(components: [.image(Self.imageComponent("stack"))])),
            .package(.init(
                packageID: "$rc_monthly",
                isSelectedByDefault: true,
                applePromoOfferProductCode: nil,
                stack: .init(components: [.image(Self.imageComponent("package"))])
            )),
            .purchaseButton(.init(
                stack: .init(components: [.image(Self.imageComponent("purchase"))]),
                action: nil,
                method: nil,
                name: nil
            )),
            .stickyFooter(.init(
                stack: .init(components: [.image(Self.imageComponent("footer-component"))])
            )),
            .tabs(tabs),
            .tabControlButton(.init(
                tabId: "tab",
                stack: .init(components: [.image(Self.imageComponent("tab-button"))])
            )),
            .carousel(.init(pages: [
                .init(components: [.image(Self.imageComponent("carousel"))])
            ])),
            .countdown(countdown)
        ])

        let assets = data.allCacheAssets
        let synchronousImageNames = Set(
            assets.images
                .filter(\.rendersSynchronously)
                .map(\.highResURL.url.lastPathComponent)
        )

        XCTAssertEqual(synchronousImageNames, ["sheet-high.heic", "sheet-button-high.heic"])
        XCTAssertEqual(
            Set(assets.videos.filter(\.rendersSynchronously).map(\.highResURL.url.lastPathComponent)),
            ["sheet-video-high.mp4"]
        )
        XCTAssertEqual(
            Set(assets.videos.map(\.highResURL.url.lastPathComponent)),
            ["sheet-video-high.mp4", "tab-control-high.mp4"]
        )

        let expectedContainerImages = [
            "outside", "sheet", "sheet-button", "stack", "package", "purchase",
            "footer-component", "tab", "tab-button", "carousel",
            "countdown", "countdown-end", "countdown-fallback"
        ]
        XCTAssertEqual(
            Set(assets.images.map(\.highResURL.url.lastPathComponent)),
            Set(expectedContainerImages.map { "\($0)-high.heic" })
        )
        XCTAssertTrue(data.allImageURLs.contains(Self.assetURL("sheet-high.heic")))
        XCTAssertTrue(data.allImageURLs.contains(Self.assetURL("sheet-low.heic")))
    }

    func testCollectsStackRootHeaderAndFooterBackgrounds() {
        let config = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(
                components: [],
                background: .video(
                    Self.video("stack-background"),
                    Self.image("stack-fallback"),
                    true,
                    true,
                    .fit,
                    nil
                )
            ),
            header: .init(stack: .init(components: [.image(Self.imageComponent("header"))])),
            stickyFooter: .init(stack: .init(
                components: [],
                background: .image(Self.image("footer-background"), .fit, nil)
            )),
            background: .video(
                Self.video("root-background"),
                Self.image("root-fallback"),
                true,
                true,
                .fit,
                nil
            )
        )

        let assets = config.allCacheAssets

        XCTAssertEqual(
            Set(assets.images.map(\.highResURL.url.lastPathComponent)),
            [
                "stack-fallback-high.heic",
                "header-high.heic",
                "footer-background-high.heic",
                "root-fallback-high.heic"
            ]
        )
        XCTAssertEqual(
            Set(assets.videos.map(\.highResURL.url.lastPathComponent)),
            ["stack-background-high.mp4", "root-background-high.mp4"]
        )
    }

    func testWorkflowAssetPrewarmingDownloadsPreferredImagesAndLowResVideos() async {
        let fileRepository = MockCacheWarmingFileRepository()
        let cache = PaywallCacheWarming(
            introEligibiltyChecker: self.eligibilityChecker,
            fileRepository: fileRepository
        )
        let sheet = PaywallComponent.ButtonComponent.Sheet(
            id: "sheet",
            name: nil,
            stack: .init(components: [
                .image(.init(source: Self.cacheWarmingImage("sheet")))
            ]),
            backgroundBlur: false,
            size: nil
        )
        let screen = Self.workflowScreen(components: [
            .image(.init(source: Self.cacheWarmingImage("image"))),
            .button(.init(
                action: .navigateTo(destination: .sheet(sheet: sheet)),
                stack: .init(components: [])
            )),
            .video(.init(source: Self.cacheWarmingVideo("video"))),
            .video(.init(source: Self.cacheWarmingVideo("high-only", hasLowRes: false)))
        ])
        let workflow = PublishedWorkflow(
            id: "workflow",
            displayName: "Test",
            initialStepId: "step",
            singleStepFallbackId: nil,
            steps: [:],
            screens: ["screen": screen]
        )

        await cache.prewarmWorkflowAssets(workflow: workflow, uiConfig: Self.emptyUIConfig)

        let requests = await fileRepository.requests
        XCTAssertEqual(Set(requests), [
            .init(url: Self.cacheWarmingURL("image-low.heic"), checksum: nil),
            .init(url: Self.cacheWarmingURL("sheet-low.heic"), checksum: nil),
            .init(url: Self.cacheWarmingURL("sheet-high.heic"), checksum: nil),
            .init(
                url: Self.cacheWarmingURL("video-low.mp4"),
                checksum: .init(algorithm: .sha256, value: "video-low")
            )
        ])
    }

    func testOfferingsAssetPrewarmingDownloadsImagesOnlyOnce() async throws {
        let fileRepository = MockCacheWarmingFileRepository()
        let cache = PaywallCacheWarming(
            introEligibiltyChecker: self.eligibilityChecker,
            fileRepository: fileRepository
        )
        let data = Self.paywallComponentsData(components: [
            .image(.init(source: Self.cacheWarmingImage("offering-image"))),
            .video(.init(source: Self.cacheWarmingVideo("offering-video"))),
            .webView(.init(
                id: "webview",
                protocolVersion: 1,
                url: "https://example.com/cache"
            ))
        ])
        let offering = Offering(
            identifier: Self.offeringIdentifier,
            serverDescription: "Test",
            paywallComponents: .init(uiConfig: Self.emptyUIConfig, data: data),
            availablePackages: [],
            webCheckoutUrl: nil
        )
        let offerings = try Self.createOfferings([offering])

        await cache.warmUpPaywallAssetsCache(offerings: offerings)
        await cache.warmUpPaywallAssetsCache(offerings: offerings)

        let requests = await fileRepository.requests
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(Set(requests), [
            .init(url: Self.cacheWarmingURL("offering-image-low.heic"), checksum: nil)
        ])
        XCTAssertEqual(
            data.allCacheAssets.webBundles,
            [.init(url: Self.url("https://example.com/cache"), checksum: nil)]
        )
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

    func testWorkflowAssetPrewarmingAttemptsSharedFontOnlyOnce() async {
        let installCallCount = await self.workflowFontInstallCallCount(fontNames: ["MockFont", "MockFont"])
        XCTAssertEqual(installCallCount, 1)
    }

    func testWorkflowAssetPrewarmingDoesNotDeduplicateDistinctFontNames() async {
        let installCallCount = await self.workflowFontInstallCallCount(
            fontNames: ["Font Regular", "Font Bold"]
        )
        XCTAssertEqual(installCallCount, 2)
    }

    func testWorkflowAssetPrewarmingDoesNotRepeatFailedSharedFontAttempt() async {
        let installCallCount = await self.workflowFontInstallCallCount(
            fontNames: ["MockFont", "MockFont"],
            shouldFailInstallation: true
        )
        XCTAssertEqual(installCallCount, 1)
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

#if !os(tvOS)
    static func data(
        components: [PaywallComponent],
        localizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary] = [:]
    ) -> PaywallComponentsData {
        return .init(
            templateName: "test",
            assetBaseURL: Self.assetURL(""),
            componentsConfig: .init(base: .init(
                stack: .init(components: components),
                stickyFooter: nil,
                background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: localizations,
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )
    }

    static func imageComponent(_ name: String) -> PaywallComponent.ImageComponent {
        return .init(source: Self.image(name))
    }

    static func image(_ name: String, dark: Bool = false) -> PaywallComponent.ThemeImageUrls {
        return .init(
            light: Self.imageURLs(name),
            dark: dark ? Self.imageURLs("\(name)-dark") : nil
        )
    }

    static func imageURLs(_ name: String) -> PaywallComponent.ImageUrls {
        return .init(
            width: 100,
            height: 100,
            original: Self.assetURL("\(name)-original.png"),
            heic: Self.assetURL("\(name)-high.heic"),
            heicLowRes: Self.assetURL("\(name)-low.heic")
        )
    }

    static func video(
        _ name: String,
        dark: Bool = false,
        darkHasLowRes: Bool = true
    ) -> PaywallComponent.ThemeVideoUrls {
        return .init(
            light: Self.videoURLs(name),
            dark: dark ? Self.videoURLs("\(name)-dark", hasLowRes: darkHasLowRes) : nil
        )
    }

    static func videoURLs(_ name: String, hasLowRes: Bool = true) -> PaywallComponent.VideoUrls {
        return .init(
            width: 100,
            height: 100,
            url: Self.assetURL("\(name)-high.mp4"),
            checksum: .init(algorithm: .sha256, value: "\(name)-high"),
            urlLowRes: hasLowRes ? Self.assetURL("\(name)-low.mp4") : nil,
            checksumLowRes: hasLowRes ? .init(algorithm: .sha256, value: "\(name)-low") : nil
        )
    }

    static func icon(
        _ name: String,
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialIconComponent>? = nil
    ) -> PaywallComponent.IconComponent {
        return .init(
            baseUrl: Self.assetURL("").absoluteString,
            iconName: name,
            formats: Self.iconFormats(name),
            size: .init(width: .fit(nil), height: .fit(nil)),
            padding: .zero,
            margin: .zero,
            color: .init(light: .hex("#000000")),
            iconBackground: nil,
            overrides: overrides
        )
    }

    static func iconFormats(_ name: String) -> PaywallComponent.IconComponent.Formats {
        return .init(svg: "\(name).svg", png: "\(name).png", heic: "\(name).heic", webp: "\(name).webp")
    }

    static func imageMedia(
        _ name: String,
        dark: Bool = false,
        rendersSynchronously: Bool = false
    ) -> [CacheAssetCollection.Media] {
        let names = dark ? [name, "\(name)-dark"] : [name]
        return names.map {
            .init(
                highResURL: .init(url: Self.assetURL("\($0)-high.heic"), checksum: nil),
                lowResURL: .init(url: Self.assetURL("\($0)-low.heic"), checksum: nil),
                rendersSynchronously: rendersSynchronously
            )
        }
    }

    static func videoMedia(
        _ name: String,
        dark: Bool = false,
        darkHasLowRes: Bool = true,
        rendersSynchronously: Bool = false
    ) -> [CacheAssetCollection.Media] {
        let namesAndLowRes = dark ? [(name, true), ("\(name)-dark", darkHasLowRes)] : [(name, true)]
        return namesAndLowRes.map { mediaName, hasLowRes in
            .init(
                highResURL: .init(
                    url: Self.assetURL("\(mediaName)-high.mp4"),
                    checksum: .init(algorithm: .sha256, value: "\(mediaName)-high")
                ),
                lowResURL: hasLowRes ? .init(
                    url: Self.assetURL("\(mediaName)-low.mp4"),
                    checksum: .init(algorithm: .sha256, value: "\(mediaName)-low")
                ) : nil,
                rendersSynchronously: rendersSynchronously
            )
        }
    }

    static func iconMedia(_ names: [String]) -> [CacheAssetCollection.Media] {
        return names.map {
            .init(
                highResURL: .init(url: Self.assetURL("\($0).heic"), checksum: nil),
                lowResURL: nil,
                rendersSynchronously: false
            )
        }
    }

    static func assetURL(_ path: String) -> URL {
        return Self.url("https://assets.example.com/\(path)")
    }

    static func url(_ string: String) -> URL {
        // swiftlint:disable:next force_unwrapping
        return URL(string: string)!
    }

    static var emptyUIConfig: UIConfig {
        return .init(
            app: .init(colors: [:], fonts: [:]),
            localizations: [:],
            variableConfig: .init(variableCompatibilityMap: [:], functionCompatibilityMap: [:])
        )
    }

    static func workflowScreen(components: [PaywallComponent]) -> WorkflowScreen {
        let data = Self.paywallComponentsData(components: components)
        return .init(
            name: "Test",
            templateName: data.templateName,
            assetBaseURL: data.assetBaseURL,
            componentsConfig: data.componentsConfig,
            componentsLocalizations: data.componentsLocalizations,
            defaultLocale: data.defaultLocale,
            offeringIdentifier: nil
        )
    }

    static func paywallComponentsData(components: [PaywallComponent]) -> PaywallComponentsData {
        return .init(
            templateName: "test",
            assetBaseURL: Self.cacheWarmingURL(""),
            componentsConfig: .init(base: .init(
                stack: .init(components: components),
                stickyFooter: nil,
                background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: [:],
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )
    }

    static func cacheWarmingImage(_ name: String) -> PaywallComponent.ThemeImageUrls {
        return .init(light: .init(
            width: 100,
            height: 100,
            original: Self.cacheWarmingURL("\(name)-original.png"),
            heic: Self.cacheWarmingURL("\(name)-high.heic"),
            heicLowRes: Self.cacheWarmingURL("\(name)-low.heic")
        ))
    }

    static func cacheWarmingVideo(
        _ name: String,
        hasLowRes: Bool = true
    ) -> PaywallComponent.ThemeVideoUrls {
        return .init(light: .init(
            width: 100,
            height: 100,
            url: Self.cacheWarmingURL("\(name)-high.mp4"),
            checksum: .init(algorithm: .sha256, value: "\(name)-high"),
            urlLowRes: hasLowRes ? Self.cacheWarmingURL("\(name)-low.mp4") : nil,
            checksumLowRes: hasLowRes ? .init(algorithm: .sha256, value: "\(name)-low") : nil
        ))
    }

    static func cacheWarmingURL(_ path: String) -> URL {
        // swiftlint:disable:next force_unwrapping
        return URL(string: "https://assets.example.com/\(path)")!
    }

    func workflowFontInstallCallCount(
        fontNames: [String],
        shouldFailInstallation: Bool = false
    ) async -> Int {
        let fontURL = URL(string: "https://example.com/font.ttf")!
        let fontsManager = MockFontsManager(
            installDelayInSeconds: 0,
            shouldFailInstallation: shouldFailInstallation
        )
        let cache = PaywallCacheWarming(
            introEligibiltyChecker: self.eligibilityChecker,
            fontsManager: fontsManager
        )

        for (index, fontName) in fontNames.enumerated() {
            let uiConfig = UIConfig(
                app: .init(
                    colors: [:],
                    fonts: [
                        "font": .init(
                            ios: .init(
                                name: fontName,
                                webFontInfo: .init(url: fontURL.absoluteString, hash: "abc123")
                            )
                        )
                    ]
                ),
                localizations: [:],
                variableConfig: .init(variableCompatibilityMap: [:], functionCompatibilityMap: [:])
            )
            let workflow = PublishedWorkflow(
                id: "workflow-\(index)",
                displayName: "Test",
                initialStepId: "step",
                singleStepFallbackId: nil,
                steps: [:],
                screens: [:]
            )
            await cache.prewarmWorkflowAssets(workflow: workflow, uiConfig: uiConfig)
        }

        return await fontsManager.installCallCount
    }
#endif

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

    static let bundle = Bundle(for: PaywallCacheWarmingTests.self)
    static let offeringIdentifier = "offering"

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private actor MockCacheWarmingFileRepository: FileRepositoryType {

    private(set) var requests: [URLWithValidation] = []

    nonisolated func prefetch(urls: [InputURL]) {}

    func generateOrGetCachedFileURL(
        for url: InputURL,
        withChecksum checksum: Checksum?
    ) async throws -> OutputURL {
        self.requests.append(.init(url: url, checksum: checksum))
        return url
    }

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

    init(
        installDelayInSeconds: TimeInterval,
        fontIsAlreadyInstalled: Bool = false,
        shouldFailInstallation: Bool = false
    ) {
        self.installDelayInSeconds = installDelayInSeconds
        self.fontIsAlreadyInstalled = fontIsAlreadyInstalled
        self.shouldFailInstallation = shouldFailInstallation
    }

    let fontIsAlreadyInstalled: Bool
    let shouldFailInstallation: Bool

    nonisolated func fontIsAlreadyInstalled(fontName: String, fontFamily: String?) -> Bool {
        return self.fontIsAlreadyInstalled
    }

    func installFont(_ font: RevenueCat.DownloadableFont) async throws {
        installCallCount += 1

        if self.shouldFailInstallation {
            throw NSError(domain: "MockFontsManager", code: 1)
        }

        let duration = UInt64(installDelayInSeconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
