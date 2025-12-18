//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyBalancesScreenViewModel.swift
//
//  Created by Will Taylor on 4/21/25.

#if os(iOS)

import Foundation
@_spi(Internal) import RevenueCat

/// A view model that manages the state and data for the virtual currencies screen.
///
/// This view model is responsible for loading and managing virtual currency balance data.
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
final class VirtualCurrencyBalancesScreenViewModel: ObservableObject {

    /// The current state of the virtual currencies screen.
    @Published var viewState: VirtualCurrencyBalancesScreen.ViewState

    /// A flag indicating whether the view model is running in a SwiftUI preview.
    ///
    /// When true, data loading is skipped to prevent unnecessary network calls
    /// during preview rendering.
    private let isRunningInSwiftUIPreview: Bool

    init(
        viewState: VirtualCurrencyBalancesScreen.ViewState = .loading,
        purchasesProvider: CustomerCenterPurchasesType
    ) {
        self.viewState = viewState
        self.purchasesProvider = purchasesProvider

        #if DEBUG
        self.isRunningInSwiftUIPreview = ProcessInfo.isRunningForPreviews
        #else
        self.isRunningInSwiftUIPreview = false
        #endif
    }

    private let purchasesProvider: CustomerCenterPurchasesType

    /// Call this function when the view appears.
    ///
    /// This method is responsible for loading the virtual currency data when the view
    /// becomes visible. It skips data loading if running in a SwiftUI preview.
    func onViewAppeared() async {
        if isRunningInSwiftUIPreview {
            // We don't want to load data in previews.
            return
        }

        await self.loadData()
    }

    /// Loads the virtual currency data from the RevenueCat SDK.
    ///
    /// This method updates the view state to reflect the loading process and handles
    /// any errors that occur during data fetching. On success, it transforms the
    /// virtual currency data into a format suitable for displaying in the UI.
    private func loadData() async {
        self.viewState = .loading

        do {
            self.purchasesProvider.invalidateVirtualCurrenciesCache()
            let virtualCurrencies = try await self.purchasesProvider.virtualCurrencies()
            let virtualCurrencyBalanceData = self.extractVirtualCurrencyBalanceData(from: virtualCurrencies.all)

            self.viewState = .loaded(virtualCurrencyBalanceData)
        } catch {
            self.viewState = .error
        }
    }

    private func extractVirtualCurrencyBalanceData(
        from virtualCurrencies: [String: RevenueCat.VirtualCurrency]
    ) -> [VirtualCurrencyBalanceListRow.RowData] {
        return virtualCurrencies
            .map {
                VirtualCurrencyBalanceListRow.RowData(
                    virtualCurrencyName: $0.value.name,
                    virtualCurrencyCode: $0.key,
                    balance: $0.value.balance
                )
            }
            .sorted { $0.balance > $1.balance }
    }
}

#endif
