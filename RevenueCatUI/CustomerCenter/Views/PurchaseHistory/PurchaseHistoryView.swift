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

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @Environment(\.navigationOptions)
    private var navigationOptions: CustomerCenterNavigationOptions

    @StateObject var viewModel: PurchaseHistoryViewModel

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.errorMessage != nil {
                ErrorView()
            } else if let info = viewModel.customerInfo {
                if !info.activeSubscriptions.isEmpty {
                    Section(header: Text(
                        localization[.activeSubscriptions]
                    )) {
                        ForEach(viewModel.activeSubscriptions) { activeSubscription in
                            Button {
                                viewModel.selectedPurchase = activeSubscription
                            } label: {
                                PurchaseLinkView(purchaseInfo: activeSubscription)
                            }
                        }
                    }
                }

                if !viewModel.inactiveSubscriptions.isEmpty {
                    Section(header: Text(
                        localization[.expiredSubscriptions]
                    )) {
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
                if !viewModel.nonSubscriptions.isEmpty {
                    Section(header: Text(
                        localization[.otherPurchases]
                    )) {
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
                Section(header: Text(
                    localization[.accountDetails]
                )) {
                    CompatibilityLabeledContent(
                        localization[.dateWhenAppWasPurchased],
                        content: dateFormatter.string(from: info.originalPurchaseDate!)
                    )

                    CompatibilityLabeledContent(
                        localization[.userId],
                        content: info.originalAppUserId
                    )
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = info.originalAppUserId
                        } label: {
                            Text(localization[.copy])
                            Image(systemName: "doc.on.clipboard")
                        }
                    }
                }
            }
        }
        .compatibleNavigation(
            item: $viewModel.selectedPurchase,
            usesNavigationStack: navigationOptions.usesNavigationStack
        ) {
            PurchaseDetailView(
                viewModel: PurchaseDetailViewModel(purchaseInfo: $0))
            .environment(\.localization, localization)
        }
        .navigationTitle(localization[.purchaseHistory])
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
