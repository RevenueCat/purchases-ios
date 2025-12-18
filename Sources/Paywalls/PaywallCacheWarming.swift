//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallCacheWarming.swift
//

//  Created by Nacho Soto on 8/7/23.

import Foundation

// swiftlint:disable file_length
protocol PaywallCacheWarmingType: Sendable {

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func warmUpEligibilityCache(offerings: Offerings) async

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func warmUpPaywallImagesCache(offerings: Offerings) async

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func warmUpPaywallVideosCache(offerings: Offerings) async

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func warmUpPaywallFontsCache(offerings: Offerings) async

#if !os(tvOS) // For Paywalls

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func triggerFontDownloadIfNeeded(fontsConfig: UIConfig.FontsConfig) async

#endif
}

protocol PaywallImageFetcherType: Sendable {

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func downloadImage(_ url: URL) async throws

}

protocol PaywallFontManagerType: Sendable {

    func fontIsAlreadyInstalled(fontName: String, fontFamily: String?) -> Bool

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func installFont(_ font: DownloadableFont) async throws

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
actor PaywallCacheWarming: PaywallCacheWarmingType {

    private let introEligibiltyChecker: TrialOrIntroPriceEligibilityCheckerType
    private let imageFetcher: PaywallImageFetcherType
    private let fontsManager: PaywallFontManagerType
    private let fileRepository: FileRepositoryType

    private var hasLoadedEligibility = false
    private var hasLoadedImages = false
    private var hasLoadedVideos = false
    private var ongoingFontDownloads: [URL: Task<Void, Never>] = [:]

    init(
        introEligibiltyChecker: TrialOrIntroPriceEligibilityCheckerType,
        imageFetcher: PaywallImageFetcherType = DefaultPaywallImageFetcher(),
        fontsManager: PaywallFontManagerType = DefaultPaywallFontsManager(session: PaywallCacheWarming.downloadSession),
        fileRepository: FileRepositoryType = FileRepository.shared
    ) {
        self.introEligibiltyChecker = introEligibiltyChecker
        self.imageFetcher = imageFetcher
        self.fontsManager = fontsManager
        self.fileRepository = fileRepository
    }

    func warmUpEligibilityCache(offerings: Offerings) {
        guard !self.hasLoadedEligibility else { return }
        self.hasLoadedEligibility = true

        let productIdentifiers = offerings.allProductIdentifiersInPaywalls
        guard !productIdentifiers.isEmpty else { return }

        Logger.debug(Strings.paywalls.warming_up_eligibility_cache(products: productIdentifiers))
        self.introEligibiltyChecker.checkEligibility(productIdentifiers: productIdentifiers) { _ in }
    }

    func warmUpPaywallImagesCache(offerings: Offerings) async {
        guard !self.hasLoadedImages else { return }
        self.hasLoadedImages = true

        let imageURLs = offerings.allImagesInPaywalls
        guard !imageURLs.isEmpty else { return }

        Logger.verbose(Strings.paywalls.warming_up_images(imageURLs: imageURLs))

        await withTaskGroup(of: Void.self) { group in
            for url in imageURLs {
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    // Preferred method - load with FileRepository
                    _ = try? await self.fileRepository.generateOrGetCachedFileURL(for: url, withChecksum: nil)

                    // Legacy method - load with URLSession
                    do {
                        try await self.imageFetcher.downloadImage(url)
                    } catch {
                        Logger.error(Strings.paywalls.error_prefetching_image(url, error))
                    }
                }
            }
        }
    }

    func warmUpPaywallVideosCache(offerings: Offerings) async {
        guard !self.hasLoadedVideos else { return }
        self.hasLoadedVideos = true

        let videoURLs = offerings.allLowResVideosInPaywalls
        guard !videoURLs.isEmpty else { return }

        Logger.verbose(Strings.paywalls.warming_up_videos(videoURLs: videoURLs))
        await withTaskGroup(of: Void.self) { group in
            for source in videoURLs {
                group.addTask { [weak self] in
                    _ = try? await self?.fileRepository.generateOrGetCachedFileURL(
                        for: source.url,
                        withChecksum: source.checksum
                    )
                }
            }
        }
    }

    func warmUpPaywallFontsCache(offerings: Offerings) async {
        let allFontsInPaywallsNamed = offerings.allFontsInPaywallsNamed
        let allFontURLs = Set(allFontsInPaywallsNamed.map(\.url))
        Logger.verbose(Strings.paywalls.warming_up_fonts(fontsURLS: allFontURLs))

        await withTaskGroup(of: Void.self) { group in
            for font in allFontsInPaywallsNamed {
                group.addTask { [weak self] in
                    await self?.installFont(from: font)
                }
            }
        }
    }

#if !os(tvOS)

    /// Downloads and installs the font if it is not already installed.
    func triggerFontDownloadIfNeeded(fontsConfig: UIConfig.FontsConfig) async {
        guard let downloadableFont = fontsConfig.downloadableFont else { return }
        await self.installFont(from: downloadableFont)
    }

#endif

