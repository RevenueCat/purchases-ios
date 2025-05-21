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
// swiftlint:disable:next type_body_length
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

    /// Used to reload the viewModel
    @Binding
    var activePurchases: [PurchaseInformation]

    /// Used to reload the viewModel
    @Binding
    var nonSubscriptionPurchases: [PurchaseInformation]

    init(screen: CustomerCenterConfigData.Screen,
         activePurchases: Binding<[PurchaseInformation]>,
         nonSubscriptionPurchases: Binding<[PurchaseInformation]>,
         virtualCurrencies: [String: RevenueCat.VirtualCurrencyInfo]?,
         originalAppUserId: String,
         originalPurchaseDate: Date?,
         shouldShowSeeAllPurchases: Bool,
         purchasesProvider: CustomerCenterPurchasesType,
         actionWrapper: CustomerCenterActionWrapper) {
        let viewModel = RelevantPurchasesListViewModel(
            screen: screen,
            actionWrapper: actionWrapper,
            activePurchases: activePurchases.wrappedValue,
            nonSubscriptionPurchases: nonSubscriptionPurchases.wrappedValue,
            virtualCurrencies: virtualCurrencies,
            originalAppUserId: originalAppUserId,
            originalPurchaseDate: originalPurchaseDate,
            shouldShowSeeAllPurchases: shouldShowSeeAllPurchases,
            purchasesProvider: purchasesProvider
        )

        self.init(
            activePurchases: activePurchases,
            nonSubscriptionPurchases: nonSubscriptionPurchases,
            viewModel: viewModel
        )
    }

    // Used for Previews
    fileprivate init(
        activePurchases: Binding<[PurchaseInformation]> = .constant([]),
        nonSubscriptionPurchases: Binding<[PurchaseInformation]> = .constant([]),
        viewModel: RelevantPurchasesListViewModel
    ) {
        self._activePurchases = activePurchases
        self._nonSubscriptionPurchases = nonSubscriptionPurchases
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
                    screen: viewModel.screen,
                    purchaseInformation: viewModel.purchaseInformation,
                    showPurchaseHistory: false,
                    virtualCurrencies: nil, // Don't show virtual currencies when navigated to from here
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
            .overlay {
                RestorePurchasesAlert(
                    isPresented: self.$viewModel.showRestoreAlert,
                    actionWrapper: self.viewModel.actionWrapper
                )
            }
    }

    @ViewBuilder
    var content: some View {
        ScrollViewWithOSBackground {
            LazyVStack(spacing: 0) {
                if viewModel.isEmpty {
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
                } else {
                    if !viewModel.activeSubscriptionPurchases.isEmpty {
                        activeSubscriptionsView
                            .padding(.top, 16)
                    }
                    if !viewModel.activeNonSubscriptionPurchases.isEmpty {
                        otherPurchasesView
                            .padding(.top, 16)
                    }

                    if let virtualCurrencies = viewModel.virtualCurrencies, !virtualCurrencies.isEmpty {
                        VirtualCurrenciesScrollViewWithOSBackgroundSection(
                            virtualCurrencies: virtualCurrencies,
                            purchasesProvider: self.viewModel.purchasesProvider
                        )
                    }
                }

                ScrollViewSection(title: localization[.actionsSectionTitle]) {
                    ActiveSubscriptionButtonsView(viewModel: viewModel)
                        .padding(.top, 16)
                        .padding(.horizontal)
                }

                if viewModel.shouldShowSeeAllPurchases {
                    seeAllSubscriptionsButton
                        .padding(.top, 16)
                }

                accountDetailsView
            }
        }
    }

    @ViewBuilder
    private var activeSubscriptionsView: some View {
        ScrollViewSection(title: localization[.subscriptionsSectionTitle]) {
            ForEach(viewModel.activeSubscriptionPurchases) { purchase in
                Button {
                    viewModel.purchaseInformation = purchase
                } label: {
                    PurchaseInformationCardView(
                        purchaseInformation: purchase,
                        localization: localization
                    )
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .tint(colorScheme == .dark ? .white : .black)
            }
        }
    }

    private var otherPurchasesView: some View {
        let prefix = RelevantPurchasesListViewModel.maxNonSubscriptionsToShow

        return ScrollViewSection(title: localization[.purchasesSectionTitle]) {
            ForEach(viewModel.activeNonSubscriptionPurchases.prefix(prefix)) { purchase in
                Button {
                    viewModel.purchaseInformation = purchase
                } label: {
                    PurchaseInformationCardView(
                        purchaseInformation: purchase,
                        localization: localization
                    )
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .tint(colorScheme == .dark ? .white : .black)
            }
        }
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
        Text(localization[.accountDetails].uppercased())
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .padding(.top, 32)
            .padding(.bottom, 16)

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

    private var buttonsView: some View {
        ForEach(self.viewModel.relevantPathsForPurchase, id: \.id) { path in
            AsyncButton(action: {
                await self.viewModel.handleHelpPath(
                    path,
                    withActiveProductId: viewModel.purchaseInformation?.productIdentifier
                )
            }, label: {
                Group {
                    if self.viewModel.loadingPath?.id == path.id {
                        TintedProgressView()
                    } else {
                        Text(path.title)
                    }
                }
                .padding()
                .background(Color(colorScheme == .light
                                  ? UIColor.systemBackground
                                  : UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding([.leading, .trailing])
            })
            .disabled(self.viewModel.loadingPath != nil)
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
struct ActiveSubscriptionsListView_Previews: PreviewProvider {

    // swiftlint:disable force_unwrapping
    static var previews: some View {
        let purchases = [
            PurchaseInformation.yearlyExpiring(store: .amazon, renewalDate: Date()),
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
                    viewModel: RelevantPurchasesListViewModel(
                        screen: warningOffMock.screens[.management]!,
                        originalAppUserId: "originalAppUserId",
                        activePurchases: purchases,
                        shouldShowSeeAllPurchases: false
                    )
                )
                .environment(\.supportInformation, warningOffMock.support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Active subs - \(colorScheme)")

            CompatibilityNavigationStack {
                RelevantPurchasesListView(
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

            CompatibilityNavigationStack {
                RelevantPurchasesListView(
                    viewModel: RelevantPurchasesListViewModel(
                        screen: warningOnMock.screens[.management]!,
                        originalAppUserId: "originalAppUserId",
                        activePurchases: purchases,
                        virtualCurrencies: CustomerCenterConfigData.fourVirtualCurrencies
                    )
                )
                .environment(\.supportInformation, warningOnMock.support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("4 VCs - \(colorScheme)")

            CompatibilityNavigationStack {
                RelevantPurchasesListView(
                    viewModel: RelevantPurchasesListViewModel(
                        screen: warningOnMock.screens[.management]!,
                        originalAppUserId: "originalAppUserId",
                        activePurchases: purchases,
                        virtualCurrencies: CustomerCenterConfigData.fiveVirtualCurrencies
                    )
                )
                .environment(\.supportInformation, warningOnMock.support)
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
