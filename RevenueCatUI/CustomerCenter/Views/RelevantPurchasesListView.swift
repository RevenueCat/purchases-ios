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

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
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
        originalAppUserId: String,
        originalPurchaseDate: Date?,
        shouldShowSeeAllPurchases: Bool,
        purchasesProvider: CustomerCenterPurchasesType,
        actionWrapper: CustomerCenterActionWrapper
    ) {
        let viewModel = RelevantPurchasesListViewModel(
            screen: screen,
            actionWrapper: actionWrapper,
            originalAppUserId: originalAppUserId,
            originalPurchaseDate: originalPurchaseDate,
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
                if !customerInfoViewModel.hasPurchases {
                    CompatibilityContentUnavailableView(
                        self.viewModel.screen.title,
                        systemImage: "exclamationmark.triangle.fill",
                        description: Text(self.viewModel.screen.subtitle ?? localization[.tryCheckRestore])
                    )
                    .padding()
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                Color(colorScheme == .light
                                      ? UIColor.systemBackground
                                      : UIColor.secondarySystemBackground)
                            )
                            .padding(.horizontal)
                            .padding(.top)
                    )
                    .padding(.bottom, 32)
                } else {
                    if !customerInfoViewModel.activeSubscriptionPurchases.isEmpty {
                        PurchasesInformationSection(
                            title: localization[.subscriptionsSectionTitle],
                            items: customerInfoViewModel.activeSubscriptionPurchases,
                            localization: localization
                        ) {
                            viewModel.purchaseInformation = $0
                        }
                        .tint(colorScheme == .dark ? .white : .black)
                    }

                    if !customerInfoViewModel.activeNonSubscriptionPurchases.isEmpty {
                        PurchasesInformationSection(
                            title: localization[.purchasesSectionTitle],
                            items: activeNonSubscriptionPurchasesToShow,
                            localization: localization
                        ) {
                            viewModel.purchaseInformation = $0
                        }
                        .tint(colorScheme == .dark ? .white : .black)
                    }
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

                accountDetailsView
            }
            .padding(.top, 16)
        }
    }

    private var activeNonSubscriptionPurchasesToShow: [PurchaseInformation] {
        Array(customerInfoViewModel.activeNonSubscriptionPurchases
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

    @ViewBuilder
    private var accountDetailsView: some View {
        ScrollViewSection(title: localization[.accountDetails]) {
            VStack {
                if let originalPurchaseDate = viewModel.originalPurchaseDate {
                    CompatibilityLabeledContent(
                        localization[.dateWhenAppWasPurchased],
                        content: dateFormatter.string(from: originalPurchaseDate)
                    )

                    Divider()
                }

                CompatibilityLabeledContent(
                    localization[.userId],
                    content: viewModel.originalAppUserId
                )
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = viewModel.originalAppUserId
                    } label: {
                        Text(localization[.copy])
                        Image(systemName: "doc.on.clipboard")
                    }
                }
            }
            .padding()
            .background(Color(colorScheme == .light
                              ? UIColor.systemBackground
                              : UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
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
 @available(macOS, unavailable)
 @available(tvOS, unavailable)
 @available(watchOS, unavailable)
 struct RelevantPurchasesListView_Previews: PreviewProvider {

     // swiftlint:disable force_unwrapping
    static var previews: some View {
        let purchases = [
            PurchaseInformation.yearlyExpiring(store: .amazon, renewalDate: PurchaseInformation.defaulRenewalDate),
            PurchaseInformation.yearlyExpiring(store: .appStore),
            .free
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
                RelevantPurchasesListView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: purchases,
                        activeNonSubscriptionPurchases: [],
                        configuration: .default
                    ),
                    viewModel: RelevantPurchasesListViewModel(
                        screen: warningOffMock.screens[.management]!,
                        originalAppUserId: "originalAppUserId",
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
                        activeSubscriptionPurchases: purchases,
                        activeNonSubscriptionPurchases: [],
                        configuration: .default
                    ),
                    viewModel: RelevantPurchasesListViewModel(
                        screen: warningOffMock.screens[.management]!,
                        originalAppUserId: "originalAppUserId",
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
                        screen: warningOnMock.screens[.management]!,
                        originalAppUserId: "originalAppUserId",
                        activePurchases: [],
                        shouldShowSeeAllPurchases: false
                    )
                )
                .environment(\.supportInformation, warningOnMock.support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Empty - \(colorScheme)")
        }
        .environment(\.localization, CustomerCenterConfigData.default.localization)
        .environment(\.appearance, CustomerCenterConfigData.default.appearance)
    }

 }

 #endif

#endif
