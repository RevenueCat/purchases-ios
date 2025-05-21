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
/// Designed for use in a ``ScrollViewWithOSBackground`` view.
///
/// This view shows up to three virtual currencies sorted by balance in descending order.
/// If there are more than three currencies, a "See All" button is displayed that navigates
/// to a full list of virtual currencies.
// swiftlint:disable:next type_name
struct VirtualCurrenciesScrollViewWithOSBackgroundSection: View {

    private static let maxNumberOfRows = 4

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @Environment(\.colorScheme)
    private var colorScheme

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
            VStack(alignment: .leading, spacing: 0) {
                ScrollViewSection(title: localization[.virtualCurrencyBalancesScreenHeader]) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(
                            Array(virtualCurrencies.enumerated()),
                            id: \.element.id
                        ) { index, virtualCurrencyRowData in
                            VirtualCurrencyBalanceListRow(rowData: virtualCurrencyRowData)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                            if index < virtualCurrencies.count - 1 {
                                Divider()
                            }
                        }

                        if displayShowAllButton {
                            Divider()
                                .padding(.vertical, 4)
                            Button {
                                self.onSeeAllInAppCurrenciesButtonTapped()
                            } label: {
                                CompatibilityLabeledContent(
                                    localization[.seeAllVirtualCurrencies].localizedCapitalized
                                ) {
                                    Image(systemName: "chevron.forward")
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                    }
                    .background(Color(colorScheme == .light
                                      ? UIColor.systemBackground
                                      : UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 16)
                    .padding(.horizontal)
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
// swiftlint:disable:next type_name
struct VirtualCurrenciesScrollViewWithOSBackgroundSection_Previews: PreviewProvider {

    static var previews: some View {

        ScrollViewWithOSBackground {
            VirtualCurrenciesScrollViewWithOSBackgroundSection(
                virtualCurrencies: CustomerCenterConfigData.fourVirtualCurrencies,
                onSeeAllInAppCurrenciesButtonTapped: { }
            )
        }
        .previewDisplayName("4 Virtual Currencies")

        ScrollViewWithOSBackground {
            VirtualCurrenciesScrollViewWithOSBackgroundSection(
                virtualCurrencies: CustomerCenterConfigData.fiveVirtualCurrencies,
                onSeeAllInAppCurrenciesButtonTapped: { }
            )
        }
        .previewDisplayName("5 Virtual Currencies")
    }

}
#endif

#endif
