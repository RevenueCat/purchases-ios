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
                // TODO: make these easy to copy
                Section(header: Text("Account Details")) {
                    CompatibilityLabeledContent(
                        String(localized: "Date when app was first purchased:"),
                        content: dateFormatter.string(from: info.originalPurchaseDate!)
                    )

                    CompatibilityLabeledContent(
                        String(localized: "App User ID"),
                        content: info.originalAppUserId
                    )
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = info.originalAppUserId
                        }) {
                            Text("Copy")
                            Image(systemName: "doc.on.clipboard")
                        }
                    }
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
