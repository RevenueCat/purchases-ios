//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrenciesListSection.swift
//
//  Created by Will Taylor on 4/22/25.

#if os(iOS)

import Foundation
import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// A SwiftUI view that displays a list of virtual currency balances in a section format.
///
/// This view shows up to three virtual currencies sorted by balance in descending order.
/// If there are more than three currencies, a "See All" button is displayed that navigates
/// to a full list of virtual currencies.
///
/// ## Implementation Requirements
///
/// The caller must implement the `onShowVirtualCurrenciesListScreenTapped` callback to handle navigation
/// to the VirtualCurrencyBalancesScreen when the user taps the "See All" button.
/// This is to avoid creating a navigation destination inside a List, which logs a warning in the console
/// and will not be supported in future OS releases.
struct VirtualCurrenciesListSection: View {

    private static let maxNumberOfRows = 4

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    private let virtualCurrencies: [VirtualCurrencyBalanceListRow.RowData]
    private let displayShowAllButton: Bool
    private let purchasesProvider: CustomerCenterPurchasesType
    private let onShowVirtualCurrenciesListScreenTapped: () -> Void

    /// Creates a new instance of the virtual currencies list section.
    ///
    /// - Parameters:
    ///   - virtualCurrencies: A dictionary mapping virtual currency codes to their balance information.
    ///   - purchasesProvider: The provider that handles purchases-related functionality.
    ///   - onShowVirtualCurrenciesListScreenTapped: A closure that will be called when the user taps the "See All" button.
    ///     This should handle navigation to the VirtualCurrencyBalancesScreen.
    ///
    /// The currencies will be sorted by balance in descending order, and up to four currencies will be displayed.
    /// If there are more than four currencies, a "See All" button will be shown with three currencies.
    init(
        virtualCurrencies: [String: RevenueCat.VirtualCurrencyInfo],
        purchasesProvider: CustomerCenterPurchasesType,
        onShowVirtualCurrenciesListScreenTapped: @escaping () -> Void
    ) {
        let sortedCurrencies = virtualCurrencies.map {
            VirtualCurrencyBalanceListRow.RowData(
                virtualCurrencyCode: $0.key,
                balance: $0.value.balance
            )
        }
            .sorted(by: { $0.balance > $1.balance })

        // We want to limit the number of rows in the list to 4 max. We accomplish this by:
        // - Showing all currencies if there are 4 or fewer currencies
        // - Show first `maxNumberOfRows` currencies + "See All" button to limit to 4 rows if there are 5 or more currencies
        if sortedCurrencies.count <= Self.maxNumberOfRows {
            self.virtualCurrencies = sortedCurrencies
            self.displayShowAllButton = false
        } else {
            self.virtualCurrencies = Array(sortedCurrencies.prefix(3))
            self.displayShowAllButton = true
        }
        self.purchasesProvider = purchasesProvider
        self.onShowVirtualCurrenciesListScreenTapped = onShowVirtualCurrenciesListScreenTapped
    }

    var body: some View {
        if !virtualCurrencies.isEmpty {
            Section {
                ForEach(virtualCurrencies) { virtualCurrencyRowData in
                    VirtualCurrencyBalanceListRow(rowData: virtualCurrencyRowData)
                }

                if displayShowAllButton {
                    Button {
                        self.onShowVirtualCurrenciesListScreenTapped()
                    } label: {
                        Text(localization[.seeAllVirtualCurrencies])
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                }
            } header: {
                Text(localization[.virtualCurrencyBalancesScreenHeader])
            }
        }
    }
}

#if DEBUG
// MARK: - Previews
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct VirtualCurrenciesListSection_Previews: PreviewProvider {

    static var previews: some View {

        List {
            VirtualCurrenciesListSection(
                virtualCurrencies: CustomerCenterConfigData.fourVirtualCurrencies,
                purchasesProvider: CustomerCenterPurchases(),
                onShowVirtualCurrenciesListScreenTapped: { }
            )
        }
        .previewDisplayName("4 Virtual Currencies")

        List {
            VirtualCurrenciesListSection(
                virtualCurrencies: CustomerCenterConfigData.fiveVirtualCurrencies,
                purchasesProvider: CustomerCenterPurchases(),
                onShowVirtualCurrenciesListScreenTapped: { }
            )
        }
        .previewDisplayName("5 Virtual Currencies")
    }

}
#endif

#endif
