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
            LabelValueRow(label: "Product Name:", value: productName ?? "")
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

#if DEBUG
            LabelValueRow(label: "Product ID:", value: subscriptionInfo.productIdentifier)
#endif
            LabelValueRow(label: "Purchase Date:", value: formattedDate(subscriptionInfo.purchaseDate))

            if subscriptionInfo.isActive {
                if let originalPurchaseDate = subscriptionInfo.originalPurchaseDate,
                   originalPurchaseDate != subscriptionInfo.purchaseDate {
                    LabelValueRow(label: "Renewed On:", value: formattedDate(originalPurchaseDate))
                }
            }

            if let expiresDate = subscriptionInfo.expiresDate {
                let label = subscriptionInfo.willRenew ? "Next Renewal Date:" : "Expires Date:"
                LabelValueRow(label: label, value: formattedDate(expiresDate))
            }

            LabelValueRow(label: "Active:", value: subscriptionInfo.isActive ? "Yes" : "No")

            LabelValueRow(
                label: "Store:",
                value: {
                    switch subscriptionInfo.store {
                    case .appStore: return "Apple App Store"
                    case .macAppStore: return "Mac App Store"
                    case .playStore: return "Google Play Store"
                    case .stripe: return "Stripe"
                    case .promotional: return "Promotional"
                    case .amazon: return "Amazon Store"
                    case .rcBilling: return "Web"
                    case .external: return "External Purchases"
                    case .unknownStore: return "Unknown Store"
                    }
                }()
            )

#if DEBUG
            LabelValueRow(label: "Sandbox Mode:", value: subscriptionInfo.isSandbox ? "Yes" : "No")
#endif

            if let unsubscribeDetectedAt = subscriptionInfo.unsubscribeDetectedAt {
                LabelValueRow(label: "Unsubscribed At:", value: formattedDate(unsubscribeDetectedAt))
            }

            if let billingIssuesDetectedAt = subscriptionInfo.billingIssuesDetectedAt {
                LabelValueRow(label: "Billing Issue Detected At:", value: formattedDate(billingIssuesDetectedAt))
            }

            if let gracePeriodExpiresDate = subscriptionInfo.gracePeriodExpiresDate {
                LabelValueRow(label: "Grace Period Expires At:", value: formattedDate(gracePeriodExpiresDate))
            }

            if subscriptionInfo.ownershipType != .unknown {
                LabelValueRow(
                    label: "Ownership Type:",
                    value: subscriptionInfo.ownershipType == .purchased
                    ? "Direct purchase" : "Shared through family member"
                )
            }
            if subscriptionInfo.periodType != .normal {
                LabelValueRow(
                    label: "Period Type:",
                    value: subscriptionInfo.periodType == .intro ? "Introductory Price" : "Trial Period"
                )
            }

            if let refundedAt = subscriptionInfo.refundedAt {
                LabelValueRow(label: "Refunded At:", value: formattedDate(refundedAt))
            }

#if DEBUG
            if let storeTransactionId = subscriptionInfo.storeTransactionId {
                LabelValueRow(label: "Transaction ID:", value: storeTransactionId)
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
