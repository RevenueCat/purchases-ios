//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK2WinBackOfferEligibilityCalculator.swift
//
//  Created by Will Taylor on 10/31/24.

import StoreKit

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
final class WinBackOfferEligibilityCalculator: Sendable {

    // MARK: - Properties
    private let systemInfo: SystemInfo

    // MARK: - Initialization

    /// Creates an instance of `SK2WinBackOfferEligibilityCalculator`.
    ///
    /// - Parameter systemInfo: An instance of `SystemInfo` providing information about the system environment.
    init(
        systemInfo: SystemInfo
    ) {
        self.systemInfo = systemInfo
    }
}

// MARK: - WinBackOfferEligibilityCalculator Conformance
@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
extension WinBackOfferEligibilityCalculator: WinBackOfferEligibilityCalculatorType {

    func eligibleWinBackOffers(forProduct product: StoreProduct) async throws -> [WinBackOffer] {
        return try await self.calculateEligibleWinBackOffers(forProduct: product)
    }

}

// MARK: - Implementation
@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
extension WinBackOfferEligibilityCalculator {

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    private func calculateEligibleWinBackOffers(
        forProduct product: StoreProduct
    ) async throws -> [WinBackOffer] {

        #if compiler(>=6.0)
        guard self.systemInfo.storeKitVersion.isStoreKit2EnabledAndAvailable else {
            throw ErrorUtils.featureNotSupportedWithStoreKit1Error()
        }

        let eligibleWinBackOfferIDs: [String] = await self.calculateEligibleWinBackOfferIDs(forProduct: product)
        guard !eligibleWinBackOfferIDs.isEmpty else { return [] }

        guard let allWinBackOffersForThisProduct: [
            Product.SubscriptionOffer
        ] = product.sk2Product?.subscription?.winBackOffers else {
            // StoreKit.Product.SubscriptionInfo is nil if the product is not a subscription
            return []
        }

        let eligibleWinBackOffers = allWinBackOffersForThisProduct
            // 1. Filter out the offers that the subscriber is not eligible for
            .filter({
                Set(eligibleWinBackOfferIDs).contains($0.id)
            })
            // 2. Convert the eligible offers to StoreProductDiscounts for us to use
            .compactMap({
                StoreProductDiscount(sk2Discount: $0, currencyCode: product.currencyCode)
            })
            // 3. Convert the StoreProductDiscounts to WinBackOffer objects
            .map({
                WinBackOffer(discount: $0)
            })

        return eligibleWinBackOffers
        #else
        return []
        #endif
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    private func calculateEligibleWinBackOfferIDs(forProduct product: StoreProduct) async -> [String] {
        #if compiler(>=6.0)
        guard let statuses = try? await product.sk2Product?.subscription?.status, !statuses.isEmpty else {
            // If StoreKit.Product.subscription is nil, then the product isn't a subscription
            // If statuses is empty, the subscriber was never subscribed to a product in the subscription group.
            return []
        }

        let purchasedSubscriptionStatuses = statuses.filter({
            switch $0.transaction {
            case .unverified:
                return false
            case .verified(let transaction):
                // Intentionally exclude transactions acquired through family sharing
                return transaction.ownershipType == .purchased
            }
        })

        let renewalInfos: [Product.SubscriptionInfo.RenewalInfo] = purchasedSubscriptionStatuses.compactMap({
            $0.verifiedRenewalInfo
        })

        let eligibleWinBackOfferIDsPerRenewalInfo: [[String]] = renewalInfos.map({
            // StoreKit sorts eligibleWinBackOfferIDs by the "best" win-back offer first.
            $0.eligibleWinBackOfferIDs
        })

        // Flatten the win-back offer IDs we've received for all of the renewalInfos while removing duplicates
        let eligibleWinBackOfferIDs: [String] = {
            var seen = Set<String>()
            return eligibleWinBackOfferIDsPerRenewalInfo
                .flatMap { $0 }
                .filter { seen.insert($0).inserted }
        }()

        return eligibleWinBackOfferIDs
        #else
        return []
        #endif
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension StoreKit.Product.SubscriptionInfo.Status {
    var verifiedRenewalInfo: StoreKit.Product.SubscriptionInfo.RenewalInfo? {
        switch self.renewalInfo {
        case .unverified:
            Logger.warn(
                Strings.storeKit.sk2_unverified_renewal_info(
                    productIdentifier: String(self.transaction.underlyingTransaction.productID)
                )
            )
            return nil
        case .verified(let status):
            return status
        }
    }
}
