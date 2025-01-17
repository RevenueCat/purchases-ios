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
                    Section(header: Text(String(localized: "Active Subscriptions"))) {
                        ForEach(viewModel.activeSubscriptions) { activeSubscription in
                            Button {
                                viewModel.selectedPurchase = activeSubscription
                            } label: {
                                PurchaseLinkView(purchaseInfo: activeSubscription)
                            }
                        }
                    }

                    Section(header: Text(String(localized: "Expired Subscriptions"))) {
                        ForEach(viewModel.inactiveSubscriptions) { inactiveSubscription in
                            Button {
                                viewModel.selectedPurchase = inactiveSubscription
                            } label: {
                                PurchaseLinkView(purchaseInfo: inactiveSubscription)
                            }
                        }
                    }
                }

                // Non-Subscription Purchases Section
                // todo: add information for non subscriptions
                // and get product type and other info directly from StoreKit or backend

                if !viewModel.nonSubscriptions.isEmpty {
                    Section(header: Text(String(localized: "Other"))) {
                        ForEach(viewModel.nonSubscriptions) { inactiveSubscription in
                            Button {
                                viewModel.selectedPurchase = inactiveSubscription
                            } label: {
                                PurchaseLinkView(purchaseInfo: inactiveSubscription)
                            }
                        }
                    }
                }

                // Account Details Section
                // todo: make these easy to copy
                Section(header: Text(String(localized: "Account Details"))) {
                    CompatibilityLabeledContent(
                        String(localized: "Date when app was first purchased"),
                        content: dateFormatter.string(from: info.originalPurchaseDate!)
                    )

                    CompatibilityLabeledContent(
                        String(localized: "User ID"),
                        content: info.originalAppUserId
                    )
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = info.originalAppUserId
                        } label: {
                            Text("Copy")
                            Image(systemName: "doc.on.clipboard")
                        }
                    }
                }
            }
        }
        .compatibleNavigation(item: $viewModel.selectedPurchase) {
            PurchaseDetailView(
                viewModel: PurchaseDetailViewModel(purchaseInfo: $0))
        }
        .navigationTitle(String(localized: "Purchase History"))
        .listStyle(.insetGrouped)
        .onAppear {
            Task {
                await viewModel.didAppear()
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
