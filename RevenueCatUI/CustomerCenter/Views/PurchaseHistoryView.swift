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
//  Created by RevenueCat on 3/7/24.
//

#if os(iOS)
import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
struct PurchaseHistoryView: View {
    @State private var customerInfo: CustomerInfo?
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List {
                if let info = customerInfo {
                    // Active Subscriptions Section
                    if !info.activeSubscriptions.isEmpty {
                        Section(header: Text("Active Subscriptions")) {
                            ForEach(Array(info.subscriptionsByProductIdentifier), id: \.self.key) { _, subscription in
                                PurchaseRow(subscriptionInfo: subscription)
                            }
                        }
                    }

                    // Non-Subscription Purchases Section
//                    if !info.nonSubscriptions.isEmpty {
//                        Section(header: Text("Non-Subscription Purchases")) {
//                            ForEach(info.nonSubscriptions, id: \.transactionIdentifier) { transaction in
//                                PurchaseRow(
//                                    title: "Purchase: \(transaction.productIdentifier)",
//                                    description: "Purchased on \(dateFormatter.string(from: transaction.purchaseDate))",
//                                    price: "$4.99" // Placeholder price
//                                    purchaseDate: transaction.purchaseDate
//                                )
//                            }
//                        }
//                    }

                    // Account Details Section
                    Section(header: Text("Account Details")) {
                        LabelValueRow(label: "Date when app was first purchased:", value: dateFormatter.string(from: info.originalPurchaseDate!))
                        LabelValueRow(label: "App User ID", value: info.originalAppUserId)
                    }
                }
            }
            .navigationTitle("Purchase History")
            .listStyle(InsetGroupedListStyle())
            .onAppear(perform: fetchCustomerInfo)
        }
    }

    private func expirationDescription(for productId: String, in info: CustomerInfo) -> String {
        if let expirationDate = info.expirationDate(forProductIdentifier: productId) {
            return "Expires on \(dateFormatter.string(from: expirationDate))"
        } else {
            return "No expiration date available"
        }
    }

    private func fetchCustomerInfo() {
        Purchases.shared.getCustomerInfo { (info, error) in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.customerInfo = info
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
struct PurchaseRow: View {
    let subscriptionInfo: SubscriptionInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            LabelValueRow(label: "Product ID:", value: subscriptionInfo.productIdentifier)
            LabelValueRow(label: "Purchase Date:", value: formattedDate(subscriptionInfo.purchaseDate))
            if let originalPurchaseDate = subscriptionInfo.originalPurchaseDate {
                LabelValueRow(label: "Original Purchase Date:", value: formattedDate(originalPurchaseDate))
            }
            if let expiresDate = subscriptionInfo.expiresDate {
                LabelValueRow(label: "Expires Date:", value: formattedDate(expiresDate))
            }
            LabelValueRow(label: "Store:", value: "\(subscriptionInfo.store.rawValue)")
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
            if let storeTransactionId = subscriptionInfo.storeTransactionId {
                LabelValueRow(label: "Transaction ID:", value: storeTransactionId)
            }
            LabelValueRow(label: "Active:", value: subscriptionInfo.isActive ? "Yes" : "No")
            LabelValueRow(label: "Will Renew:", value: subscriptionInfo.willRenew ? "Yes" : "No")
        }
        .padding(.vertical, 5)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct LabelValueRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct PurchaseHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseHistoryView()
    }
}
#endif

#endif
