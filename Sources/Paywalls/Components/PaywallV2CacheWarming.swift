//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallV2CacheWarming.swift
//
//  Created by Josh Holtz on 1/13/25.

import Foundation

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension PaywallComponentsData {

    var allCacheAssets: CacheAssetCollection {
        return cacheAssets(
            from: self.componentsConfig,
            localizations: self.componentsLocalizations
        )
    }

    var allImageURLs: [URL] {
        return self.allCacheAssets.imageSourcesToDownload.map(\.url)
    }

    var allLowResVideoUrls: [URLWithValidation] {
        return self.allCacheAssets.videoSourcesToDownload
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension WorkflowScreen {

    var allCacheAssets: CacheAssetCollection {
        return cacheAssets(
            from: self.componentsConfig,
            localizations: self.componentsLocalizations
        )
    }

    /// Like ``allCacheAssets``, but resolves localized videos for the locale that will be displayed only,
    /// since they are costly to download.
    func localizedCacheAssets(preferredLocales: [Locale]) -> CacheAssetCollection {
        let displayedLocale = self.componentsLocalizations.displayedLocale(
            preferredLocales: preferredLocales,
            defaultLocale: self.defaultLocale
        )
        return cacheAssets(
            from: self.componentsConfig,
            localizations: self.componentsLocalizations,
            localizedVideos: self.componentsVideoLocalizations.findLocale(displayedLocale) ?? [:]
        )
    }

    var allImageURLs: [URL] {
        return self.allCacheAssets.imageSourcesToDownload.map(\.url)
    }

    var allLowResVideoUrls: [URLWithValidation] {
        return self.allCacheAssets.videoSourcesToDownload
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private func cacheAssets(
    from componentsConfig: PaywallComponentsData.ComponentsConfig,
    localizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary],
    localizedVideos: PaywallComponent.VideoLocalizationDictionary? = nil
) -> CacheAssetCollection {
    let componentAssets = componentsConfig.base.cacheAssets(localizedVideos: localizedVideos)
    let localizedImages = localizations.values.flatMap { localeValues in
        localeValues.values.flatMap { value -> [CacheAssetCollection.Media] in
            switch value {
            case .string:
                return []
            case .image(let image):
                return image.cacheMedia(rendersSynchronously: false)
            }
        }
    }

    return .init(
        images: componentAssets.images + localizedImages,
        videos: componentAssets.videos,
        webBundles: componentAssets.webBundles
    )
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension PaywallComponentsData.PaywallComponentsConfig {

    var allCacheAssets: CacheAssetCollection {
        return self.cacheAssets(localizedVideos: nil)
    }

    /// - Parameter localizedVideos: used to resolve localized videos referenced by `overrideVideoLid`.
    /// If `nil`, `overrideVideoLid` is ignored and `source` is used.
    func cacheAssets(localizedVideos: PaywallComponent.VideoLocalizationDictionary?) -> CacheAssetCollection {
        var collector = AssetCollector(localizedVideos: localizedVideos)

        self.collectAssets(in: self.stack, rendersSynchronously: false, into: &collector)
        if let header = self.header {
            self.collectAssets(in: header.stack, rendersSynchronously: false, into: &collector)
        }
        if let stickyFooter = self.stickyFooter {
            self.collectAssets(in: stickyFooter.stack, rendersSynchronously: false, into: &collector)
        }
        collector.collect(self.background, rendersSynchronously: false)

        return collector.assets
    }

    var allImageURLs: [URL] {
        return self.allCacheAssets.imageSourcesToDownload.map(\.url)
    }

    var allLowResVideoUrls: [URLWithValidation] {
        return self.allCacheAssets.videoSourcesToDownload
    }

    private func collectAssets(
        in stack: PaywallComponent.StackComponent,
        rendersSynchronously: Bool,
        into collector: inout AssetCollector
    ) {
        if let background = stack.background {
            collector.collect(background, rendersSynchronously: rendersSynchronously)
        }

        for component in stack.components {
            let rendersSynchronously = rendersSynchronously || component.isSheetButton

            switch component {
            case .text, .tabControl, .tabControlToggle, .fallbackHeader,
                 .stack, .button, .package, .purchaseButton, .stickyFooter,
                 .tabs, .tabControlButton, .carousel, .countdown:
                break
            case .icon(let icon):
                collector.imageURLs += icon.cacheMedia(rendersSynchronously: rendersSynchronously)
            case .image(let image):
                collector.imageURLs += image.source.cacheMedia(rendersSynchronously: rendersSynchronously)
                collector.imageURLs += image.overrides?.flatMap {
                    $0.properties.source?.cacheMedia(rendersSynchronously: rendersSynchronously) ?? []
                } ?? []
            case .timeline(let timeline):
                collector.imageURLs += timeline.items.flatMap {
                    $0.icon.cacheMedia(rendersSynchronously: rendersSynchronously)
                }
            case .video(let video):
                collector.videoURLs += collector.videoSource(
                    video.source,
                    overrideVideoLid: video.overrideVideoLid
                )?.cacheMedia(rendersSynchronously: rendersSynchronously) ?? []
                collector.videoURLs += video.overrides?.flatMap {
                    collector.videoSource(
                        $0.properties.source,
                        overrideVideoLid: $0.properties.overrideVideoLid
                    )?.cacheMedia(rendersSynchronously: rendersSynchronously) ?? []
                } ?? []
                collector.imageURLs += video.fallbackSource?.cacheMedia(
                    rendersSynchronously: rendersSynchronously
                ) ?? []
            case .webView(let webView):
                if let url = PaywallComponent.WebViewComponent.validatedHTTPSURL(from: webView.url) {
                    collector.webViewURLs.append(.init(url: url, checksum: nil))
                }
            }

            for childStack in component.childStacks(includeSheetDestinations: true) {
                self.collectAssets(in: childStack, rendersSynchronously: rendersSynchronously, into: &collector)
            }
        }
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private struct AssetCollector {

    let localizedVideos: PaywallComponent.VideoLocalizationDictionary?
    var imageURLs: [CacheAssetCollection.Media] = []
    var videoURLs: [CacheAssetCollection.Media] = []
    var webViewURLs: [URLWithValidation] = []

    var assets: CacheAssetCollection {
        return .init(
            images: self.imageURLs,
            videos: self.videoURLs,
            webBundles: self.webViewURLs
        )
    }

    func videoSource(
        _ source: PaywallComponent.ThemeVideoUrls?,
        overrideVideoLid: PaywallComponent.LocalizationKey?
    ) -> PaywallComponent.ThemeVideoUrls? {
        guard let overrideVideoLid, let localizedVideos = self.localizedVideos else { return source }
        // Like rendering, a lid never falls back to `source`: without its localized video the paywall fails.
        return localizedVideos[overrideVideoLid]
    }

    mutating func collect(
        _ background: PaywallComponent.Background,
        rendersSynchronously: Bool
    ) {
        switch background {
        case .color:
            break
        case .image(let imageURLs, _, _):
            self.imageURLs += imageURLs.cacheMedia(rendersSynchronously: rendersSynchronously)
        case .video(let videoURLs, let fallbackImageURLs, _, _, _, _):
            self.videoURLs += videoURLs.cacheMedia(rendersSynchronously: rendersSynchronously)
            self.imageURLs += fallbackImageURLs.cacheMedia(rendersSynchronously: rendersSynchronously)
        }
    }

}

private extension PaywallComponent {

    var isSheetButton: Bool {
        switch self {
        case .button(let component):
            switch component.action {
            case .navigateTo(.sheet):
                return true
            default:
                return false
            }
        default:
            return false
        }
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private extension PaywallComponent.ThemeImageUrls {

    func cacheMedia(rendersSynchronously: Bool) -> [CacheAssetCollection.Media] {
        return [self.light, self.dark]
            .compactMap { $0 }
            .map { imageURLs in
                .init(
                    highResURL: .init(url: imageURLs.heic, checksum: nil),
                    lowResURL: .init(url: imageURLs.heicLowRes, checksum: nil),
                    rendersSynchronously: rendersSynchronously
                )
            }
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private extension PaywallComponent.ThemeVideoUrls {

    func cacheMedia(rendersSynchronously: Bool) -> [CacheAssetCollection.Media] {
        return [self.light, self.dark]
            .compactMap { $0 }
            .map { videoURLs in
                .init(
                    highResURL: .init(url: videoURLs.url, checksum: videoURLs.checksum),
                    lowResURL: videoURLs.urlLowRes.map {
                        .init(url: $0, checksum: videoURLs.checksumLowRes)
                    },
                    rendersSynchronously: rendersSynchronously
                )
            }
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private extension PaywallComponent.IconComponent {

    func cacheMedia(rendersSynchronously: Bool) -> [CacheAssetCollection.Media] {
        guard let baseURL = URL(string: self.baseUrl) else {
            return []
        }

        let formats = [self.formats] + (self.overrides?.compactMap(\.properties.formats) ?? [])
        return formats.map {
            .init(
                highResURL: .init(url: baseURL.appendingPathComponent($0.heic), checksum: nil),
                lowResURL: nil,
                rendersSynchronously: rendersSynchronously
            )
        }
    }

}
