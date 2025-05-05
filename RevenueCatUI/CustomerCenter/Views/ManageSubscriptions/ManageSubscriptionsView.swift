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

    init(screen: CustomerCenterConfigData.Screen,
         purchaseInformation: PurchaseInformation?,
         purchasesActive: [PurchaseInformation] = [],
         purchasesProvider: CustomerCenterPurchasesType,
         actionWrapper: CustomerCenterActionWrapper) {
        let viewModel = ManageSubscriptionsViewModel(
            screen: screen,
            actionWrapper: actionWrapper,
            purchaseInformation: purchaseInformation,
            purchasesActive: purchasesActive,
            purchasesProvider: purchasesProvider)
        self.init(viewModel: viewModel)
    }

    fileprivate init(viewModel: ManageSubscriptionsViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        content
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
    }

    @ViewBuilder
    var content: some View {
        List {
            if support?.shouldWarnCustomersAboutMultipleSubscriptions == true {
                CompatibilityContentUnavailableView(
                    "You May Have Duplicate Subscriptions",
                    systemImage: "exclamationmark.square",
                    description: Text("It looks like you might be subscribed both on the web and through the App Store. To avoid being charged twice, please cancel your iOS subscription in your device settings.")
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
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

            if viewModel.purchasesActive.isEmpty {
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
                        relevantPathsForPurchase: self.viewModel.relevantPathsForPurchase,
                        determineFlowForPath: { path in
                            await self.viewModel.determineFlow(
                                for: path,
                                activeProductId: nil
                            )
                        },
                        label: { path in
                            if self.viewModel.loadingPath?.id == path.id {
                                TintedProgressView()
                            } else {
                                Text(path.title)
                            }
                        }
                    )
                }

            } else {
                Section("Active subscriptions") {
                    ForEach(viewModel.purchasesActive) { purchase in
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
        .dismissCircleButtonToolbarIfNeeded()
        .applyIf(self.viewModel.screen.type == .management, apply: {
            $0.navigationTitle(self.viewModel.screen.title)
                .navigationBarTitleDisplayMode(.inline)
         })
    }
}

#endif
