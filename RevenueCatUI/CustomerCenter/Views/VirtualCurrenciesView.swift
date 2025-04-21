//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrenciesView.swift
//
//  Created by Will Taylor on 4/21/25.

#if os(iOS)

import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct VirtualCurrenciesView: View {

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @StateObject var viewModel: VirtualCurrenciesViewModel

    enum ViewState {
        case loading
        case loaded([VirtualCurrencyBalanceRowData])
        case error
    }

    struct VirtualCurrencyBalanceRowData: Identifiable, Hashable {
        let id = UUID()
        let code: String
        let balance: Int
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
                        ForEach(virtualCurrencyBalanceData) { virtualCurrencyData in
                            VirtualCurrencyBalanceRow(
                                title: virtualCurrencyData.code,
                                balance: virtualCurrencyData.balance
                            )
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

    private struct VirtualCurrencyBalanceRow: View {

        let title: String
        let balance: Int

        var body: some View {
            if #available(iOS 16.0, *) {
                LabeledContent {
                    Text(balance.formatted())
                } label: {
                    Text(title)
                }
                .transition(.slide)
            } else {
                HStack {
                    Text(title)
                    Spacer()
                    Text(balance.formatted())
                        .foregroundStyle(.secondary)
                }
                .transition(.slide)
            }
        }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension VirtualCurrenciesView.ViewState: Equatable {
    static func == (lhs: VirtualCurrenciesView.ViewState, rhs: VirtualCurrenciesView.ViewState) -> Bool {
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
                VirtualCurrenciesView(
                    viewModel: VirtualCurrenciesViewModel(
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
                VirtualCurrenciesView(
                    viewModel: VirtualCurrenciesViewModel(
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
                VirtualCurrenciesView(
                    viewModel: VirtualCurrenciesViewModel(
                        viewState: .loaded([
                            .init(code: "PLTNM", balance: 2000),
                            .init(code: "BRNZ", balance: 1000),
                            .init(code: "SLVR", balance: 500),
                            .init(code: "GLD", balance: 100)

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
                VirtualCurrenciesView(
                    viewModel: VirtualCurrenciesViewModel(
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
