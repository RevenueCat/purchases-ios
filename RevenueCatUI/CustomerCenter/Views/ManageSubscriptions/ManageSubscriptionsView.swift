//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ManageSubscriptionsView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionsView: View {

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.supportInformation)
    private var support

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @Environment(\.navigationOptions)
    var navigationOptions

    @StateObject
    private var viewModel: ManageSubscriptionsViewModel

    @Binding
    var activePurchases: [PurchaseInformation]

    init(screen: CustomerCenterConfigData.Screen,
         activePurchases: Binding<[PurchaseInformation]>,
         purchasesProvider: CustomerCenterPurchasesType,
         actionWrapper: CustomerCenterActionWrapper) {
        let viewModel = ManageSubscriptionsViewModel(
            screen: screen,
            actionWrapper: actionWrapper,
            activePurchases: activePurchases.wrappedValue,
            purchasesProvider: purchasesProvider)

        self.init(
            activePurchases: activePurchases,
            viewModel: viewModel
        )
    }

    // Used for Previews
    fileprivate init(
        activePurchases: Binding<[PurchaseInformation]> = .constant([]),
        viewModel: ManageSubscriptionsViewModel
    ) {
        self._activePurchases = activePurchases
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .compatibleNavigation(
                item: $viewModel.purchaseInformation,
                usesNavigationStack: navigationOptions.usesNavigationStack
            ) { _ in
                ManageSubscriptionView(
                    screen: viewModel.screen,
                    purchaseInformation: $viewModel.purchaseInformation,
                    showPurchaseHistory: false,
                    purchasesProvider: self.viewModel.purchasesProvider,
                    actionWrapper: self.viewModel.actionWrapper
                )
                .environment(\.appearance, appearance)
                .environment(\.localization, localization)
                .environment(\.navigationOptions, navigationOptions)
            }
            .compatibleNavigation(
                isPresented: $viewModel.showAllPurchases,
                usesNavigationStack: navigationOptions.usesNavigationStack
            ) {
                PurchaseHistoryView(
                    viewModel: PurchaseHistoryViewModel(purchasesProvider: self.viewModel.purchasesProvider)
                )
                .environment(\.appearance, appearance)
                .environment(\.localization, localization)
                .environment(\.navigationOptions, navigationOptions)
            }
            .onChangeOf(activePurchases) { _ in
                viewModel.updatePurchases(activePurchases)
            }
    }

    @ViewBuilder
    var content: some View {
        List {
            if viewModel.purchasesMightBeDuplicated, support?.shouldWarnCustomersAboutMultipleSubscriptions == true {
                CompatibilityContentUnavailableView(
                    localization[.youMayHaveDuplicatedSubscriptionsTitle],
                    systemImage: "exclamationmark.square",
                    description: Text(
                        localization[.youMayHaveDuplicatedSubscriptionsSubtitle]
                    )
                )
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            Color(colorScheme == .light
                                  ? UIColor.systemBackground
                                  : UIColor.secondarySystemBackground)
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                )
            }

            if viewModel.activePurchases.isEmpty {
                let fallbackDescription = localization[.tryCheckRestore]

                Section {
                    CompatibilityContentUnavailableView(
                        self.viewModel.screen.title,
                        systemImage: "exclamationmark.triangle.fill",
                        description: Text(self.viewModel.screen.subtitle ?? fallbackDescription)
                    )
                }

                Section {
                    ManageSubscriptionsButtonsView(
                        viewModel: self.viewModel
                    )
                }

            } else {
                Section(localization[.activeSubscriptions]) {
                    ForEach(viewModel.activePurchases) { purchase in
                        Button {
                            viewModel.purchaseInformation = purchase
                        } label: {
                            CompatibilityLabeledContent {
                                if purchase.title?.isEmpty == true {
                                    Text(purchase.productIdentifier)
                                } else {
                                    Text(purchase.title ?? "")
                                }
                            } content: {
                                Image(systemName: "chevron.forward")
                            }
                        }
                    }
                }

                if support?.displayPurchaseHistoryLink == true {
                    Button {
                        viewModel.showAllPurchases = true
                    } label: {
                        CompatibilityLabeledContent(localization[.seeAllPurchases]) {
                            Image(systemName: "chevron.forward")
                        }
                    }
                }
            }
        }
        .applyIf(self.viewModel.screen.type == .management, apply: {
            $0.navigationTitle(self.viewModel.screen.title)
                .navigationBarTitleDisplayMode(.inline)
         })
    }
}

#if DEBUG
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionsView_Previews: PreviewProvider {

    // swiftlint:disable force_unwrapping
    static var previews: some View {
        let purchases = [
            CustomerCenterConfigData.subscriptionInformationYearlyExpiring(store: .amazon),
            CustomerCenterConfigData.subscriptionInformationMonthlyRenewing,
            CustomerCenterConfigData.subscriptionInformationFree
        ]

        let warningOffMock = CustomerCenterConfigData.mock(
            displayPurchaseHistoryLink: true
        )

        let warningOnMock = CustomerCenterConfigData.mock(
            displayPurchaseHistoryLink: true,
            shouldWarnCustomersAboutMultipleSubscriptions: true
        )

        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            CompatibilityNavigationStack {
                ManageSubscriptionsView(
                    viewModel: ManageSubscriptionsViewModel(
                        screen: warningOffMock.screens[.management]!,
                        activePurchases: purchases
                    )
                )
                .environment(\.supportInformation, warningOffMock.support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Active subs - \(colorScheme)")

            CompatibilityNavigationStack {
                ManageSubscriptionsView(
                    viewModel: ManageSubscriptionsViewModel(
                        screen: warningOnMock.screens[.management]!,
                        activePurchases: purchases
                    )
                )
                .environment(\.supportInformation, warningOnMock.support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Dup subs warning - \(colorScheme)")
        }
        .environment(\.localization, CustomerCenterConfigData.default.localization)
        .environment(\.appearance, CustomerCenterConfigData.default.appearance)
    }

}

#endif

#endif
