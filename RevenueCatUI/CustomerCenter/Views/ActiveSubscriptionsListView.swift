//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ActiveSubscriptionsListView.swift
//
//  Created by Facundo Menzella on 14/5/25.

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ActiveSubscriptionsListView: View {

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
    private var viewModel: ActiveSubscriptionsListViewModel

    /// Used to reload the viewModel
    @Binding
    var activePurchases: [PurchaseInformation]

    init(screen: CustomerCenterConfigData.Screen,
         activePurchases: Binding<[PurchaseInformation]>,
         originalAppUserId: String,
         originalPurchaseDate: Date?,
         purchasesProvider: CustomerCenterPurchasesType,
         actionWrapper: CustomerCenterActionWrapper) {
        let viewModel = ActiveSubscriptionsListViewModel(
            screen: screen,
            actionWrapper: actionWrapper,
            activePurchases: activePurchases.wrappedValue,
            originalAppUserId: originalAppUserId,
            originalPurchaseDate: originalPurchaseDate,
            purchasesProvider: purchasesProvider
        )

        self.init(
            activePurchases: activePurchases,
            viewModel: viewModel
        )
    }

    // Used for Previews
    fileprivate init(
        activePurchases: Binding<[PurchaseInformation]> = .constant([]),
        viewModel: ActiveSubscriptionsListViewModel
    ) {
        self._activePurchases = activePurchases
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
        if viewModel.activePurchases.isEmpty {
            List {
                let fallbackDescription = localization[.tryCheckRestore]

                Section {
                    CompatibilityContentUnavailableView(
                        self.viewModel.screen.title,
                        systemImage: "exclamationmark.triangle.fill",
                        description: Text(self.viewModel.screen.subtitle ?? fallbackDescription)
                    )
                }

                Section {
                    ManageSubscriptionsButtonsView(viewModel: viewModel)
                }
            }
        } else {
            ScrollViewWithOSBackground {
                LazyVStack {
                    Text(localization[.activeSubscriptions].uppercased())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)

                    ForEach(viewModel.activePurchases) { purchase in
                        Section {
                            Button {
                                viewModel.purchaseInformation = purchase
                            } label: {
                                PurchaseInformationCardView(
                                    purchaseInformation: purchase,
                                    localization: localization
                                )
                                .background(Color(colorScheme == .light
                                                  ? UIColor.systemBackground
                                                  : UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                            .tint(colorScheme == .dark ? .white : .black)
                        }
                    }

                    if support?.displayPurchaseHistoryLink == true {
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
                        .padding(.top, 8)
                    }

                    accountDetailsView
                }
            }
        }
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
                ActiveSubscriptionsListView(
                    viewModel: ActiveSubscriptionsListViewModel(
                        screen: warningOffMock.screens[.management]!,
                        originalAppUserId: "originalAppUserId",
                        activePurchases: purchases
                    )
                )
                .environment(\.supportInformation, warningOffMock.support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Active subs - \(colorScheme)")

            CompatibilityNavigationStack {
                ActiveSubscriptionsListView(
                    viewModel: ActiveSubscriptionsListViewModel(
                        screen: warningOnMock.screens[.management]!,
                        originalAppUserId: UUID().uuidString,
                        activePurchases: []
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
