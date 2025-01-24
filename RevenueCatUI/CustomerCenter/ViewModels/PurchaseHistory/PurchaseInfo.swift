//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseInfo.swift
//
//
//  Created by Facundo Menzella on 15/1/25.
//

#if os(iOS)
import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
enum PurchaseInfo: Identifiable {
    case subscription(SubscriptionInfo)
    case nonSubscription(NonSubscriptionTransaction)

    var id: String {
        productIdentifier
    }

    var productIdentifier: String {
        switch self {
        case let .subscription(info):
            return info.productIdentifier
        case let .nonSubscription(transaction):
            return transaction.productIdentifier
        }
    }

    var isActive: Bool {
        switch self {
        case let .subscription(info):
            return info.isActive
        case .nonSubscription:
            return false
        }
    }

    var paidPrice: String? {
        formattedPrice(price)
    }

    private var price: ProductPaidPrice? {
        switch self {
        case let .subscription(info):
            return info.price
        case .nonSubscription:
            return nil
        }
    }

    var willRenew: Bool {
        switch self {
        case let .subscription(info):
            return info.willRenew
        case .nonSubscription:
            return false
        }
    }

    var purchaseDate: Date {
        switch self {
        case let .subscription(info):
            return info.purchaseDate
        case let .nonSubscription(transaction):
            return transaction.purchaseDate
        }
    }

    var expiresDate: Date? {
        switch self {
        case let .subscription(info):
            return info.expiresDate
        case .nonSubscription:
            return nil
        }
    }

    var purchaseDetailDebugItems: [PurchaseDetailItem] {
#if DEBUG
        debugItems
#else
        []
#endif
    }

    var purchaseDetailItems: [PurchaseDetailItem] {
        var items: [PurchaseDetailItem] = []
        switch self {
        case let .subscription(purchaseInfo):
            if let price = paidPrice {
                items.append(.paidPrice(price))
            }

            items.append(.status(
                purchaseInfo.isActive ? .active : .inactive
            ))

            if let expiresDate = purchaseInfo.expiresDate {
                if purchaseInfo.willRenew {
                    items.append(.nextRenewalDate(formattedDate(expiresDate)))
                } else {
                    items.append(.expiresDate(formattedDate(expiresDate)))
                }
            }

            if let unsubscribeDetectedAt = purchaseInfo.unsubscribeDetectedAt {
                items.append(.unsubscribeDetectedAt(formattedDate(unsubscribeDetectedAt)))
            }

            if let billingIssuesDetectedAt = purchaseInfo.billingIssuesDetectedAt {
                items.append(.billingIssuesDetectedAt(formattedDate(billingIssuesDetectedAt)))
            }

            if let gracePeriodExpiresDate = purchaseInfo.gracePeriodExpiresDate {
                items.append(.gracePeriodExpiresDate(formattedDate(gracePeriodExpiresDate)))
            }

            if purchaseInfo.periodType != .normal {
                items.append(.periodType(
                    purchaseInfo.periodType == .intro ? .introductoryPrice : .trialPeriod
                ))
            }

            if let refundedAt = purchaseInfo.refundedAt {
                items.append(.refundedAtDate(formattedDate(refundedAt)))
            }
        case let .nonSubscription(transaction):
            items.append(.purchaseDate(formattedDate(transaction.purchaseDate)))

        }

        return items
    }
}

@available(iOS 15.0, *)
private extension PurchaseInfo {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    func formattedDate(_ date: Date) -> String {
        Self.formatter.string(from: date)
    }

    func formattedPrice(_ price: ProductPaidPrice?) -> String? {
        guard let price else {
            return nil
        }

        // Not the most performance, but not thread to mutate the currency
        // todo: cache based on currency
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.currencyCode = price.currency

        return formatter.string(from: NSNumber(value: price.amount))
    }

    var debugItems: [PurchaseDetailItem] {
        switch self {
        case .subscription(let purchaseInfo):
            var items: [PurchaseDetailItem] = [
                .store(purchaseInfo.store.localizationKey),
                .productID(purchaseInfo.productIdentifier),
                .sandbox(purchaseInfo.isSandbox)
            ]
            if purchaseInfo.isActive {
                if let originalPurchaseDate = purchaseInfo.originalPurchaseDate,
                   originalPurchaseDate != purchaseInfo.purchaseDate {
                    items.append(.purchaseDate(formattedDate(originalPurchaseDate)))
                }
            }

            if let storeTransactionId = purchaseInfo.storeTransactionId {
                items.append(.transactionID(storeTransactionId))
            }
            return items

        case .nonSubscription(let transaction):
            return [
                .store(transaction.store.localizationKey),
                .productID(transaction.productIdentifier),
                .transactionID(transaction.storeTransactionIdentifier)
            ]
        }
    }
}

#endif
