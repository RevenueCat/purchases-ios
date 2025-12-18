//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrenciesScrollViewWithOSBackgroundSection.swift
//
//  Created by Will Taylor on 4/22/25.

#if os(iOS)

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

/// A SwiftUI view that displays a list of virtual currency balances in a section format.
///
/// This view shows up to three virtual currencies sorted by balance in descending order.
/// If there are more than three currencies, a "See All" button is displayed that navigates
/// to a full list of virtual currencies. Designed for use in a ``ScrollViewWithOSBackground`` view.
///
/// ## Navigation Considerations
///
/// Due to SwiftUI's limitations with placing navigation destinations inside ``List`` and ``LazyVStack`` views,
/// it is the responsibility of the parent view to implement the `onSeeAllInAppCurrenciesButtonTapped`
/// closure to present the ``VirtualCurrencyBalancesScreen``. This closure is called when the user
/// taps the "See All In-App Currencies" button.
///
/// > SwiftUI will print the following warning if navigation destinations are used inside ``List`` or ``LazyVStack``:
/// > ```
/// > Do not put a navigation destination modifier inside a "lazy" container, like `List` or `LazyVStack`.
/// > These containers create child views only when needed to render on screen. Add the navigation destination
/// > modifier outside these containers so that the navigation stack can always see the destination.
/// > There's a misplaced `navigationDestination(isPresented:destination:)` modifier presenting
/// > `VirtualCurrencyBalancesScreen`. It will be ignored in a future release.
/// > ```
/// >
/// > The extraction of the navigation logic to the parent view circumvents this warning.
///
/// Example implementation:
/// ```swift
/// VirtualCurrenciesScrollViewWithOSBackgroundSection(
///     virtualCurrencies: virtualCurrencies,
///     onSeeAllInAppCurrenciesButtonTapped: {
///         // Present VirtualCurrencyBalancesScreen here
///         // For example, using NavigationLink or sheet presentation
///     }
/// )
/// ```
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
// swiftlint:disable:next type_name
struct VirtualCurrenciesScrollViewWithOSBackgroundSection: View {

    private static let maxNumberOfRows = 4

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @Environment(\.colorScheme)
    private var colorScheme

    private let virtualCurrencies: [VirtualCurrencyBalanceListRow.RowData]
    private let displayShowAllButton: Bool

    /// Closure called when the user taps the "See All In-App Currencies" button.
    /// The parent view should implement this to present the ``VirtualCurrencyBalancesScreen``
    /// since navigation destinations cannot be nested inside ``List`` or ``LazyVStack``.
    private let onSeeAllInAppCurrenciesButtonTapped: () -> Void

    /// Creates a new virtual currencies list section.
    /// - Parameters:
    ///   - virtualCurrencies: Dictionary of virtual currency codes to their balance information
    ///   - onSeeAllInAppCurrenciesButtonTapped: Closure to handle navigation to the full list screen.
    ///     Must be implemented by the parent view to present ``VirtualCurrencyBalancesScreen``
    ///     since navigation destinations cannot be nested inside ``List`` or ``LazyVStack``.
    init(
        virtualCurrencies: RevenueCat.VirtualCurrencies,
        onSeeAllInAppCurrenciesButtonTapped: @escaping () -> Void
    ) {
        let sortedCurrencies = virtualCurrencies.all.map {
            VirtualCurrencyBalanceListRow.RowData(
                virtualCurrencyName: $0.value.name,
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
                    #if compiler(>=5.9)
                    .background(Color(colorScheme == .light
                                      ? UIColor.systemBackground
                                      : UIColor.secondarySystemBackground),
                                in: .rect(cornerRadius: CustomerCenterStylingUtilities.cornerRadius))
                    #endif
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
                virtualCurrencies: VirtualCurrenciesFixtures.fourVirtualCurrencies,
                onSeeAllInAppCurrenciesButtonTapped: { }
            )
        }
        .previewDisplayName("4 Virtual Currencies")

        ScrollViewWithOSBackground {
            VirtualCurrenciesScrollViewWithOSBackgroundSection(
                virtualCurrencies: VirtualCurrenciesFixtures.fiveVirtualCurrencies,
                onSeeAllInAppCurrenciesButtonTapped: { }
            )
        }
        .previewDisplayName("5 Virtual Currencies")
    }

}
#endif

#endif
