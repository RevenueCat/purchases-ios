//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyBalanceListRow.swift
//
//  Created by Will Taylor on 4/22/25.

#if os(iOS)

import SwiftUI

/// A SwiftUI view that displays a virtual currency balance in a list row format.
///
/// This view is designed to be used within a `List` or similar container view to display
/// virtual currency balances in a consistent format. It adapts its appearance based on
/// the iOS version, using `LabeledContent` on iOS 16+ and a custom `HStack` layout on earlier versions.
///
/// It uses a RowData struct to store the data for the row to make looping through multiple rows easier.
///
/// ## Example
/// ```swift
/// List {
///     VirtualCurrencyBalanceListRow(
///         rowData: .init(
///             virtualCurrencyCode: "GLD",
///             balance: 100
///         )
///     )
/// }
/// ```
///
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct VirtualCurrencyBalanceListRow: View {

    /// The data model for a virtual currency balance row.
    ///
    /// This struct contains the necessary information to display a virtual currency balance,
    /// including the currency code and the current balance amount.
    struct RowData: Identifiable, Hashable {
        /// A unique identifier for the row.
        let id = UUID()

        /// The virtual currency's name
        let virtualCurrencyName: String

        /// The code representing the virtual currency (e.g., "GLD" for gold).
        let virtualCurrencyCode: String

        /// The current balance of the virtual currency.
        let balance: Int
    }

    /// The data to be displayed in the row.
    let rowData: RowData

    var body: some View {
        CompatibilityLabeledContent {
            Text("\(rowData.virtualCurrencyName) (\(rowData.virtualCurrencyCode))")
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        } content: {
            Text(rowData.balance.formatted())
        }
        .transition(.opacity)
    }
}

struct VirtualCurrencyBalanceListRow_Previews: PreviewProvider {

    static var previews: some View {
        if #available(iOS 15.0, *) {
            List {
                VirtualCurrencyBalanceListRow(
                    rowData: .init(
                        virtualCurrencyName: "Gold",
                        virtualCurrencyCode: "GLD",
                        balance: 100
                    )
                )
            }
        } else {
            Text("Unavailable on iOS <15.0")
        }
    }
}

#endif
