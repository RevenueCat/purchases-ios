//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPromoOfferCacheV2.swift
//
//  Created by Josh Holtz on 7/28/25.

import Combine
import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
internal final class PaywallPromoOfferCache: ObservableObject {

    typealias ProductID = String
    typealias PackageInfo = (package: Package, promotionalOfferProductCode: String?)

    enum Status: Equatable {
        case unknown
        case ineligible
        case signedEligible(PromotionalOffer)
    }

    @Published
    private var cache: [ProductID: Status] = [:]
    @Published
    private var hasAnySubscriptionHistory: Bool = false
    private var cancellable: AnyCancellable?

    // MARK: - Init

    init(subscriptionHistoryTracker: SubscriptionHistoryTracker) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.cancellable = await subscriptionHistoryTracker.status
                .receive(on: DispatchQueue.main)
                .sink { [weak self] status in
                    self?.hasAnySubscriptionHistory = status == .hasHistory
                }
        }
    }

    // MARK: - Public API

    func computeEligibility(for packageInfos: [PackageInfo]) async {
        await self.checkSignedEligibility(packageInfos: packageInfos)
    }

    func isMostLikelyEligible(for package: Package?) -> Bool {
        guard let package else { return false }

        let status = cache[package.storeProduct.productIdentifier] ?? .ineligible
        switch status {
        case .unknown, .signedEligible:
            return true
        case .ineligible:
            return hasAnySubscriptionHistory
        }
    }

    func get(for package: Package?) -> PromotionalOffer? {
        guard let package else { return nil }

        if case .signedEligible(let promoOffer) = cache[package.storeProduct.productIdentifier] {
            return promoOffer
        }

        return nil
    }

    // MARK: - Internal Logic

    private func checkSignedEligibility(packageInfos: [PackageInfo]) async {
        // Build up results in a local dictionary first, then assign all at once.
        // This ensures a single atomic update to the @Published property,
        // which reliably triggers objectWillChange and view updates.
        var newCacheEntries: [ProductID: Status] = [:]

        for packageInfo in packageInfos {
            let storeProduct = packageInfo.package.storeProduct
            if let productCode = packageInfo.promotionalOfferProductCode,
               let discount = storeProduct.discounts.first(where: { $0.offerIdentifier == productCode }) {

                do {
                    let promoOffer = try await Purchases.shared.promotionalOffer(
                        forProductDiscount: discount,
                        product: storeProduct
                    )
                    newCacheEntries[storeProduct.productIdentifier] = .signedEligible(promoOffer)
                } catch {
                    newCacheEntries[storeProduct.productIdentifier] = .ineligible
                }
            }
        }

        // Single atomic assignment to trigger @Published and objectWillChange
        var updatedCache = self.cache
        for (key, value) in newCacheEntries {
            updatedCache[key] = value
        }
        self.cache = updatedCache
    }
}
