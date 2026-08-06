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
    localizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary]
) -> CacheAssetCollection {
    let componentAssets = componentsConfig.base.allCacheAssets
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
        var collector = AssetCollector()

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

    // swiftlint:disable:next cyclomatic_complexity function_body_length
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
            case .text, .tabControl, .tabControlToggle, .fallbackHeader:
                break
            case .icon(let icon):
                collector.imageURLs += icon.cacheMedia(rendersSynchronously: rendersSynchronously)
            case .image(let image):
                collector.imageURLs += image.source.cacheMedia(rendersSynchronously: rendersSynchronously)
                collector.imageURLs += image.overrides?.flatMap {
                    $0.properties.source?.cacheMedia(rendersSynchronously: rendersSynchronously) ?? []
                } ?? []
            case .stack(let stack):
                self.collectAssets(
                    in: stack,
                    rendersSynchronously: rendersSynchronously,
                    into: &collector
                )
            case .button(let button):
                self.collectAssets(
                    in: button.stack,
                    rendersSynchronously: rendersSynchronously,
                    into: &collector
                )

                switch button.action {
                case .navigateTo(let destination):
                    switch destination {
                    case .sheet(sheet: let sheet):
                        if let sheet {
                            self.collectAssets(
                                in: sheet.stack,
                                rendersSynchronously: rendersSynchronously,
                                into: &collector
                            )
                        }
                    case .customerCenter, .offerCode, .privacyPolicy, .terms, .webPaywallLink, .url, .unknown:
                        break
                    }
                case .restorePurchases, .navigateBack, .workflowTrigger, .unknown:
                    break
                }
            case .package(let package):
                self.collectAssets(
                    in: package.stack,
                    rendersSynchronously: rendersSynchronously,
                    into: &collector
                )
            case .purchaseButton(let purchaseButton):
                self.collectAssets(
                    in: purchaseButton.stack,
                    rendersSynchronously: rendersSynchronously,
                    into: &collector
                )
            case .stickyFooter(let stickyFooter):
                self.collectAssets(
                    in: stickyFooter.stack,
                    rendersSynchronously: rendersSynchronously,
                    into: &collector
                )
            case .timeline(let timeline):
                collector.imageURLs += timeline.items.flatMap {
                    $0.icon.cacheMedia(rendersSynchronously: rendersSynchronously)
                }
            case .tabs(let tabs):
                self.collectAssets(
                    in: tabs.control.stack,
                    rendersSynchronously: rendersSynchronously,
                    into: &collector
                )
                for tab in tabs.tabs {
                    self.collectAssets(
                        in: tab.stack,
                        rendersSynchronously: rendersSynchronously,
                        into: &collector
                    )
                }
            case .tabControlButton(let controlButton):
                self.collectAssets(
                    in: controlButton.stack,
                    rendersSynchronously: rendersSynchronously,
                    into: &collector
                )
            case .carousel(let carousel):
                for page in carousel.pages {
                    self.collectAssets(
                        in: page,
                        rendersSynchronously: rendersSynchronously,
                        into: &collector
                    )
                }
            case .video(let video):
                collector.videoURLs += video.source.cacheMedia(rendersSynchronously: rendersSynchronously)
                collector.videoURLs += video.overrides?.flatMap {
                    $0.properties.source?.cacheMedia(rendersSynchronously: rendersSynchronously) ?? []
                } ?? []
                collector.imageURLs += video.fallbackSource?.cacheMedia(
                    rendersSynchronously: rendersSynchronously
                ) ?? []
            case .countdown(let countdown):
                self.collectAssets(
                    in: countdown.countdownStack,
                    rendersSynchronously: rendersSynchronously,
                    into: &collector
                )
                if let endStack = countdown.endStack {
                    self.collectAssets(
                        in: endStack,
                        rendersSynchronously: rendersSynchronously,
                        into: &collector
                    )
                }
                if let fallback = countdown.fallback {
                    self.collectAssets(
                        in: fallback,
                        rendersSynchronously: rendersSynchronously,
                        into: &collector
                    )
                }
            case .webView(let webView):
                if let url = PaywallComponent.WebViewComponent.validatedHTTPSURL(from: webView.url) {
                    collector.webViewURLs.append(.init(url: url, checksum: nil))
                }
            }
        }
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private struct AssetCollector {

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
