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

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @Environment(\.navigationOptions)
    private var navigationOptions: CustomerCenterNavigationOptions

    @StateObject var viewModel: PurchaseHistoryViewModel

    var body: some View {
        contentView
        .compatibleNavigation(
            item: $viewModel.selectedPurchase,
            usesNavigationStack: navigationOptions.usesNavigationStack
        ) {
            PurchaseDetailView(
                viewModel: PurchaseDetailViewModel(
                    purchaseInfo: $0,
                    purchasesProvider: self.viewModel.purchasesProvider
                )
            )
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

    @ViewBuilder
    private var contentView: some View {
        ScrollViewWithOSBackground {
            LazyVStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.errorMessage != nil {
                    ErrorView()
                } else if let info = viewModel.customerInfo {
                    if !info.activeSubscriptions.isEmpty {
                        PurchasesInformationSection(
                            title: localization[.subscriptionsSectionTitle],
                            items: viewModel.activeSubscriptions,
                            localization: localization) { purchase in
                                viewModel.selectedPurchase = purchase
                            }
                            .tint(colorScheme == .dark ? .white : .black)
                    }

                    if !viewModel.inactiveSubscriptions.isEmpty {
                        PurchasesInformationSection(
                            title: localization[.inactive],
                            items: viewModel.inactiveSubscriptions,
                            localization: localization) { purchase in
                                viewModel.selectedPurchase = purchase
                            }
                            .tint(colorScheme == .dark ? .white : .black)
                    }

                    if !viewModel.nonSubscriptions.isEmpty {
                        PurchasesInformationSection(
                            title: localization[.purchasesSectionTitle],
                            items: viewModel.nonSubscriptions,
                            localization: localization) { purchase in
                                viewModel.selectedPurchase = purchase
                            }
                            .tint(colorScheme == .dark ? .white : .black)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var activeSubscriptionsView: some View {
        ScrollViewSection(title: localization[.subscriptionsSectionTitle]) {
            ForEach(viewModel.activeSubscriptions) { purchase in
                Button {
                    viewModel.selectedPurchase = purchase
                } label: {
                    PurchaseInformationCardView(
                        purchaseInformation: purchase,
                        localization: localization,
                        accessibilityIdentifier: ""
                    )
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .tint(colorScheme == .dark ? .white : .black)
            }
        }
    }

    @ViewBuilder
    private var inactiveSubscriptionsView: some View {
        ScrollViewSection(title: "INACTIVE") {
            ForEach(viewModel.inactiveSubscriptions) { purchase in
                Button {
                    viewModel.selectedPurchase = purchase
                } label: {
                    PurchaseInformationCardView(
                        purchaseInformation: purchase,
                        localization: localization,
                        accessibilityIdentifier: ""
                    )
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .tint(colorScheme == .dark ? .white : .black)
            }
        }
    }

    private var otherPurchasesView: some View {
        ScrollViewSection(title: localization[.purchasesSectionTitle]) {
            ForEach(viewModel.nonSubscriptions) { purchase in
                Button {
                    viewModel.selectedPurchase = purchase
                } label: {
                    PurchaseInformationCardView(
                        purchaseInformation: purchase,
                        localization: localization,
                        accessibilityIdentifier: ""
                    )
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .tint(colorScheme == .dark ? .white : .black)
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
        PurchaseHistoryView(
            viewModel: PurchaseHistoryViewModel(
                isLoading: true,
                purchasesProvider: MockCustomerCenterPurchases(
                    customerInfo: CustomerInfoFixtures.customerInfo(
                        subscriptions: [
                            CustomerInfoFixtures.Subscription(
                                id: "id1",
                                store: "\(Store.appStore.rawValue)",
                                purchaseDate: "2022-03-08T17:42:58Z",
                                expirationDate: nil
                            )
                        ],
                        entitlements: [],
                        nonSubscriptions: [
                            CustomerInfoFixtures.NonSubscriptionTransaction(
                                id: "id2",
                                store: "\(Store.playStore.rawValue)",
                                purchaseDate: "2022-03-08T17:42:58Z"
                            )
                        ])
                )
            )
        )
    }
}
#endif

#endif
