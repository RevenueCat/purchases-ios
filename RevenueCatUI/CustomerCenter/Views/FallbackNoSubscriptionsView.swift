//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FallbackNoSubscriptionsView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

/// If fetching the configuration fails (NO_ACTIVE screen is not present) we display this
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct FallbackNoSubscriptionsView: View {

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

    private let virtualCurrencies: RevenueCat.VirtualCurrencies?

    private let purchasesProvider: CustomerCenterPurchasesType

    init(
        customerCenterViewModel: CustomerCenterViewModel,
        actionWrapper: CustomerCenterActionWrapper,
        virtualCurrencies: RevenueCat.VirtualCurrencies?,
        purchasesProvider: CustomerCenterPurchasesType
    ) {
        self.customerCenterViewModel = customerCenterViewModel
        self.actionWrapper = actionWrapper
        self.virtualCurrencies = virtualCurrencies
        self.purchasesProvider = purchasesProvider
    }

    var body: some View {
        ScrollViewWithOSBackground {
            LazyVStack(spacing: 0) {
                NoSubscriptionsCardView(
                    screenOffering: nil,
                    screen: nil,
                    localization: localization,
                    purchasesProvider: purchasesProvider
                )
                .padding(.horizontal)
                .padding(.bottom, 32)

                if let virtualCurrencies, !virtualCurrencies.all.isEmpty {
                    VirtualCurrenciesScrollViewWithOSBackgroundSection(
                        virtualCurrencies: virtualCurrencies,
                        onSeeAllInAppCurrenciesButtonTapped: { self.showAllInAppCurrenciesScreen = true }
                    )

                    Spacer().frame(height: 16)
                }

                restorePurchasesButton
            }
        }
        .compatibleNavigation(
            isPresented: $showAllInAppCurrenciesScreen,
            usesNavigationStack: navigationOptions.usesNavigationStack
        ) {
            VirtualCurrencyBalancesScreen(
                viewModel: VirtualCurrencyBalancesScreenViewModel(
                    purchasesProvider: customerCenterViewModel.purchasesProvider
                )
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

    private var restorePurchasesButton: some View {
        Button {
            showRestoreAlert = true
        } label: {
            CompatibilityLabeledContent(localization[.restorePurchases])
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(colorScheme == .light
                                  ? UIColor.systemBackground
                                  : UIColor.secondarySystemBackground))
                .cornerRadius(CustomerCenterStylingUtilities.cornerRadius)
                .padding(.horizontal)
        }
        .tint(colorScheme == .dark ? .white : .black)
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsView_Previews: PreviewProvider {

    static var previews: some View {
        FallbackNoSubscriptionsView(
            customerCenterViewModel: CustomerCenterViewModel(uiPreviewPurchaseProvider: MockCustomerCenterPurchases()),
            actionWrapper: CustomerCenterActionWrapper(),
            virtualCurrencies: nil,
            purchasesProvider: MockCustomerCenterPurchases()
        )
        .previewDisplayName("No Subscriptions View")

        FallbackNoSubscriptionsView(
            customerCenterViewModel: CustomerCenterViewModel(uiPreviewPurchaseProvider: MockCustomerCenterPurchases()),
            actionWrapper: CustomerCenterActionWrapper(),
            virtualCurrencies: VirtualCurrenciesFixtures.fourVirtualCurrencies,
            purchasesProvider: MockCustomerCenterPurchases()
        )
        .environment(\.supportInformation, CustomerCenterConfigData.mock(displayVirtualCurrencies: true).support)
        .previewDisplayName("4 Virtual Currencies")

        FallbackNoSubscriptionsView(
            customerCenterViewModel: CustomerCenterViewModel(uiPreviewPurchaseProvider: MockCustomerCenterPurchases()),
            actionWrapper: CustomerCenterActionWrapper(),
            virtualCurrencies: VirtualCurrenciesFixtures.fiveVirtualCurrencies,
            purchasesProvider: MockCustomerCenterPurchases()
        )
        .environment(\.supportInformation, CustomerCenterConfigData.mock(displayVirtualCurrencies: true).support)
        .previewDisplayName("5 Virtual Currencies")
    }

}

#endif

#endif
