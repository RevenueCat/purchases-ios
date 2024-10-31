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
struct SubscriptionInformation {

    let title: String?
    let durationTitle: String?
    let explanation: Explanation
    let price: PriceDetails
    let expirationOrRenewal: ExpirationOrRenewal?
    let productIdentifier: String

    let willRenew: Bool
    let active: Bool

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
        self.willRenew = willRenew
        self.active = active
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
        self.willRenew = willRenew
        self.active = active
        self.store = store
    }

    init(entitlement: EntitlementInfo,
         subscribedProduct: StoreProduct? = nil,
         dateFormatter: DateFormatter = DateFormatter()) {
        // swiftlint:disable:next todo
        // TODO: support non-consumables
        dateFormatter.dateStyle = .medium

        self.title = subscribedProduct?.localizedTitle
        self.explanation = entitlement.explanation
        self.durationTitle = subscribedProduct?.subscriptionPeriod?.durationTitle
        self.price = entitlement.priceBestEffort(product: subscribedProduct)
        self.expirationOrRenewal = entitlement.expirationOrRenewal(dateFormatter: dateFormatter)
        self.willRenew = entitlement.willRenew
        self.productIdentifier = entitlement.productIdentifier
        self.active = entitlement.isActive
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

    func priceBestEffort(product: StoreProduct?) -> SubscriptionInformation.PriceDetails {
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

    func expirationOrRenewal(dateFormatter: DateFormatter) -> SubscriptionInformation.ExpirationOrRenewal? {
        guard let date = expirationDateBestEffort(dateFormatter: dateFormatter) else {
            return nil
        }
        let label: SubscriptionInformation.ExpirationOrRenewal.Label =
        self.isActive ? (
            self.willRenew ? .nextBillingDate : .expires
        ) : .expired
        return SubscriptionInformation.ExpirationOrRenewal(label: label, date: date)

    }

    var explanation: SubscriptionInformation.Explanation {
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
    ) -> SubscriptionInformation.ExpirationOrRenewal.Date? {
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
