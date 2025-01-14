//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseHistoryView.swift
//
//  Created by Facundo Menzella on 14/1/25.
//

#if os(iOS)
import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
struct PurchaseDetailView: View {

    @State var productName: String?
    let subscriptionInfo: SubscriptionInfo

    var body: some View {
        List {
            CompatibilityLabeledContent(String(localized: "Product Name:"), content: productName ?? "")
                .onAppear {
                    Task {
                        guard
                            let product = await Purchases.shared.products([subscriptionInfo.productIdentifier]).first
                        else {
                            return
                        }

                        productName = product.localizedTitle
                    }
                }

            CompatibilityLabeledContent(String(localized: "Purchase Date:"), content: formattedDate(subscriptionInfo.purchaseDate))

            if subscriptionInfo.isActive {
                if let originalPurchaseDate = subscriptionInfo.originalPurchaseDate,
                   originalPurchaseDate != subscriptionInfo.purchaseDate {
                    CompatibilityLabeledContent(String(localized: "Renewed On:"), content: formattedDate(originalPurchaseDate))
                }
            }

            if let expiresDate = subscriptionInfo.expiresDate {
                CompatibilityLabeledContent(
                    String(localized: subscriptionInfo.willRenew ? "Next Renewal Date:" : "Expires Date:"),
                    content: formattedDate(expiresDate)
                )
            }

            CompatibilityLabeledContent(String(localized: "Active:"), content: subscriptionInfo.isActive ? String(localized: "Yes") : String(localized: "No"))

            CompatibilityLabeledContent(String(localized: "Store:"), content: subscriptionInfo.localizedStore)

            if let unsubscribeDetectedAt = subscriptionInfo.unsubscribeDetectedAt {
                CompatibilityLabeledContent(String(localized: "Unsubscribed At:"), content: formattedDate(unsubscribeDetectedAt))
            }

            if let billingIssuesDetectedAt = subscriptionInfo.billingIssuesDetectedAt {
                CompatibilityLabeledContent(String(localized: "Billing Issue Detected At:"), content: formattedDate(billingIssuesDetectedAt))
            }

            if let gracePeriodExpiresDate = subscriptionInfo.gracePeriodExpiresDate {
                CompatibilityLabeledContent(String(localized: "Grace Period Expires At:"), content: formattedDate(gracePeriodExpiresDate))
            }

            if subscriptionInfo.ownershipType != .unknown {
                CompatibilityLabeledContent(String(localized: "Ownership Type:"), content: subscriptionInfo.ownershipType == .purchased
                                            ? "Direct purchase" : "Shared through family member")
            }
            if subscriptionInfo.periodType != .normal {
                CompatibilityLabeledContent(String(localized: "Period Type:"), content: subscriptionInfo.periodType == .intro ? "Introductory Price" : "Trial Period")
            }

            if let refundedAt = subscriptionInfo.refundedAt {
                CompatibilityLabeledContent(String(localized: "Refunded At:"), content: formattedDate(refundedAt))
            }

#if DEBUG
            CompatibilityLabeledContent(String(localized: "Product ID:"), content: subscriptionInfo.productIdentifier)
            CompatibilityLabeledContent(String(localized: "Sandbox Mode:"), content: subscriptionInfo.isSandbox ? "Yes" : "No")
            if let storeTransactionId = subscriptionInfo.storeTransactionId {
                CompatibilityLabeledContent(String(localized: "Transaction ID:"), content: storeTransactionId)
            }
#endif
        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 15.0, *)
private extension PurchaseDetailView {
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

#endif
