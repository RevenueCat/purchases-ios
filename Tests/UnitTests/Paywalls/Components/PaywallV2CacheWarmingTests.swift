//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallV2CacheWarmingTests.swift
//

@_spi(Internal) @testable import RevenueCat
import XCTest

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
final class PaywallV2CacheWarmingTests: TestCase {

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
            Set(assets.imageURLs),
            Set(
                Self.imageMedia("image", dark: true) +
                Self.imageMedia("image-override") +
                Self.iconMedia(["icon", "icon-override"]) +
                Self.imageMedia("video-fallback") +
                Self.imageMedia("localized", dark: true)
            )
        )
        XCTAssertEqual(
            Set(assets.videoURLs),
            Set(
                Self.videoMedia("video", dark: true, darkHasLowRes: false) +
                Self.videoMedia("video-override")
            )
        )
        XCTAssertEqual(
            assets.webViewURLs,
            [.init(url: Self.url("https://example.com/cache"), checksum: nil)]
        )

        XCTAssertEqual(
            Set(data.allImageURLs),
            Set(assets.imageURLs.map { ($0.lowResURL ?? $0.highResURL).url })
        )
        XCTAssertEqual(
            Set(data.allLowResVideoUrls),
            Set(assets.videoURLs.compactMap(\.lowResURL))
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
            assets.imageURLs
                .filter(\.rendersSynchronously)
                .map(\.highResURL.url.lastPathComponent)
        )

        XCTAssertEqual(synchronousImageNames, ["sheet-high.heic", "sheet-button-high.heic"])
        XCTAssertEqual(
            Set(assets.videoURLs.filter(\.rendersSynchronously).map(\.highResURL.url.lastPathComponent)),
            ["sheet-video-high.mp4"]
        )
        XCTAssertEqual(
            Set(assets.videoURLs.map(\.highResURL.url.lastPathComponent)),
            ["sheet-video-high.mp4", "tab-control-high.mp4"]
        )

        let expectedContainerImages = [
            "outside", "sheet", "sheet-button", "stack", "package", "purchase",
            "footer-component", "tab", "tab-button", "carousel",
            "countdown", "countdown-end", "countdown-fallback"
        ]
        XCTAssertEqual(
            Set(assets.imageURLs.map(\.highResURL.url.lastPathComponent)),
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
            Set(assets.imageURLs.map(\.highResURL.url.lastPathComponent)),
            [
                "stack-fallback-high.heic",
                "header-high.heic",
                "footer-background-high.heic",
                "root-fallback-high.heic"
            ]
        )
        XCTAssertEqual(
            Set(assets.videoURLs.map(\.highResURL.url.lastPathComponent)),
            ["stack-background-high.mp4", "root-background-high.mp4"]
        )
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private extension PaywallV2CacheWarmingTests {

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

}
