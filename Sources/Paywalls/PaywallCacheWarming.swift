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

protocol PaywallCacheWarmingType: Sendable {

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func warmUpEligibilityCache(offerings: Offerings) async

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func warmUpPaywallImagesCache(offerings: Offerings) async

}

protocol PaywallImageFetcherType: Sendable {

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func downloadImage(_ url: URL) async throws

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
actor PaywallCacheWarming: PaywallCacheWarmingType {

    private let introEligibiltyChecker: TrialOrIntroPriceEligibilityCheckerType
    private let imageFetcher: PaywallImageFetcherType

    private var hasLoadedEligibility = false
    private var hasLoadedImages = false

    init(
        introEligibiltyChecker: TrialOrIntroPriceEligibilityCheckerType,
        imageFetcher: PaywallImageFetcherType = DefaultPaywallImageFetcher()
    ) {
        self.introEligibiltyChecker = introEligibiltyChecker
        self.imageFetcher = imageFetcher
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

        for url in imageURLs {
            do {
                try await self.imageFetcher.downloadImage(url)
            } catch {
                Logger.error(Strings.paywalls.error_prefetching_image(url, error))
            }
        }

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

    #if !os(macOS) && !os(tvOS) // For Paywalls V2

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

    #if !os(macOS) && !os(tvOS) // For Paywalls V2

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
        ]
            .compactMap { $0 }
    }

}
