//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrenciesScreen.swift
//
//  Created by Will Taylor on 4/21/25.

#if os(iOS)

@_spi(Internal) import RevenueCat
import SwiftUI

/// A SwiftUI view that displays a list of virtual currency balances for the current user.
///
/// This view shows a loading state while fetching balances, displays the balances in a list when loaded,
/// or shows an error state if the fetch fails. Each virtual currency balance is displayed in a row
/// showing the currency code and balance amount.
///
/// ## Example
/// ```swift
/// NavigationView {
///     VirtualCurrenciesScreen(
///         viewModel: VirtualCurrenciesScreenViewModel(
///             purchasesProvider: CustomerCenterPurchases()
///         )
///     )
/// }
/// ```
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct VirtualCurrencyBalancesScreen: View {

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @StateObject var viewModel: VirtualCurrencyBalancesScreenViewModel

    /// Represents the different states the view can be in.
    ///
    /// - `loading`: The view is currently fetching virtual currency balances.
    /// - `loaded`: The view has successfully loaded the balances. Contains an array of balance data.
    /// - `error`: An error occurred while fetching the balances.
    enum ViewState: Equatable {
        case loading
        case loaded([VirtualCurrencyBalanceListRow.RowData])
        case error
    }

    var body: some View {
        List {
            switch self.viewModel.viewState {
            case .loading:
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                    .transition(.opacity)
            case .loaded(let virtualCurrencyBalanceData):
                if !virtualCurrencyBalanceData.isEmpty {
                    Section {
                        ForEach(virtualCurrencyBalanceData) { virtualCurrencyBalanceData in
                            VirtualCurrencyBalanceListRow(rowData: virtualCurrencyBalanceData)
                        }
                    } header: {
                        Text(localization[.virtualCurrencyBalancesScreenHeader])
                    }
                    .transition(.opacity)
                } else {
                    Section {
                        CompatibilityContentUnavailableView(
                            "",
                            systemImage: "exclamationmark.triangle.fill",
                            description: Text(localization[.noVirtualCurrencyBalancesFound])
                        )
                    }
                    .transition(.opacity)
                }
            case .error:
                ErrorView()
                    .transition(.opacity)
            }

        }
        .animation(.default, value: viewModel.viewState)
        .navigationTitle(localization[.virtualCurrencyBalancesScreenHeader])
        .task(priority: .userInitiated) {
            await self.viewModel.onViewAppeared()
        }
    }
}

struct VirtualCurrencyBalancesScreen_Previews: PreviewProvider {

    static var previews: some View {
        if #available(iOS 15.0, *) {
            CompatibilityNavigationStack {
                VirtualCurrencyBalancesScreen(
                    viewModel: VirtualCurrencyBalancesScreenViewModel(
                        viewState: .loaded([]),
                        purchasesProvider: CustomerCenterPurchases()
                    )
                )
                .environment(\.localization, CustomerCenterConfigData.Localization.default)
                .navigationBarTitleDisplayMode(.inline)
                .previewDisplayName("Loaded With 0 VC Balances")
            }
            .previewDisplayName("Loaded With 0 VC Balances")

            CompatibilityNavigationStack {
                VirtualCurrencyBalancesScreen(
                    viewModel: VirtualCurrencyBalancesScreenViewModel(
                        viewState: .loaded([
                            .init(virtualCurrencyName: "Platinum", virtualCurrencyCode: "PLTNM", balance: 2000),
                            .init(virtualCurrencyName: "Bronze", virtualCurrencyCode: "BRNZ", balance: 1000),
                            .init(virtualCurrencyName: "Silver", virtualCurrencyCode: "SLVR", balance: 500),
                            .init(virtualCurrencyName: "Gold", virtualCurrencyCode: "GLD", balance: 100)

                        ]),
                        purchasesProvider: CustomerCenterPurchases()
                    )
                )
                .environment(\.localization, CustomerCenterConfigData.Localization.default)
                .navigationBarTitleDisplayMode(.inline)
            }
            .previewDisplayName("Loaded with 4 VC Balances")

            CompatibilityNavigationStack {
                VirtualCurrencyBalancesScreen(
                    viewModel: VirtualCurrencyBalancesScreenViewModel(
                        viewState: .error,
                        purchasesProvider: CustomerCenterPurchases()
                    )
                )
                .environment(\.localization, CustomerCenterConfigData.Localization.default)
                .navigationBarTitleDisplayMode(.inline)
            }
            .previewDisplayName("Error")
        } else {
            Text("VirtualCurrencyBalancesSectionView is not available on this platform")
        }
    }
}

#endif
