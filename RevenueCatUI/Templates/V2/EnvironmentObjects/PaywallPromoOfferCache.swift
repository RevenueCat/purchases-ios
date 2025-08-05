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
@_spi(Internal) import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
internal final class PaywallPromoOfferCache: ObservableObject {

    typealias ProductID = String
    typealias PackageInfo = (package: Package, promotionalOfferProductCode: String?)

    enum Status: Equatable {
        case unknown
        case ineligible
        case signedEligible(PromotionalOffer)
    }

    private var cache: [ProductID: Status] = [:]
    private var hasAnySubscriptionHistory: Bool = false
    private var cancellable: AnyCancellable?

    // MARK: - Init

    init(subscriptionHistoryTracker: SubscriptionHistoryTracker) {
        Task {
            self.cancellable = await subscriptionHistoryTracker.status.sink { [weak self] status in
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
        for packageInfo in packageInfos {
            let storeProduct = packageInfo.package.storeProduct
            if let productCode = packageInfo.promotionalOfferProductCode,
               let discount = storeProduct.discounts.first(where: { $0.offerIdentifier == productCode }) {

                do {
                    let promoOffer = try await Purchases.shared.promotionalOffer(
                        forProductDiscount: discount,
                        product: storeProduct
                    )
                    cache[storeProduct.productIdentifier] = .signedEligible(promoOffer)
                } catch {
                    cache[storeProduct.productIdentifier] = .ineligible
                }
            }
        }
    }
}
