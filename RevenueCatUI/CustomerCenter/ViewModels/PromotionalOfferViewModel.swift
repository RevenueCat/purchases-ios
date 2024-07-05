//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PromotionalOfferViewModel.swift
//
//
//  Created by Cesar de la Vega on 17/6/24.
//

import Foundation
import RevenueCat

#if !os(macOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class PromotionalOfferViewModel: ObservableObject {

    typealias CustomerInfoFetcher = @Sendable () async throws -> CustomerInfo
    typealias PurchasesProvider = @Sendable (_ productIdentifiers: [String]) async -> [StoreProduct]

    @Published
    var product: StoreProduct?
    @Published
    var promotionalOffer: PromotionalOffer?
    @Published
    var transaction: StoreTransaction?
    @Published
    var promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer?
    @Published
    var localization: CustomerCenterConfigData.Localization?
    @Published
    var error: Error?

    private var purchasesProvider: PromotionalOfferPurchaseType

    convenience init() {
        self.init(product: nil, promotionalOffer: nil, promoOfferDetails: nil, localization: nil)
    }

    convenience init(product: StoreProduct?,
                     promotionalOffer: PromotionalOffer?,
                     promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer?,
                     localization: CustomerCenterConfigData.Localization?) {
        self.init(product: product,
                  promotionalOffer: promotionalOffer,
                  promoOfferDetails: promoOfferDetails,
                  localization: localization,
                  purchasesProvider: PromotionalOfferPurchases())
    }

    // @PublicForExternalTesting
    init(product: StoreProduct?,
         promotionalOffer: PromotionalOffer?,
         promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer?,
         localization: CustomerCenterConfigData.Localization?,
         purchasesProvider: PromotionalOfferPurchaseType) {
        self.product = product
        self.promotionalOffer = promotionalOffer
        self.promoOfferDetails = promoOfferDetails
        self.localization = localization
        self.purchasesProvider = purchasesProvider
    }

    func purchasePromo() async {
        guard let promotionalOffer = self.promotionalOffer,
              let product = self.product else {
            Logger.warning(Strings.promo_offer_not_loaded)
            return
        }

        do {
            let purchase = try await Purchases.shared.purchase(product: product, promotionalOffer: promotionalOffer)
            self.transaction = purchase.transaction
        } catch {
            self.error = error
        }
    }

    func loadPromo(promotionalOfferId: String) async {
        do {
            let customerInfo = try await self.purchasesProvider.customerInfo()

            guard let currentEntitlement = customerInfo.currentEntitlement(),
                  let subscribedProduct = await purchasesProvider.products([currentEntitlement.productIdentifier]).first
            else {
                Logger.warning(Strings.could_not_offer_for_active_subscriptions)
                self.error = CustomerCenterError.couldNotFindSubscriptionInformation
                return
            }

            guard let discount = subscribedProduct.discounts.first(where: {
                $0.offerIdentifier == promotionalOfferId
            }) else {
                Logger.warning(Strings.could_not_offer_for_active_subscriptions)
                self.error = CustomerCenterError.couldNotFindSubscriptionInformation
                return
            }

            let promotionalOffer = try await Purchases.shared.promotionalOffer(forProductDiscount: discount,
                                                                               product: subscribedProduct)
            self.promotionalOffer = promotionalOffer
            self.product = subscribedProduct
        } catch {
            Logger.warning(Strings.error_fetching_promotional_offer(error))
            self.error = CustomerCenterError.couldNotFindOfferForActiveProducts
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private final class PromotionalOfferPurchases: PromotionalOfferPurchaseType {

    func customerInfo() async throws -> RevenueCat.CustomerInfo {
        try await Purchases.shared.customerInfo()
    }

    func products(_ productIdentifiers: [String]) async -> [StoreProduct] {
        await Purchases.shared.products(productIdentifiers)
    }

}

private extension CustomerInfo {

    func currentEntitlement() -> EntitlementInfo? {
        return self.entitlements
            .active
            .values
            .lazy
            .filter { $0.store == .appStore }
            .sorted { lhs, rhs in
                let lhsDateSeconds = lhs.expirationDate?.timeIntervalSince1970 ?? TimeInterval.greatestFiniteMagnitude
                let rhsDateSeconds = rhs.expirationDate?.timeIntervalSince1970 ?? TimeInterval.greatestFiniteMagnitude
                return lhsDateSeconds < rhsDateSeconds
            }
            .first
    }

}

#endif
