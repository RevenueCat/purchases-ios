//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NoSubscriptionsView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsView: View {

    let configuration: CustomerCenterConfigData
    let actionWrapper: CustomerCenterActionWrapper

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.navigationOptions)
    var navigationOptions
    @ObservedObject
    private var customerCenterViewModel: CustomerCenterViewModel

    @State
    private var showRestoreAlert: Bool = false

    @State
    private var showAllInAppCurrenciesScreen: Bool = false

    private let virtualCurrencies: [String: RevenueCat.VirtualCurrencyInfo]?
    private let purchasesProvider: CustomerCenterPurchasesType

    init(
        customerCenterViewModel: CustomerCenterViewModel,
        configuration: CustomerCenterConfigData,
        actionWrapper: CustomerCenterActionWrapper,
        purchasesProvider: CustomerCenterPurchasesType,
        virtualCurrencies: [String: RevenueCat.VirtualCurrencyInfo]?
    )
        self.configuration = configuration
        self.actionWrapper = actionWrapper
        self.virtualCurrencies = virtualCurrencies
        self.purchasesProvider = purchasesProvider
    }

    var body: some View {
        let fallbackDescription = localization[.tryCheckRestore]
        let fallbackTitle = localization[.noSubscriptionsFound]

        List {
            Section {
                CompatibilityContentUnavailableView(
                    self.configuration.screens[.noActive]?.title ?? fallbackTitle,
                    systemImage: "exclamationmark.triangle.fill",
                    description:
                        Text(self.configuration.screens[.noActive]?.subtitle ?? fallbackDescription)
                )
            }

            if let virtualCurrencies, !virtualCurrencies.isEmpty {
                VirtualCurrenciesListSection(
                    virtualCurrencies: virtualCurrencies,
                    onSeeAllInAppCurrenciesButtonTapped: { self.showAllInAppCurrenciesScreen = true }
                )
            }

            Section {
                Button(localization[.restorePurchases]) {
                    showRestoreAlert = true
                }
            }

        }
        .dismissCircleButtonToolbarIfNeeded()
        .compatibleNavigation(
            isPresented: $showAllInAppCurrenciesScreen,
            usesNavigationStack: navigationOptions.usesNavigationStack
        ) {
            VirtualCurrencyBalancesScreen(
                viewModel: VirtualCurrencyBalancesScreenViewModel(purchasesProvider: self.purchasesProvider)
            )
            .environment(\.appearance, appearance)
            .environment(\.localization, localization)
            .environment(\.navigationOptions, navigationOptions)
        }
        .overlay {
            RestorePurchasesAlert(
                isPresented: $showRestoreAlert,
                actionWrapper: actionWrapper,
                customerCenterViewModel: customerCenterViewModel
            )
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsView_Previews: PreviewProvider {

    static var previews: some View {
        NoSubscriptionsView(
            customerCenterViewModel: CustomerCenterViewModel(uiPreviewPurchaseProvider: MockCustomerCenterPurchases()),
            configuration: CustomerCenterConfigData.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: CustomerCenterPurchases(),
            virtualCurrencies: nil
        )
        .previewDisplayName("No Subscriptions View")

        NoSubscriptionsView(
            customerCenterViewModel: CustomerCenterViewModel(uiPreviewPurchaseProvider: MockCustomerCenterPurchases()),
            configuration: CustomerCenterConfigData.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: CustomerCenterPurchases(),
            virtualCurrencies: CustomerCenterConfigData.fourVirtualCurrencies
        )
        .environment(\.supportInformation, CustomerCenterConfigData.mock(displayVirtualCurrencies: true).support)
        .previewDisplayName("4 Virtual Currencies")

        NoSubscriptionsView(
            customerCenterViewModel: CustomerCenterViewModel(uiPreviewPurchaseProvider: MockCustomerCenterPurchases()),
            configuration: CustomerCenterConfigData.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: CustomerCenterPurchases(),
            virtualCurrencies: CustomerCenterConfigData.fiveVirtualCurrencies
        )
        .environment(\.supportInformation, CustomerCenterConfigData.mock(displayVirtualCurrencies: true).support)
        .previewDisplayName("5 Virtual Currencies")
    }

}

#endif

#endif