    private func installFont(from font: DownloadableFont) async {
        if let existingTask = ongoingFontDownloads[font.url] {
            // Already downloading, await the existing task.
            Logger.debug(Strings.paywalls.font_download_already_in_progress(
                name: font.name,
                fontURL: font.url)
            )
            await existingTask.value
            return
        }

        if self.fontsManager.fontIsAlreadyInstalled(fontName: font.name, fontFamily: font.fontFamily) {
            // Font already available, no need to download.
            return
        }

        let task = Task {
            do {
                try await self.fontsManager.installFont(font)
            } catch {
                Logger.error(Strings.paywalls.error_installing_font(font.url, error))
            }
        }

        ongoingFontDownloads[font.url] = task
        await task.value
        ongoingFontDownloads[font.url] = nil
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension PaywallCacheWarming {

    static let downloadSession: URLSession = {
        return .init(
            configuration: {
                let configuration: URLSessionConfiguration = .default
                configuration.urlCache = PaywallCacheWarming.urlCache
                return configuration
            }()
        )
    }()

    private static let urlCache = URLCache(memoryCapacity: 50_000_000, // 50M
                                           diskCapacity: 200_000_000) // 200MB
}

// MARK: -

private final class DefaultPaywallImageFetcher: PaywallImageFetcherType {

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func downloadImage(_ url: URL) async throws {
        _ = try await PaywallCacheWarming.downloadSession.data(from: url)
    }

}

// MARK: - Extensions

internal extension PaywallData {

    /// - Returns: all image URLs contained in this paywall.
    var allImageURLs: [URL] {
        return self
            .allImages
            .lazy
            .flatMap(\.allImageNames)
            .map { self.assetBaseURL.appendingPathComponent($0) }
    }

    private var allImages: [PaywallData.Configuration.Images] {
        if self.config.tiers.isEmpty {
            return [self.config.images]
        } else {
            let imagesByTier = self.config.imagesByTier
            return self.config.tiers
                .lazy
                .map(\.id)
                .compactMap { imagesByTier[$0] }
        }
    }

}

private extension Offerings {

    var offeringsToPreWarm: [Offering] {
        // At the moment we only want to pre-warm the current offering to prevent
        // apps with many paywalls from downloading a large amount of images
        return self.current.map { [$0] } ?? []
    }

    var allProductIdentifiersInPaywalls: Set<String> {
        return .init(
            self
                .offeringsToPreWarm
                .lazy
                .flatMap(\.productIdentifiersInPaywall)
        )
    }

    var allLowResVideosInPaywalls: Set<URLWithValidation> {
        return .init(
            self
                .all
                .values
                .lazy
                .compactMap(\.paywallComponents)
                .flatMap(\.data.allLowResVideoUrls)
        )
    }

#if !os(tvOS) // For Paywalls V2

    var allFontsInPaywallsNamed: [DownloadableFont] {
        response.uiConfig?
            .app
            .allDownloadableFonts ?? []
    }

#else

    var allFontsInPaywallsNamed: [DownloadableFont] {
        [ ]
    }

#endif

    #if !os(tvOS) // For Paywalls V2

    var allImagesInPaywalls: Set<URL> {
        return self.allImagesInPaywallsV1 + self.allImagesInPaywallsV2
    }

    #else

    var allImagesInPaywalls: Set<URL> {
        return self.allImagesInPaywallsV1
    }

    #endif

    private var allImagesInPaywallsV1: Set<URL> {
        return .init(
            self
                .offeringsToPreWarm
                .lazy
                .compactMap(\.paywall)
                .flatMap(\.allImageURLs)
        )
    }

    #if !os(tvOS) // For Paywalls V2

    private var allImagesInPaywallsV2: Set<URL> {
        // Attempting to warm up all low res images for all offerings for Paywalls V2.
        // Paywalls V2 paywall are explicitly published so anything that
        // is here is intended to be displayed.
        // Also only prewarming low res urls
        return .init(
            self
                .all
                .values
                .lazy
                .compactMap(\.paywallComponents)
                .flatMap(\.data.allImageURLs)
        )
    }

    #endif

}

private extension Offering {

    var productIdentifiersInPaywall: Set<String> {
        guard let paywall = self.paywall else { return [] }

        let packageTypes = Set(paywall.config.packages)
        return Set(
            self.availablePackages
                .lazy
                .filter { packageTypes.contains($0.identifier) }
                .map(\.storeProduct.productIdentifier)
        )
    }
}

private extension PaywallData.Configuration.Images {

    var allImageNames: [String] {
        return [
            self.header,
            self.background,
            self.icon
        ].compactMap { $0 }
    }
}

/// Business logic object to easily manage the download of fonts.
struct DownloadableFont: Sendable {

    /// The font name.
    let name: String

    /// The font family name, if available.
    let fontFamily: String?

    let url: URL
    let hash: String
}

#if !os(tvOS) // For Paywalls V2

private extension UIConfig.AppConfig {
    var allDownloadableFonts: [DownloadableFont] {
        fonts.values.compactMap {
            $0.downloadableFont
        }
    }
}

private extension UIConfig.FontsConfig {
    var downloadableFont: DownloadableFont? {
        if let webFontInfo = self.ios.webFontInfo {
            guard let url = URL(string: webFontInfo.url) else {
                Logger.error(PaywallsStrings.error_prefetching_font_invalid_url(name: self.ios.value,
                                                                                invalidURLString: webFontInfo.url))
                return nil
            }

            return DownloadableFont(
                name: self.ios.value,
                fontFamily: webFontInfo.family,
                url: url,
                hash: webFontInfo.hash
            )
        }
        return nil
    }
}

#endif
