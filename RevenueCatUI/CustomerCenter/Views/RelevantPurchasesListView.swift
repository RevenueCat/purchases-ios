//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RelevantPurchasesListView.swift
//
//  Created by Facundo Menzella on 14/5/25.

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
// swiftlint:disable file_length
struct RelevantPurchasesListView: View {

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @Environment(\.navigationOptions)
    var navigationOptions

    @StateObject
    private var viewModel: RelevantPurchasesListViewModel

    @ObservedObject
    private var customerInfoViewModel: CustomerCenterViewModel

    init(
        customerInfoViewModel: CustomerCenterViewModel,
        screen: CustomerCenterConfigData.Screen,
        shouldShowSeeAllPurchases: Bool,
        purchasesProvider: CustomerCenterPurchasesType,
        actionWrapper: CustomerCenterActionWrapper
    ) {
        let viewModel = RelevantPurchasesListViewModel(
            screen: screen,
            actionWrapper: actionWrapper,
            shouldShowSeeAllPurchases: shouldShowSeeAllPurchases,
            purchasesProvider: purchasesProvider
        )

        self.init(
            customerInfoViewModel: customerInfoViewModel,
            viewModel: viewModel
        )
    }

    // Used for Previews
    fileprivate init(
        customerInfoViewModel: CustomerCenterViewModel,
        viewModel: RelevantPurchasesListViewModel
    ) {
        self.customerInfoViewModel = customerInfoViewModel
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .applyIf(self.viewModel.screen.type == .management, apply: {
                $0.navigationTitle(self.viewModel.screen.title)
                    .navigationBarTitleDisplayMode(.inline)
            })
            .compatibleNavigation(
                item: $viewModel.purchaseInformation,
                usesNavigationStack: navigationOptions.usesNavigationStack
            ) { _ in
                SubscriptionDetailView(
                    customerInfoViewModel: customerInfoViewModel,
                    screen: viewModel.screen,
                    purchaseInformation: viewModel.purchaseInformation,
                    showPurchaseHistory: false,
                    showVirtualCurrencies: false,
                    allowsMissingPurchaseAction: false,
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
            .compatibleNavigation(
                isPresented: $viewModel.showAllInAppCurrenciesScreen,
                usesNavigationStack: navigationOptions.usesNavigationStack
            ) {
                VirtualCurrencyBalancesScreen(
                    viewModel: VirtualCurrencyBalancesScreenViewModel(
                        purchasesProvider: self.viewModel.purchasesProvider
                    )
                )
                .environment(\.appearance, appearance)
                .environment(\.localization, localization)
                .environment(\.navigationOptions, navigationOptions)
            }
            .overlay {
                RestorePurchasesAlert(
                    isPresented: self.$viewModel.showRestoreAlert,
                    actionWrapper: self.viewModel.actionWrapper,
                    customerCenterViewModel: customerInfoViewModel
                )
            }
    }

    @ViewBuilder
    var content: some View {
        ScrollViewWithOSBackground {
            LazyVStack(spacing: 0) {
                if !customerInfoViewModel.subscriptionsSection.isEmpty {
                    PurchasesInformationSection(
                        title: localization[.subscriptionsSectionTitle],
                        items: customerInfoViewModel.subscriptionsSection,
                        localization: localization
                    ) {
                        viewModel.purchaseInformation = $0
                    }
                    .tint(colorScheme == .dark ? .white : .black)
                } else {
                    ScrollViewSection(title: localization[.subscriptionsSectionTitle]) {
                        NoSubscriptionsCardView(localization: localization)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                    }
                }

                if !customerInfoViewModel.nonSubscriptionsSection.isEmpty {
                    PurchasesInformationSection(
                        title: localization[.purchasesSectionTitle],
                        items: activeNonSubscriptionPurchasesToShow,
                        localization: localization
                    ) {
                        viewModel.purchaseInformation = $0
                    }
                    .tint(colorScheme == .dark ? .white : .black)
                }

                if let virtualCurrencies = customerInfoViewModel.virtualCurrencies,
                   !virtualCurrencies.all.isEmpty,
                    customerInfoViewModel.shouldShowVirtualCurrencies {
                    VirtualCurrenciesScrollViewWithOSBackgroundSection(
                        virtualCurrencies: virtualCurrencies,
                        onSeeAllInAppCurrenciesButtonTapped: self.viewModel.displayAllInAppCurrenciesScreen
                    )

                    Spacer().frame(height: 16)
                }

                ScrollViewSection(title: localization[.actionsSectionTitle]) {
                    ActiveSubscriptionButtonsView(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                }

                if viewModel.shouldShowSeeAllPurchases {
                    seeAllSubscriptionsButton
                        .padding(.bottom, 32)
                } else {
                    Spacer().frame(height: 16)
                }

                AccountDetailsSection(
                    originalPurchaseDate: customerInfoViewModel.originalPurchaseDate,
                    originalAppUserId: customerInfoViewModel.originalAppUserId,
                    localization: localization
                )
            }
            .padding(.top, 16)
        }
    }

    private var activeNonSubscriptionPurchasesToShow: [PurchaseInformation] {
        Array(customerInfoViewModel.nonSubscriptionsSection
            .prefix(RelevantPurchasesListViewModel.maxNonSubscriptionsToShow))
    }

    private var seeAllSubscriptionsButton: some View {
        Button {
            viewModel.showAllPurchases = true
        } label: {
            CompatibilityLabeledContent(localization[.seeAllPurchases]) {
                Image(systemName: "chevron.forward")
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(colorScheme == .light
                              ? UIColor.systemBackground
                              : UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .tint(colorScheme == .dark ? .white : .black)
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
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct RelevantPurchasesListView_Previews: PreviewProvider {

    // swiftlint:disable force_unwrapping
    static var previews: some View {
        let purchases = [
            PurchaseInformation.mock(
                store: .amazon,
                isExpired: false,
                renewalDate: PurchaseInformation.defaulRenewalDate
            ),
            PurchaseInformation.mock(
                store: .appStore,
                isExpired: false
            ),
            .free
        ]

        let warningOffMock = CustomerCenterConfigData.mock(
            displayPurchaseHistoryLink: true
        )

        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            CompatibilityNavigationStack {
                RelevantPurchasesListView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: purchases,
                        activeNonSubscriptionPurchases: [],
                        configuration: .default
                    ),
                    viewModel: RelevantPurchasesListViewModel(
                        screen: warningOffMock.screens[.management]!,
                        shouldShowSeeAllPurchases: true
                    )
                )
                .environment(\.supportInformation, warningOffMock.support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Active subs - \(colorScheme)")

            CompatibilityNavigationStack {
                RelevantPurchasesListView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: [],
                        activeNonSubscriptionPurchases: [.consumable, .lifetime],
                        configuration: .default
                    ),
                    viewModel: RelevantPurchasesListViewModel(
                        screen: warningOffMock.screens[.management]!,
                        shouldShowSeeAllPurchases: true
                    )
                )
                .environment(\.supportInformation, warningOffMock.support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("No subscriptions - \(colorScheme)")

            CompatibilityNavigationStack {
                RelevantPurchasesListView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: [],
                        activeNonSubscriptionPurchases: [],
                        configuration: .default
                    ),
                    viewModel: RelevantPurchasesListViewModel(
                        screen: warningOffMock.screens[.management]!,
                        shouldShowSeeAllPurchases: true
                    )
                )
                .environment(\.supportInformation, warningOffMock.support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Empty - \(colorScheme)")

            CompatibilityNavigationStack {
                RelevantPurchasesListView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: [],
                        activeNonSubscriptionPurchases: [.consumable, .lifetime],
                        configuration: .default
                    ),
                    viewModel: RelevantPurchasesListViewModel(
                        screen: warningOffMock.screens[.management]!,
                        shouldShowSeeAllPurchases: true
                    )
                )
                .environment(\.supportInformation, warningOffMock.support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("No subscriptions - \(colorScheme)")

            CompatibilityNavigationStack {
                RelevantPurchasesListView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: purchases,
                        activeNonSubscriptionPurchases: [],
                        configuration: .default
                    ),
                    viewModel: RelevantPurchasesListViewModel(
                        screen: warningOffMock.screens[.management]!,
                        activePurchases: purchases,
                        nonSubscriptionPurchases: [.consumable, .lifetime],
                        shouldShowSeeAllPurchases: false
                    )
                )
                .environment(\.supportInformation, warningOffMock.support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Active subs & other - \(colorScheme)")

            CompatibilityNavigationStack {
                RelevantPurchasesListView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: [],
                        activeNonSubscriptionPurchases: [],
                        configuration: .default
                    ),
                    viewModel: RelevantPurchasesListViewModel(
                        screen: warningOffMock.screens[.management]!,
                        activePurchases: [],
                        shouldShowSeeAllPurchases: false
                    )
                )
                .environment(\.supportInformation, warningOffMock.support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Empty - \(colorScheme)")

            CompatibilityNavigationStack {
                RelevantPurchasesListView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: purchases,
                        activeNonSubscriptionPurchases: [],
                        virtualCurrencies: VirtualCurrenciesFixtures.fourVirtualCurrencies,
                        configuration: CustomerCenterConfigData.mock(displayVirtualCurrencies: true)
                    ),
                    viewModel: RelevantPurchasesListViewModel(
                        screen: warningOffMock.screens[.management]!,
                        activePurchases: purchases,
                        shouldShowSeeAllPurchases: false
                    )
                )
                .environment(\.supportInformation, warningOffMock.support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("4 VCs - \(colorScheme)")

            CompatibilityNavigationStack {
                RelevantPurchasesListView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: purchases,
                        activeNonSubscriptionPurchases: [],
                        virtualCurrencies: VirtualCurrenciesFixtures.fiveVirtualCurrencies,
                        configuration: CustomerCenterConfigData.mock(displayVirtualCurrencies: true)
                    ),
                    viewModel: RelevantPurchasesListViewModel(
                        screen: warningOffMock.screens[.management]!,
                        activePurchases: purchases,
                        shouldShowSeeAllPurchases: false
                    )
                )
                .environment(\.supportInformation, warningOffMock.support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("5 VCs - \(colorScheme)")
        }
        .environment(\.localization, CustomerCenterConfigData.default.localization)
        .environment(\.appearance, CustomerCenterConfigData.default.appearance)
    }

}

#endif

#endif
