//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseHistoryViewModel.swift
//
//
//  Created by Facundo Menzella on 14/1/25.
//

import Foundation
import SwiftUI

import RevenueCat

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class PurchaseDetailViewModel: ObservableObject {

    @Published var items: [PurchaseDetailItem] = []

    var localizedOwnership: String? {
        subscriptionInfo.ownershipType == .familyShared
            ? String(localized: "Shared through family member")
            : nil
    }

    init(subscriptionInfo: SubscriptionInfo) {
        self.subscriptionInfo = subscriptionInfo
    }

    func didAppear() async {
        await fetchProduct()
    }

    // MARK: - Private

    private let subscriptionInfo: SubscriptionInfo
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension PurchaseDetailViewModel {

    func fetchProduct() async {
        guard
            let product = await Purchases.shared.products([subscriptionInfo.productIdentifier]).first
        else {
            return
        }

        var items: [PurchaseDetailItem] = [
            .productName(product.localizedTitle),
            .status(subscriptionInfo.isActive ? String(localized: "Active") : String(localized: "Inactive"))
        ]

        if let expiresDate = subscriptionInfo.expiresDate {
            if subscriptionInfo.willRenew {
                items.append(.nextRenewalDate(formattedDate(expiresDate)))
            } else {
                items.append(.expiresDate(formattedDate(expiresDate)))
            }
        }

        if let unsubscribeDetectedAt = subscriptionInfo.unsubscribeDetectedAt {
            items.append(.unsubscribeDetectedAt(formattedDate(unsubscribeDetectedAt)))
        }

        if let billingIssuesDetectedAt = subscriptionInfo.billingIssuesDetectedAt {
            items.append(.billingIssuesDetectedAt(formattedDate(billingIssuesDetectedAt)))
        }

        if let gracePeriodExpiresDate = subscriptionInfo.gracePeriodExpiresDate {
            items.append(.gracePeriodExpiresDate(formattedDate(gracePeriodExpiresDate)))
        }

        if subscriptionInfo.periodType != .normal {
            items.append(.periodType(
                subscriptionInfo.periodType == .intro
                    ? String(localized: "Introductory Price")
                    : String(localized: "Trial Period"))
            )
        }

        if let refundedAt = subscriptionInfo.refundedAt {
            items.append(.refundedAtDate(formattedDate(refundedAt)))
        }

        addDebug(&items)

        await MainActor.run {
            self.items = items
        }
    }

    func addDebug(_ items: inout [PurchaseDetailItem]) {
#if DEBUG
        items.append(contentsOf: [
            .store(subscriptionInfo.localizedStore),
            .productID(subscriptionInfo.productIdentifier),
            .sandbox(subscriptionInfo.isSandbox)
        ])

        if subscriptionInfo.isActive {
            if let originalPurchaseDate = subscriptionInfo.originalPurchaseDate,
               originalPurchaseDate != subscriptionInfo.purchaseDate {
                items.append(.purchaseDate(formattedDate(originalPurchaseDate)))
            }
        }

        if let storeTransactionId = subscriptionInfo.storeTransactionId {
            items.append(.transactionID(storeTransactionId))
        }
#endif
    }
}

@available(iOS 15.0, *)
private extension PurchaseDetailViewModel {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    func formattedDate(_ date: Date) -> String {
        Self.formatter.string(from: date)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
enum PurchaseDetailItem: Identifiable {
    case productName(String?)
    case purchaseDate(String)
    case status(String)

    case nextRenewalDate(String)
    case expiresDate(String)
    case unsubscribeDetectedAt(String)
    case billingIssuesDetectedAt(String)
    case gracePeriodExpiresDate(String)
    case periodType(String)
    case refundedAtDate(String)

    // DEBUG only
    case store(String)
    case productID(String)
    case sandbox(Bool)
    case transactionID(String)

    var label: String {
        switch self {
        case .productName: return String(localized: "Product name")
        case .purchaseDate:  return String(localized: "Original Download Date")
        case .status: return String(localized: "Status")
        case .nextRenewalDate: return String(localized: "Next Renewal")
        case .expiresDate: return String(localized: "Expires")
        case .unsubscribeDetectedAt: return String(localized: "Unsubscribed At")
        case .billingIssuesDetectedAt: return String(localized: "Billing Issue Detected At")
        case .gracePeriodExpiresDate: return String(localized: "Grace Period Expires At")
        case .periodType: return String(localized: "Period Type")
        case .refundedAtDate: return String(localized: "Refunded At")
        case .store: return String(localized: "Store")
        case .productID: return String(localized: "Product ID")
        case .sandbox: return String(localized: "Sandbox")
        case .transactionID: return String(localized: "TransactionID")
        }
    }

    var content: String {
        switch self {
        case let .productName(name): return name ?? "-"

        case .purchaseDate(let value),
                .expiresDate(let value),
                .nextRenewalDate(let value),
                .unsubscribeDetectedAt(let value),
                .billingIssuesDetectedAt(let value),
                .gracePeriodExpiresDate(let value),
                .status(let value),
                .periodType(let value),
                .refundedAtDate(let value),
                .store(let value),
                .productID(let value),
                .transactionID(let value):
            return value

        case .sandbox(let value):
            return value ? "Yes" : "No"
        }
    }

    var isDebugOnly: Bool {
        switch self {
        case .store, .productID, .sandbox, .transactionID:
            return true
        default:
            return false
        }
    }

    var id: String {
        label
    }

}

#endif
