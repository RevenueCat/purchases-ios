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
                        activeSubscriptionsView
                            .padding(.top, 16)
                    }

                    if !viewModel.inactiveSubscriptions.isEmpty {
                        inactiveSubscriptionsView
                            .padding(.top, 16)
                    }

                    if !viewModel.nonSubscriptions.isEmpty {
                        otherPurchasesView
                            .padding(.top, 16)
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
                customerInfo: CustomerInfoFixtures.customerInfoWithAppleSubscriptions,
                isLoading: false,
                activeSubscriptions: [
                    .yearlyExpiring()
                ],
                inactiveSubscriptions: [
                    .monthlyRenewing
                ],
                nonSubscriptions: [
                    .consumable
                ],
                purchasesProvider: MockCustomerCenterPurchases()
            )
        )
    }
}
#endif

#endif
