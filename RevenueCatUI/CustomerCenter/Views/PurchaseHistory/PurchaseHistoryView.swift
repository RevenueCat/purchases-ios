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
    @StateObject var viewModel: PurchaseHistoryViewModel

    var body: some View {
        List {
            if let info = viewModel.customerInfo {
                if !info.activeSubscriptions.isEmpty {
                    // todo: add the price from the backend
                    Section(header: Text("Active Subscriptions")) {
                        ForEach(viewModel.activeSubscriptions, id: \.productIdentifier) { activeSubscription in
                            Button {
                                viewModel.selectedActiveSubscrition = activeSubscription
                            } label: {
                                PurchaseLinkView(subscriptionInfo: activeSubscription)
                                    .compatibleNavigation(item: $viewModel.selectedActiveSubscrition) {
                                        PurchaseDetailView(subscriptionInfo: $0)
                                    }
                            }
                        }
                    }

                    Section(header: Text("Past Subscriptions")) {
                        ForEach(viewModel.inactiveSubscriptions, id: \.productIdentifier) { inactiveSubscription in
                            Button {
                                viewModel.selectedInactiveSubscription = inactiveSubscription
                            } label: {
                                PurchaseLinkView(subscriptionInfo: inactiveSubscription)
                                    .compatibleNavigation(item: $viewModel.selectedInactiveSubscription) {
                                        PurchaseDetailView(subscriptionInfo: $0)
                                    }
                            }
                        }
                    }
                }

                // Non-Subscription Purchases Section
                // todo: add information for non subscriptions
                // and get product type and other info directly from StoreKit or backend

                // Account Details Section
                // todo: make these easy to copy
                Section(header: Text("Account Details")) {
                    LabelValueRow(label: "Date when app was first purchased:", value: dateFormatter.string(from: info.originalPurchaseDate!))
                    LabelValueRow(label: "App User ID", value: info.originalAppUserId)
                }
            } else {
                // TODO: add fallback
                EmptyView()
            }
        }
        .navigationTitle("Purchase History")
        .listStyle(.insetGrouped)
        .onAppear {
            Task {
                await viewModel.didAppear()
            }
        }
    }

    private func expirationDescription(for productId: String, in info: CustomerInfo) -> String {
        if let expirationDate = info.expirationDate(forProductIdentifier: productId) {
            return "Expires on \(dateFormatter.string(from: expirationDate))"
        } else {
            return "No expiration date available"
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

    @State var productName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
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
        CompatibilityNavigationStack {
            PurchaseHistoryView(viewModel: PurchaseHistoryViewModel())
        }
    }
}
#endif

#endif
