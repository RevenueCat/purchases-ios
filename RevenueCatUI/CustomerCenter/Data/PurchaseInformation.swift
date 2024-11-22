//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionInformation.swift
//
//
//  Created by Cesar de la Vega on 28/5/24.
//

import Foundation
import RevenueCat

// swiftlint:disable nesting
struct PurchaseInformation {

    let title: String?
    let durationTitle: String?
    let explanation: Explanation
    let price: PriceDetails
    let expirationOrRenewal: ExpirationOrRenewal?
    let productIdentifier: String
    let store: Store

    init(title: String,
         durationTitle: String,
         explanation: Explanation,
         price: PriceDetails,
         expirationOrRenewal: ExpirationOrRenewal?,
         willRenew: Bool,
         productIdentifier: String,
         active: Bool,
         store: Store
    ) {
        self.title = title
        self.durationTitle = durationTitle
        self.explanation = explanation
        self.price = price
        self.expirationOrRenewal = expirationOrRenewal
        self.productIdentifier = productIdentifier
        self.store = store
    }

    init(explanation: Explanation,
         price: PriceDetails,
         expirationOrRenewal: ExpirationOrRenewal?,
         willRenew: Bool,
         productIdentifier: String,
         active: Bool,
         store: Store
    ) {
        self.title = nil
        self.durationTitle = nil
        self.explanation = explanation
        self.price = price
        self.expirationOrRenewal = expirationOrRenewal
        self.productIdentifier = productIdentifier
        self.store = store
    }

    init(entitlement: EntitlementInfo,
         subscribedProduct: StoreProduct? = nil,
         dateFormatter: DateFormatter = DateFormatter()) {
        dateFormatter.dateStyle = .medium

        self.title = subscribedProduct?.localizedTitle
        self.explanation = entitlement.explanation
        self.durationTitle = subscribedProduct?.subscriptionPeriod?.durationTitle
        self.price = entitlement.priceBestEffort(product: subscribedProduct)
        self.expirationOrRenewal = entitlement.expirationOrRenewal(dateFormatter: dateFormatter)
        self.productIdentifier = entitlement.productIdentifier
        self.store = entitlement.store
    }

    init(product: StoreProduct,
         expirationDate: Date?,
         dateFormatter: DateFormatter = DateFormatter()) {
        // We don't have enough information to determine if the subscription will renew or not because we
        // are loading the information from the product without entitlement information.
        // We also assume that the subscription is active.
        // We also assume that the subscription will renew the earliest possible renewal date and this is the
        // product with the earliest renewal date.
        dateFormatter.dateStyle = .medium

        self.title = product.localizedTitle
        self.explanation = .earliestRenewal
        self.durationTitle = product.subscriptionPeriod?.durationTitle
        self.price = .paid(product.localizedPriceString)
        if let dateString = expirationDate.map({ dateFormatter.string(from: $0) }) {
            let date = PurchaseInformation.ExpirationOrRenewal.Date.date(dateString)
            self.expirationOrRenewal = PurchaseInformation.ExpirationOrRenewal(label: .expires,
                                                                               date: date)
        } else {
            self.expirationOrRenewal = nil
        }
        self.productIdentifier = product.productIdentifier
        self.store = .appStore
    }

    init(subscribedProduct: StoreProduct,
         subscription: SubscriptionInfo,
         dateFormatter: DateFormatter = DateFormatter()) {
        self.title = subscribedProduct.localizedTitle
        self.durationTitle = subscribedProduct.subscriptionPeriod?.durationTitle
        self.explanation = subscription.expiresDate != nil
            ? (subscription.isActive ? (subscription.willRenew ? .earliestRenewal : .earliestExpiration) : .expired)
            : .lifetime
        self.price = .paid(subscribedProduct.localizedPriceString)
        self.expirationOrRenewal = subscription.expiresDate.map { date in
            let dateString = dateFormatter.string(from: date)
            let label: ExpirationOrRenewal.Label = subscription.isActive 
                ? (subscription.willRenew ? .nextBillingDate : .expires)
                : .expired
            return ExpirationOrRenewal(label: label, date: .date(dateString))
        }
        self.productIdentifier = subscription.productIdentifier
        self.store = subscription.store
    }

