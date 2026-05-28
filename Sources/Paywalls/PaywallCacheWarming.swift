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

// swiftlint:disable file_length

import Foundation

protocol PaywallCacheWarmingType: Sendable {

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func warmUpEligibilityCache(offerings: Offerings) async

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func clearEligibilityCache() async

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func warmUpPaywallImagesCache(offerings: Offerings) async

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func warmUpPaywallVideosCache(offerings: Offerings) async

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func warmUpPaywallFontsCache(offerings: Offerings) async

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func warmUpWorkflowCaches(workflow: PublishedWorkflow) async

#if !os(tvOS) // For Paywalls

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func triggerFontDownloadIfNeeded(fontsConfig: UIConfig.FontsConfig) async

#endif
}

protocol PaywallFontManagerType: Sendable {

    func fontIsAlreadyInstalled(fontName: String, fontFamily: String?) -> Bool

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func installFont(_ font: DownloadableFont) async throws

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
actor PaywallCacheWarming: PaywallCacheWarmingType {

    private let introEligibiltyChecker: TrialOrIntroPriceEligibilityCheckerType
    private let fontsManager: PaywallFontManagerType
    private let fileRepository: FileRepositoryType
    private let htmlFileRepository: InMemoryHTMLFileRepositoryType

    private var warmedEligibilityProductIdentifiers: Set<String> = []
    private var hasLoadedImages = false
    private var hasLoadedVideos = false
    private var warmedWorkflowIDs: Set<String> = []
    private var ongoingFontDownloads: [URL: Task<Void, Never>] = [:]

    init(
        introEligibiltyChecker: TrialOrIntroPriceEligibilityCheckerType,
        fontsManager: PaywallFontManagerType = DefaultPaywallFontsManager(session: PaywallCacheWarming.downloadSession),
        fileRepository: FileRepositoryType = FileRepository.shared,
        htmlFileRepository: InMemoryHTMLFileRepositoryType = InMemoryHTMLFileRepository.shared
    ) {
        self.introEligibiltyChecker = introEligibiltyChecker
        self.fontsManager = fontsManager
        self.fileRepository = fileRepository
        self.htmlFileRepository = htmlFileRepository
    }

    /// Warms up the intro eligibility cache for products across all offerings.
    ///
    /// To avoid penalizing the current offering's warm-up with the cost of fetching eligibility for
    /// the rest of the offerings, the work is staggered: the current offering's products are
    /// warmed up first, and only after that completes are the remaining offerings warmed up.
    ///
    /// Products that have already been warmed up are skipped on subsequent calls.
    /// Call ``clearEligibilityCache()`` to reset the tracking (e.g. when `CustomerInfo` changes).
    func warmUpEligibilityCache(offerings: Offerings) async {
        let currentProducts = offerings.productIdentifiersInCurrentOffering
            .subtracting(self.warmedEligibilityProductIdentifiers)

        if !currentProducts.isEmpty {
            self.warmedEligibilityProductIdentifiers.formUnion(currentProducts)
            await Self.checkEligibility(productIdentifiers: currentProducts, checker: self.introEligibiltyChecker)
        }

        let remainingProducts = offerings.allProductIdentifiers
            .subtracting(self.warmedEligibilityProductIdentifiers)

        if !remainingProducts.isEmpty {
            self.warmedEligibilityProductIdentifiers.formUnion(remainingProducts)
            await Self.checkEligibility(productIdentifiers: remainingProducts, checker: self.introEligibiltyChecker)
        }
    }

    /// Resets the set of product identifiers that have been warmed up for intro eligibility.
    ///
    /// Should be called whenever the underlying eligibility cache is cleared (e.g. on
    /// `CustomerInfo` changes) so that the next call to ``warmUpEligibilityCache(offerings:)``
    /// re-populates the cache.
    func clearEligibilityCache() {
        self.warmedEligibilityProductIdentifiers.removeAll(keepingCapacity: false)
    }

    private static func checkEligibility(
        productIdentifiers: Set<String>,
        checker: TrialOrIntroPriceEligibilityCheckerType
    ) async {
        Logger.debug(Strings.paywalls.warming_up_eligibility_cache(products: productIdentifiers))
        _ = await Async.call { completion in
            checker.checkEligibility(productIdentifiers: productIdentifiers) { result in
                completion(result)
            }
        }
    }

    func warmUpPaywallImagesCache(offerings: Offerings) async {
        guard !self.hasLoadedImages else { return }
        self.hasLoadedImages = true

        let imageURLs = offerings.allImagesInPaywalls
        #if !os(tvOS)
        let webViewURLs = offerings.allWebViewURLsInPaywalls
        #else
        let webViewURLs: Set<URL> = []
        #endif
        guard !imageURLs.isEmpty || !webViewURLs.isEmpty else { return }

        if !imageURLs.isEmpty {
            Logger.verbose(Strings.paywalls.warming_up_images(imageURLs: imageURLs))
        }

        await withTaskGroup(of: Void.self) { group in
            for url in imageURLs {
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    // Preferred method - load with FileRepository
                    _ = try? await self.fileRepository.generateOrGetCachedFileURL(for: url, withChecksum: nil)
                }
            }
            #if !os(tvOS)
            for url in webViewURLs {
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    _ = try? await self.htmlFileRepository.generateOrGetCachedFileURL(for: url)
                }
            }
            #endif
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

    func warmUpWorkflowCaches(workflow: PublishedWorkflow) async {
        guard !self.warmedWorkflowIDs.contains(workflow.id) else { return }
        self.warmedWorkflowIDs.insert(workflow.id)

        // Intentionally prewarming all screens, not just those reachable from
        // `initialStepId`. This trades off potentially downloading assets for
        // unreachable screens against the simpler implementation. For workflows
        // with many screens or complex branching, switch to a bounded graph walk
        // from `initialStepId` via `WorkflowStep.stepTriggerActions` to limit
        // data, battery, and connection usage.
        let screens = Array(workflow.screens.values)

        Logger.verbose(Strings.paywalls.warming_up_workflow(screenCount: screens.count))

        let imageURLs = Set(screens.flatMap(\.allImageURLs))
        let videoURLs = Set(screens.flatMap(\.allLowResVideoUrls))
        #if !os(tvOS)
        let webViewURLs = Set(screens.flatMap(\.allWebViewURLs))
        #endif
        #if !os(tvOS)
        let fonts = workflow.uiConfig.app.allDownloadableFonts
        #endif

        await withTaskGroup(of: Void.self) { group in
            for url in imageURLs {
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    _ = try? await self.fileRepository.generateOrGetCachedFileURL(for: url, withChecksum: nil)
                }
            }
            for source in videoURLs {
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    _ = try? await self.fileRepository.generateOrGetCachedFileURL(
                        for: source.url,
                        withChecksum: source.checksum
                    )
                }
            }
            #if !os(tvOS)
            for url in webViewURLs {
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    _ = try? await self.htmlFileRepository.generateOrGetCachedFileURL(for: url)
                }
            }
            #endif
            #if !os(tvOS)
            for font in fonts {
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    await self.installFont(from: font)
                }
            }
            #endif
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

    var productIdentifiersInCurrentOffering: Set<String> {
        guard let current = self.current else { return [] }
        return Set(current.availablePackages.lazy.map(\.storeProduct.productIdentifier))
    }

    var allProductIdentifiers: Set<String> {
        return Set(
            self.all.values.lazy
                .flatMap(\.availablePackages)
                .map(\.storeProduct.productIdentifier)
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

    #if !os(tvOS) // For Paywalls V2

    var allWebViewURLsInPaywalls: Set<URL> {
        return .init(
            self
                .all
                .values
                .lazy
                .compactMap(\.paywallComponents)
                .flatMap(\.data.allWebViewURLs)
        )
    }

    #endif

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
