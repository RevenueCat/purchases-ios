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

        let winbackOffersByID: [String: Product.SubscriptionOffer] = self.winbackOffersByID(for: product)
        guard !winbackOffersByID.isEmpty else { return [] }

        let eligibleWinBackOffers: [WinBackOffer] = eligibleWinBackOfferIDs
            // Convert the eligible offer IDs to StoreProductDiscounts for us to use
            .compactMap { winbackOfferID in
                guard let winbackOffer = winbackOffersByID[winbackOfferID] else {
                    return nil
                }
                return StoreProductDiscount(sk2Discount: winbackOffer, currencyCode: product.currencyCode)
            }
            // Convert the StoreProductDiscounts to WinBackOffer objects
            .map { WinBackOffer(discount: $0) }

        return eligibleWinBackOffers
        #else
        return []
        #endif
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    private func calculateEligibleWinBackOfferIDs(forProduct product: StoreProduct) async -> [String] {
        #if compiler(>=6.0)
        guard let subscriptionInfo = product.sk2Product?.subscription else {
            // If StoreKit.Product.subscription is nil, then the product isn't a subscription
            return []
        }

        guard let statuses = try? await subscriptionInfo.status, !statuses.isEmpty else {
            // If statuses is empty, the subscriber was never subscribed to a product in the subscription group.
            return []
        }

        // It's okay for us to only check the first matching status since you can only be subscribed to a product once.
        // Thus, there can be at most 1 renewalInfo that is not a family shared one.
        // See https://developer.apple.com/videos/play/wwdc2024/10110/ for an example.
        guard let purchaseSubscriptionStatus = statuses.first(where: {
            $0.transaction.unsafePayloadValue.ownershipType == .purchased
        }) else {
            return []
        }

        guard let renewalInfo = purchaseSubscriptionStatus.verifiedRenewalInfo else {
            return []
        }

        // StoreKit sorts eligibleWinBackOfferIDs by the "best" win-back offer first.
        // Note that renewalInfo.eligibleWinBackOfferIDs contains the eligible winback offers across all billing plans.
        var eligibleWinBackOfferIDs = renewalInfo.eligibleWinBackOfferIDs

        #if compiler(>=6.3.2)
        if #available(iOS 26.4, tvOS 26.4, macOS 26.4, watchOS 26.4, visionOS 26.4, *) {
            let availableOfferIDs: Set<String>
            if let billingPlan = product.installmentsInfo?.billingPlanType {
                availableOfferIDs = availableWinBackOfferIDs(
                    forBillingPlan: billingPlan,
                    subscriptionInfo: subscriptionInfo
                )
            } else {
                availableOfferIDs = Set(
                    subscriptionInfo.winBackOffers.compactMap({ $0.id })
                )
            }

            eligibleWinBackOfferIDs = filterWinBackOfferIDs(
                eligibleWinBackOfferIDs,
                availableWinBackOfferIDs: availableOfferIDs
            )
        }
        #endif

        return eligibleWinBackOfferIDs
        #else
        return []
        #endif
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    private func winbackOffersByID(
        for product: StoreProduct
    ) -> [String: Product.SubscriptionOffer] {
        #if compiler(>=6.0)
        var winbackOffersByID: [String: Product.SubscriptionOffer] = [:]

        guard let subscriptionInfo = product.sk2Product?.subscription else {
            return winbackOffersByID
        }

        // First, get the winbacks on the product itself
        for winbackOffer in subscriptionInfo.winBackOffers {
            if let winbackID = winbackOffer.id {
                winbackOffersByID[winbackID] = winbackOffer
            }
        }

        #if compiler(>=6.3.2)
        if #available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *) {
            // Get the winbacks that might only be available on one set of pricing terms
            for pricingTerms in subscriptionInfo.pricingTerms {
                let winbackOffers = pricingTerms.subscriptionOffers.filter({ $0.type == .winBack })
                for winbackOffer in winbackOffers {
                    if let winbackID = winbackOffer.id,
                       !winbackOffersByID.keys.contains(winbackID) {
                        winbackOffersByID[winbackID] = winbackOffer
                    }
                }
            }
        }
        #endif

        return winbackOffersByID
        #else
        // Winback offers are not supported with compiler <6.0
        return [:]
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

@available(iOS 26.4, tvOS 26.4, macOS 26.4, watchOS 26.4, *)
private extension WinBackOfferEligibilityCalculator {
    private func availableWinBackOfferIDs(
        forBillingPlan billingPlanType: BillingPlanType,
        subscriptionInfo: Product.SubscriptionInfo
    ) -> Set<String> {
        #if compiler(>=6.3.2)
        let skBillingPlanType = billingPlanType.skBillingPlanType
        guard let applicablePricingTerms = subscriptionInfo.pricingTerms.first(where: {
            $0.billingPlanType == skBillingPlanType
        }) else {
            // The user is not eligible for pricing terms with the requested billing plan. Therefore, they are
            // not eligible for winback offers on that given billing plan type.
            return []
        }

        return Set(
            applicablePricingTerms.subscriptionOffers
                .filter({ $0.type == .winBack })
                .compactMap({ $0.id })
        )
        #else
        // Billing plans are not available
        return []
        #endif
    }

    private func filterWinBackOfferIDs(
        _ allWinbackOfferIDs: [String],
        availableWinBackOfferIDs: Set<String>
    ) -> [String] {
        guard !availableWinBackOfferIDs.isEmpty else { return [] }

        return allWinbackOfferIDs.filter({ winbackOfferID in
            availableWinBackOfferIDs.contains(winbackOfferID)
        })
    }
}
