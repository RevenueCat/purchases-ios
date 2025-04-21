//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyBalancesView.swift
//
//  Created by Will Taylor on 4/21/25.

#if os(iOS)

import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct VirtualCurrencyBalancesView: View {

    private enum Constants {
        static let animationDuration: TimeInterval = 0.2
        static let maxInitiallyVisibleCurrencies = 3
    }

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    /// Mapping of virtual currency code to its balance.
    let virtualCurrencies: [(String, Int)]

    init(virtualCurrencies: [String: VirtualCurrencyInfo]) {
        self.virtualCurrencies = virtualCurrencies
            .map { ($0.key, $0.value.balance) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        List {
            if !virtualCurrencies.isEmpty {
                Section {
                    ForEach(virtualCurrencies, id: \.0) { virtualCurrency in
                        VirtualCurrencyBalanceRow(title: virtualCurrency.0, balance: virtualCurrency.1)
                    }
                } header: {
                    Text(localization[.virtualCurrencyBalancesHeader])
                }

            } else {
                Section {
                    CompatibilityContentUnavailableView(
                        "",
                        systemImage: "exclamationmark.triangle.fill",
                        description: Text(localization[.noVirtualCurrencyBalancesFound])
                    )
                }
            }
        }
        .navigationTitle(localization[.virtualCurrencyBalancesHeader])
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

class VirtualCurrencyBalancesModel: ObservableObject {

}

#if DEBUG
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
fileprivate extension VirtualCurrencyBalancesView {

    /// Convenenience initializer for previewing.
    init(
        virtualCurrencyBalances: [(String, Int)]
    ) {
        self.virtualCurrencies = virtualCurrencyBalances
    }
}

#endif

#Preview("4 Virtual Currency Balances") {
    if #available(iOS 14.0, *) {
        NavigationView {
            if #available(iOS 15.0, *) {
                VirtualCurrencyBalancesView(
                    virtualCurrencyBalances: [
                        ("GLD", 100),
                        ("SLVR", 200),
                        ("BRNZ", 300),
                        ("PLTNM", 1000)
                    ]
                )
                .environment(\.localization, CustomerCenterConfigData.Localization.default)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("VirtualCurrencyBalancesSectionView is not available on this platform")
            }
        }
    } else {
        // Fallback on earlier versions
    }
}

#Preview("No Virtual Currency Balances") {
    if #available(iOS 14.0, *) {
        NavigationView {
            if #available(iOS 15.0, *) {
                VirtualCurrencyBalancesView(
                    virtualCurrencyBalances: []
                )
                .environment(\.localization, CustomerCenterConfigData.Localization.default)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("VirtualCurrencyBalancesSectionView is not available on this platform")
            }
        }
    } else {
        // Fallback on earlier versions
    }
}

#endif
