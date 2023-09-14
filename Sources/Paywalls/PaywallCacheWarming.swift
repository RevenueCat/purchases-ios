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

        // SwiftUI's `AsyncImage` uses `URLSession.shared` for internal caching.
        URLCache.shared.memoryCapacity = 50_000_000 // 50M
        URLCache.shared.diskCapacity = 200_000_000 // 200MB
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

// MARK: -

final class DefaultPaywallImageFetcher: PaywallImageFetcherType {

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func downloadImage(_ url: URL) async throws {
        _ = try await URLSession.shared.data(from: url)
    }

}

// MARK: - Extensions

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

    var allImagesInPaywalls: Set<URL> {
        return .init(
            self
                .offeringsToPreWarm
                .lazy
                .compactMap(\.paywall)
                .flatMap(\.allImageURLs)
        )
    }

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

private extension PaywallData {

    var allImageURLs: [URL] {
        return self.config.images
            .allImageNames
            .map { self.assetBaseURL.appendingPathComponent($0) }
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
