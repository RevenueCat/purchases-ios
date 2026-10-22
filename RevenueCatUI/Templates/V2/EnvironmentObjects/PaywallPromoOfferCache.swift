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

    // Includes the billing plan: variants of the same App Store product can have different offers.
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

    /// `nil` fetches eligibility from the backend. Otherwise eligibility is fabricated locally
    /// (dummy signed offers when `true`, ineligible when `false`), so paywall previews/mocks can
    /// show promo components and pricing without a real subscriber or a backend-signed offer.
    private let simulatedEligibility: Bool?

    // MARK: - Init

    init(subscriptionHistoryTracker: SubscriptionHistoryTracker?, simulatedEligibility: Bool? = nil) {
        self.simulatedEligibility = simulatedEligibility

        // Simulate mode passes no tracker: it only ever produces `.signedEligible`/`.ineligible` entries,
        // which never consult `hasAnySubscriptionHistory`, so we skip the tracker's StoreKit work.
        guard let subscriptionHistoryTracker else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.cancellable = await subscriptionHistoryTracker.status
                .receive(on: DispatchQueue.main)
                .sink { [weak self] status in
                    self?.hasAnySubscriptionHistory = status == .hasHistory
                }
        }
    }

    /// Builds a cache that fabricates dummy signed promo offers for matching packages, for paywall
    /// previews/mocks. No network or real subscription required. Seeding happens during the view's
    /// eligibility `.task`, so it does not run in Xcode Previews / Emerge snapshots (where that task
    /// is skipped); it does run in a normally-launched preview app.
    convenience init(simulateEligible: Bool) {
        self.init(subscriptionHistoryTracker: nil, simulatedEligibility: simulateEligible)
    }

    /// The cache a preview needs for `simulateEligible`, or `nil` to leave the real one in place.
    /// Single mapping site, so an initializer that forwards the flag cannot forget to build it.
    static func simulated(if simulateEligible: Bool) -> PaywallPromoOfferCache? {
        return simulateEligible ? PaywallPromoOfferCache(simulateEligible: true) : nil
    }

    // MARK: - Public API

    func computeEligibility(for packageInfos: [PackageInfo]) async {
        await self.checkSignedEligibility(packageInfos: packageInfos)
    }

    func isMostLikelyEligible(for package: Package?) -> Bool {
        guard let package else { return false }

        let status = cache[package.storeProduct.id] ?? .ineligible
        switch status {
        case .unknown, .signedEligible:
            return true
        case .ineligible:
            return hasAnySubscriptionHistory
        }
    }

    func get(for package: Package?) -> PromotionalOffer? {
        guard let package else { return nil }

        if case .signedEligible(let promoOffer) = cache[package.storeProduct.id] {
            return promoOffer
        }

        return nil
    }

    /// The signed offer to forward to a real purchase. Returns `nil` in simulate mode so a fabricated
    /// offer (sentinel signing data) never reaches StoreKit; display paths still use `get(for:)`.
    func purchasableOffer(for package: Package?) -> PromotionalOffer? {
        return self.simulatedEligibility != nil ? nil : self.get(for: package)
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

                if let simulatedEligibility = self.simulatedEligibility {
                    newCacheEntries[storeProduct.id] = simulatedEligibility
                        ? .signedEligible(Self.makeSimulatedOffer(for: discount))
                        : .ineligible
                    continue
                }

                do {
                    let promoOffer = try await Purchases.shared.promotionalOffer(
                        forProductDiscount: discount,
                        product: storeProduct
                    )
                    newCacheEntries[storeProduct.id] = .signedEligible(promoOffer)
                } catch {
                    newCacheEntries[storeProduct.id] = .ineligible
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

    /// Fabricates a dummy signed offer for previews. The signing values are sentinels: this offer is
    /// only used to drive promo display/pricing in a mock, never sent to the backend.
    private static func makeSimulatedOffer(for discount: StoreProductDiscount) -> PromotionalOffer {
        return discount.promotionalOffer(
            withSignedDataIdentifier: "preview",
            keyIdentifier: "preview",
            nonce: UUID(),
            signature: "preview",
            timestamp: 0
        )
    }
}
