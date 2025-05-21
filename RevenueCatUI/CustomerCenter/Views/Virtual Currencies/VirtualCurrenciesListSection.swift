//
//  VirtualCurrenciesListSection.swift
//  RevenueCat
//
//  Created by Will Taylor on 5/21/25.
//

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
/// Designed for use in a SwiftUI ``List`` view.
///
/// This view shows up to three virtual currencies sorted by balance in descending order.
/// If there are more than three currencies, a "See All" button is displayed that navigates
/// to a full list of virtual currencies.
struct VirtualCurrenciesListSection: View {

    private static let maxNumberOfRows = 4

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    private let virtualCurrencies: [VirtualCurrencyBalanceListRow.RowData]
    private let displayShowAllButton: Bool
    private let onSeeAllInAppCurrenciesButtonTapped: () -> Void

    init(
        virtualCurrencies: [String: RevenueCat.VirtualCurrencyInfo],
        onSeeAllInAppCurrenciesButtonTapped: @escaping () -> Void
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
        // - Show first 3 currencies + "See All" button to limit to 4 rows if there are 5 or more currencies
        if sortedCurrencies.count <= Self.maxNumberOfRows {
            self.virtualCurrencies = sortedCurrencies
            self.displayShowAllButton = false
        } else {
            self.virtualCurrencies = Array(sortedCurrencies.prefix(3))
            self.displayShowAllButton = true
        }
        self.onSeeAllInAppCurrenciesButtonTapped = onSeeAllInAppCurrenciesButtonTapped
    }

    var body: some View {
        if !virtualCurrencies.isEmpty {
            Section {
                ForEach(virtualCurrencies) { virtualCurrencyRowData in
                    VirtualCurrencyBalanceListRow(rowData: virtualCurrencyRowData)
                }

                if displayShowAllButton {
                    Button {
                        self.onSeeAllInAppCurrenciesButtonTapped()
                    } label: {
                        CompatibilityLabeledContent(localization[.seeAllVirtualCurrencies].localizedCapitalized) {
                            Image(systemName: "chevron.forward")
                        }
                    }
                    .buttonStyle(.plain)
                }
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
                onSeeAllInAppCurrenciesButtonTapped: { }
            )
        }
        .previewDisplayName("4 Virtual Currencies")

        List {
            VirtualCurrenciesListSection(
                virtualCurrencies: CustomerCenterConfigData.fiveVirtualCurrencies,
                onSeeAllInAppCurrenciesButtonTapped: { }
            )
        }
        .previewDisplayName("5 Virtual Currencies")
    }

}
#endif

#endif