    init(subscribedProduct: StoreProduct,
         nonSubscription: NonSubscriptionTransaction,
         dateFormatter: DateFormatter = DateFormatter()) {
        self.title = subscribedProduct.localizedTitle
        self.durationTitle = nil
        self.explanation = .lifetime
        self.price = .paid(subscribedProduct.localizedPriceString)
        self.expirationOrRenewal = nil
        self.productIdentifier = nonSubscription.productIdentifier
        self.store = nonSubscription.store
    }

    init(subscription: SubscriptionInfo,
         dateFormatter: DateFormatter = DateFormatter()) {
        self.title = nil
        self.durationTitle = nil
        self.explanation = subscription.expiresDate != nil
            ? (subscription.isActive ? (subscription.willRenew ? .earliestRenewal : .earliestExpiration) : .expired)
            : .lifetime
        self.price = .unknown
        self.expirationOrRenewal = subscription.expiresDate.map { date in
            let dateString = dateFormatter.string(from: date)
            let label: ExpirationOrRenewal.Label = subscription.isActive 
                ? (subscription.willRenew ? .nextBillingDate : .expires)
                : .expired
            return ExpirationOrRenewal(label: label, date: .date(dateString))
        }
        self.productIdentifier = subscription.productIdentifier
        self.store = subscription.store
    }

    init(nonSubscription: NonSubscriptionTransaction,
         dateFormatter: DateFormatter = DateFormatter()) {
        self.title = nil
        self.durationTitle = nil
        self.explanation = .lifetime
        self.price = .unknown
        self.expirationOrRenewal = nil
        self.productIdentifier = nonSubscription.productIdentifier
        self.store = nonSubscription.store
    }

    // For Apple products with subscription and entitlement
    init(entitlement: EntitlementInfo,
         subscribedProduct: StoreProduct,
         subscription: SubscriptionInfo,
         dateFormatter: DateFormatter = DateFormatter()) {
        dateFormatter.dateStyle = .medium

        self.title = subscribedProduct.localizedTitle
        self.explanation = entitlement.explanation
        self.durationTitle = subscribedProduct.subscriptionPeriod?.durationTitle
        self.price = entitlement.priceBestEffort(product: subscribedProduct)
        self.expirationOrRenewal = entitlement.expirationOrRenewal(dateFormatter: dateFormatter)
        self.productIdentifier = entitlement.productIdentifier
        self.store = entitlement.store
    }

    // For Apple products with non-subscription and entitlement
    init(entitlement: EntitlementInfo,
         subscribedProduct: StoreProduct,
         nonSubscription: NonSubscriptionTransaction,
         dateFormatter: DateFormatter = DateFormatter()) {
        dateFormatter.dateStyle = .medium

        self.title = subscribedProduct.localizedTitle
        self.explanation = entitlement.explanation
        self.durationTitle = subscribedProduct.subscriptionPeriod?.durationTitle
        self.price = entitlement.priceBestEffort(product: subscribedProduct)
        self.expirationOrRenewal = entitlement.expirationOrRenewal(dateFormatter: dateFormatter)
        self.productIdentifier = entitlement.productIdentifier
        self.store = entitlement.store
    }

    // For non-Apple subscription with entitlement
    init(entitlement: EntitlementInfo,
         subscription: SubscriptionInfo,
         dateFormatter: DateFormatter = DateFormatter()) {
        dateFormatter.dateStyle = .medium

        self.title = nil
        self.explanation = entitlement.explanation
        self.durationTitle = nil
        self.price = entitlement.priceBestEffort(product: nil)
        self.expirationOrRenewal = entitlement.expirationOrRenewal(dateFormatter: dateFormatter)
        self.productIdentifier = entitlement.productIdentifier
        self.store = entitlement.store
    }

