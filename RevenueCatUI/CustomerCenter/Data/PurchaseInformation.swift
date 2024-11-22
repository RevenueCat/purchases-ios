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
         productIdentifier: String,
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

    init(entitlement: EntitlementInfo? = nil,
         subscribedProduct: StoreProduct? = nil,
         transaction: Transaction,
         dateFormatter: DateFormatter = DateFormatter()) {
        dateFormatter.dateStyle = .medium

        // Title and duration from product if available
        self.title = subscribedProduct?.localizedTitle
        self.durationTitle = subscribedProduct?.subscriptionPeriod?.durationTitle

        // Use entitlement data if available, otherwise derive from transaction
        if let entitlement = entitlement {
            self.explanation = entitlement.explanation
            self.expirationOrRenewal = entitlement.expirationOrRenewal(dateFormatter: dateFormatter)
            self.productIdentifier = entitlement.productIdentifier
            self.store = entitlement.store
            self.price = entitlement.priceBestEffort(product: subscribedProduct)
        } else {
            switch transaction.type {
            case .subscription(let isActive, let willRenew, let expiresDate):
                self.explanation = expiresDate != nil
                    ? (isActive ? (willRenew ? .earliestRenewal : .earliestExpiration) : .expired)
                    : .lifetime
                self.expirationOrRenewal = expiresDate.map { date in
                    let dateString = dateFormatter.string(from: date)
                    let label: ExpirationOrRenewal.Label = isActive 
                        ? (willRenew ? .nextBillingDate : .expires)
                        : .expired
                    return ExpirationOrRenewal(label: label, date: .date(dateString))
                }
            case .nonSubscription:
                self.explanation = .lifetime
                self.expirationOrRenewal = nil
            }
            
            self.productIdentifier = transaction.productIdentifier
            self.store = transaction.store
            self.price = transaction.store == .promotional ? .free 
                : (subscribedProduct.map { .paid($0.localizedPriceString) } ?? .unknown)
        }
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

protocol Transaction {

    var productIdentifier: String { get }
    var store: Store { get }
    var type: TransactionType { get }

}

enum TransactionType {

    case subscription(isActive: Bool, willRenew: Bool, expiresDate: Date?)
    case nonSubscription

}

extension SubscriptionInfo: Transaction {

    var type: TransactionType {
        .subscription(isActive: isActive,
                      willRenew: willRenew,
                      expiresDate: expiresDate)
    }

}

extension NonSubscriptionTransaction: Transaction {

    var type: TransactionType {
        .nonSubscription
    }

}
