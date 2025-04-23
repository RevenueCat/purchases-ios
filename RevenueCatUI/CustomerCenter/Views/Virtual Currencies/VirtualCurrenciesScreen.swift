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

import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct VirtualCurrenciesScreen: View {

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @StateObject var viewModel: VirtualCurrenciesScreenViewModel

    enum ViewState {
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
                        Text(localization[.virtualCurrenciesScreenHeader])
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
        .navigationTitle(localization[.virtualCurrenciesScreenHeader])
        .onAppear {
            Task {
                await self.viewModel.onAppear()
            }
        }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension VirtualCurrenciesScreen.ViewState: Equatable {
    static func == (lhs: VirtualCurrenciesScreen.ViewState, rhs: VirtualCurrenciesScreen.ViewState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.error, .error):
            return true
        case let (.loaded(lhsData), .loaded(rhsData)):
            return lhsData == rhsData
        default:
            return false
        }
    }
}

#Preview("Loading") {
    if #available(iOS 14.0, *) {
        NavigationView {
            if #available(iOS 15.0, *) {
                VirtualCurrenciesScreen(
                    viewModel: VirtualCurrenciesScreenViewModel(
                        viewState: .loading,
                        purchasesProvider: CustomerCenterPurchases(),
                        isRunningInSwiftUIPreview: true
                    )
                )
                .environment(\.localization, CustomerCenterConfigData.Localization.default)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("VirtualCurrencyBalancesSectionView is not available on this platform")
            }
        }
    } else {
        Text("VirtualCurrencyBalancesSectionView is not available on this OS version")
    }
}

#Preview("Loaded With 0 VC Balances") {
    if #available(iOS 14.0, *) {
        NavigationView {
            if #available(iOS 15.0, *) {
                VirtualCurrenciesScreen(
                    viewModel: VirtualCurrenciesScreenViewModel(
                        viewState: .loaded([]),
                        purchasesProvider: CustomerCenterPurchases(),
                        isRunningInSwiftUIPreview: true
                    )
                )
                .environment(\.localization, CustomerCenterConfigData.Localization.default)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("VirtualCurrencyBalancesSectionView is not available on this platform")
            }
        }
    } else {
        Text("VirtualCurrencyBalancesSectionView is not available on this OS version")
    }
}

#Preview("Loaded with 4 VC Balances") {
    if #available(iOS 14.0, *) {
        NavigationView {
            if #available(iOS 15.0, *) {
                VirtualCurrenciesScreen(
                    viewModel: VirtualCurrenciesScreenViewModel(
                        viewState: .loaded([
                            .init(virtualCurrencyCode: "PLTNM", balance: 2000),
                            .init(virtualCurrencyCode: "BRNZ", balance: 1000),
                            .init(virtualCurrencyCode: "SLVR", balance: 500),
                            .init(virtualCurrencyCode: "GLD", balance: 100)

                        ]),
                        purchasesProvider: CustomerCenterPurchases(),
                        isRunningInSwiftUIPreview: true
                    )
                )
                .environment(\.localization, CustomerCenterConfigData.Localization.default)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("VirtualCurrencyBalancesSectionView is not available on this platform")
            }
        }
    } else {
        Text("VirtualCurrencyBalancesSectionView is not available on this OS version")
    }
}

#Preview("Error") {
    if #available(iOS 14.0, *) {
        NavigationView {
            if #available(iOS 15.0, *) {
                VirtualCurrenciesScreen(
                    viewModel: VirtualCurrenciesScreenViewModel(
                        viewState: .error,
                        purchasesProvider: CustomerCenterPurchases(),
                        isRunningInSwiftUIPreview: true
                    )
                )
                .environment(\.localization, CustomerCenterConfigData.Localization.default)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("VirtualCurrencyBalancesSectionView is not available on this platform")
            }
        }
    } else {
        Text("VirtualCurrencyBalancesSectionView is not available on this OS version")
    }
}

#endif