    // For non-Apple non-subscription with entitlement
    init(entitlement: EntitlementInfo,
         nonSubscription: NonSubscriptionTransaction,
         dateFormatter: DateFormatter = DateFormatter()) {
        dateFormatter.dateStyle = .medium

        self.title = nil
        self.explanation = entitlement.explanation
        self.durationTitle = nil
        self.price = entitlement.priceBestEffort(product: nil)
        self.expirationOrRenewal = entitlement.expirationOrRenewal(dateFormatter: dateFormatter)
        self.productIdentifier = entitlement.productIdentifier
        self.store = entitlement.store
    }

    struct ExpirationOrRenewal {
        let label: Label
        let date: Date

        enum Label {
            case nextBillingDate
            case expires
            case expired
        }

        enum Date: Equatable {
            case never
            case date(String)
        }
    }

    enum PriceDetails: Equatable {
        case free
        case paid(String)
        case unknown
    }

    enum Explanation {
        case promotional
        case google
        case web
        case otherStorePurchase
        case amazon
        case earliestRenewal
        case earliestExpiration
        case expired
        case lifetime
    }

}
// swiftlint:enable nesting

fileprivate extension EntitlementInfo {

    func priceBestEffort(product: StoreProduct?) -> PurchaseInformation.PriceDetails {
        if let product {
            return .paid(product.localizedPriceString)
        }
        if self.store == .promotional {
            return .free
        }
        return .unknown
    }

    func durationTitleBestEffort(productIdentifier: String) -> String? {
        switch self.store {
        case .promotional:
            if productIdentifier.isPromotionalLifetime(store: store) {
                return "Lifetime"
            }
        case .appStore, .macAppStore, .playStore, .stripe, .unknownStore, .amazon, .rcBilling, .external:
            return nil
        @unknown default:
            return nil
        }
        return nil
    }

    func expirationOrRenewal(dateFormatter: DateFormatter) -> PurchaseInformation.ExpirationOrRenewal? {
        guard let date = expirationDateBestEffort(dateFormatter: dateFormatter) else {
            return nil
        }
        let label: PurchaseInformation.ExpirationOrRenewal.Label =
        self.isActive ? (
            self.willRenew ? .nextBillingDate : .expires
        ) : .expired
        return PurchaseInformation.ExpirationOrRenewal(label: label, date: date)

    }

    var explanation: PurchaseInformation.Explanation {
        switch self.store {
        case .appStore, .macAppStore:
            if self.expirationDate != nil {
                if self.isActive {
                    return self.willRenew ? .earliestRenewal : .earliestExpiration
                } else {
                    return .expired
                }
            } else {
                return .lifetime
            }
        case .promotional:
            return .promotional
        case .playStore:
            return .google
        case .stripe, .rcBilling:
            return .web
        case .external, .unknownStore:
            return .otherStorePurchase
        case .amazon:
            return .amazon
        }
    }

    private func expirationDateBestEffort(
        dateFormatter: DateFormatter
    ) -> PurchaseInformation.ExpirationOrRenewal.Date? {
        if self.expirationDate == nil {
            return .never
        }
        switch self.store {
        case .promotional:
            if self.productIdentifier.isPromotionalLifetime(store: self.store) {
                return .never
            }
            if let date = self.expirationDate.map({ dateFormatter.string(from: $0) }) {
                return .date(date)
            }
            return nil
        case .appStore, .macAppStore, .playStore, .stripe, .unknownStore, .amazon, .rcBilling, .external:
            if let date = self.expirationDate.map({ dateFormatter.string(from: $0) }) {
                return .date(date)
            }
            return nil
        @unknown default:
            return nil
        }
    }

}

fileprivate extension String {

    func isPromotionalLifetime(store: Store) -> Bool {
        return self.hasSuffix("_lifetime") && store == .promotional
    }

}
