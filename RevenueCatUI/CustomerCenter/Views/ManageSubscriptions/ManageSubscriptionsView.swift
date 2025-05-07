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

@_spi(Internal) import RevenueCat
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
        //            .onChangeOf(activePurchases) { _ in
        //                viewModel.updatePurchases(activePurchases)
        //            }
    }

    @ViewBuilder
    var content: some View {
        ZStack {
            Color(
                colorScheme == .dark
                ? UIColor.secondarySystemBackground
                : UIColor.systemGroupedBackground
            )
            .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if viewModel.purchasesMightBeDuplicated,
                       support?.shouldWarnCustomersAboutMultipleSubscriptions == true {
                        CompatibilityContentUnavailableView(
                            localization[.youMayHaveDuplicatedSubscriptionsTitle],
                            systemImage: "exclamationmark.square",
                            description: Text(
                                localization[.youMayHaveDuplicatedSubscriptionsSubtitle]
                            )
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    Color(colorScheme == .light
                                          ? UIColor.systemBackground
                                          : UIColor.secondarySystemBackground)
                                )
                        )
                    }

                    if viewModel.activePurchases.isEmpty {
                        let fallbackDescription = localization[.tryCheckRestore]

                        CompatibilityContentUnavailableView(
                            self.viewModel.screen.title,
                            systemImage: "exclamationmark.triangle.fill",
                            description: Text(self.viewModel.screen.subtitle ?? fallbackDescription)
                        )
                        .padding(.horizontal)

                        ManageSubscriptionsButtonsView(
                            viewModel: self.viewModel
                        )
                        .padding(.horizontal)

                    } else {
                        Text(localization[.activeSubscriptions].uppercased())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 32)

                        ForEach(viewModel.activePurchases) { purchase in
                            Button {
                                viewModel.purchaseInformation = purchase
                            } label: {
                                PurchaseInformationCardView(purchaseInformation: purchase)
                                    .padding(16)
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                            .tint(.primary)
                        }

                        if support?.displayPurchaseHistoryLink == true {
                            Button {
                                viewModel.showAllPurchases = true
                            } label: {
                                CompatibilityLabeledContent(localization[.seeAllPurchases]) {
                                    Image(systemName: "chevron.forward")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 12, height: 12)
                                        .foregroundStyle(.secondary)
                                        .font(Font.system(size: 12, weight: .bold))
                                }
                                .padding(16)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)
                                .tint(.primary)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top)
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
        let purchases: [PurchaseInformation] = [
            .subscriptionInformationYearlyExpiring(productIdentifier: "p1"),
            .subscriptionInformationYearlyExpiring(productIdentifier: "p2", store: .amazon),
            .subscriptionInformationYearlyExpiring(productIdentifier: "p3", introductoryDiscount: MockStoreProductDiscount.mock(paymentMode: .payAsYouGo, discountType: .introductory)),
            .subscriptionInformationYearlyExpiring(productIdentifier: "p4", introductoryDiscount: MockStoreProductDiscount.mock(paymentMode: .payUpFront, discountType: .promotional)),
            .monthlyRenewing,
            .subscriptionInformationFree
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
