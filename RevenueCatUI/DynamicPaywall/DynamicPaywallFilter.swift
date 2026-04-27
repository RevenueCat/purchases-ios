//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DynamicPaywallFilter.swift

import Foundation
import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum DynamicPaywallFilter {

    /// Applies the given behavior's filtering logic to the offering.
    ///
    /// - Returns: A new `Offering` with only the packages that pass the filter,
    ///   or `nil` if no packages survive (meaning the paywall should not be presented).
    static func apply(
        behavior: DynamicPaywallBehavior,
        to offering: Offering,
        customerInfo: CustomerInfo
    ) async -> Offering? {
        switch behavior.kind {
        case .upgrade:
            return await applyUpgradeFilter(to: offering, customerInfo: customerInfo)
        }
    }

    // MARK: - Upgrade

    private static func applyUpgradeFilter(
        to offering: Offering,
        customerInfo: CustomerInfo
    ) async -> Offering? {
        let activeSubscriptionIDs = customerInfo.activeSubscriptions
        guard !activeSubscriptionIDs.isEmpty else {
            Logger.debug(Strings.dynamicPaywall_noActiveSubscriptions)
            return nil
        }

        guard Purchases.isConfigured else {
            Logger.warning(Strings.dynamicPaywall_purchasesNotConfigured)
            return nil
        }

        let activeProducts = await Purchases.shared.products(Array(activeSubscriptionIDs))
        guard !activeProducts.isEmpty else {
            Logger.debug(Strings.dynamicPaywall_couldNotFetchActiveProducts)
            return nil
        }

        // Build a map of subscription group -> maximum active price in that group
        var maxPriceByGroup: [String: Decimal] = [:]
        for product in activeProducts {
            guard let groupID = product.subscriptionGroupIdentifier else { continue }
            let existing = maxPriceByGroup[groupID] ?? -1
            if product.price > existing {
                maxPriceByGroup[groupID] = product.price
            }
        }

        guard !maxPriceByGroup.isEmpty else {
            Logger.debug(Strings.dynamicPaywall_noSubscriptionGroupFound)
            return nil
        }

        let filteredPackages: [Package] = offering.availablePackages.filter { package in
            guard let groupID = package.storeProduct.subscriptionGroupIdentifier else {
                return false
            }
            guard let activePrice = maxPriceByGroup[groupID] else {
                return false
            }
            return package.storeProduct.price > activePrice
        }

        guard !filteredPackages.isEmpty else {
            Logger.debug(Strings.dynamicPaywall_noUpgradeCandidates)
            return nil
        }

        Logger.debug(Strings.dynamicPaywall_foundUpgradeCandidates(filteredPackages.count))

        return offering.copyWithFilteredPackages(filteredPackages)
    }

}
