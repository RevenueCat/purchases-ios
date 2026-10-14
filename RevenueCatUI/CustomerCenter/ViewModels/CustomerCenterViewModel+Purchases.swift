//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterViewModel+Purchases.swift
//
//
//  Created by Monika on 2026-10-14.
//

import Foundation
@_spi(Internal) import RevenueCat

#if os(iOS)
@available(iOS 15.0, *)
extension CustomerCenterViewModel {

    func loadNonSubscriptions(
        customerInfo: CustomerInfo, configuration: CustomerCenterConfigData
    ) async -> [PurchaseInformation] {
        var activeNonSubscriptionPurchases: [PurchaseInformation] = []
        // customerInfo returns these oldest first, and the management screen only shows the first few
        for subscription in customerInfo.nonSubscriptions.sorted(by: { $0.purchaseDate > $1.purchaseDate }) {

            let purchaseInfo: PurchaseInformation = await .from(
                transaction: subscription,
                customerInfo: customerInfo,
                purchasesProvider: purchasesProvider,
                changePlans: [],
                customerCenterStoreKitUtilities: customerCenterStoreKitUtilities,
                localization: configuration.localization
            )
            activeNonSubscriptionPurchases.append(purchaseInfo)
        }
        return activeNonSubscriptionPurchases
    }

    private func loadMostRecentExpiredTransaction(
        customerInfo: CustomerInfo, configuration: CustomerCenterConfigData
    ) async -> [PurchaseInformation] {
        let inactive = customerInfo.subscriptionsByProductIdentifier
            .filter { !$0.value.isActive }
            .sorted { sub1, sub2 in
                // most recent expired
                let date1 = sub1.value.expiresDate
                let date2 = sub2.value.expiresDate

                switch (date1, date2) {
                case let (date1?, date2?):
                    return date1 > date2
                case (nil, _?):
                    return false
                case (_?, nil):
                    return true
                case (nil, nil):
                    return false
                }
            }
            .first

        guard let inactiveSub = inactive?.value else {
            return []
        }

        let purchaseInfo: PurchaseInformation = await .from(
            transaction: inactiveSub,
            customerInfo: customerInfo,
            purchasesProvider: purchasesProvider,
            changePlans: [],
            customerCenterStoreKitUtilities: customerCenterStoreKitUtilities,
            localization: configuration.localization
        )

        return [purchaseInfo]
    }

    func loadSubscriptions(
        customerInfo: CustomerInfo,
        configuration: CustomerCenterConfigData
    ) async -> [PurchaseInformation] {
        var activeSubscriptionPurchases: [PurchaseInformation] = []
        let subscriptions = customerInfo.activeSubscriptions
            .compactMap({ id in
                // Do the opposite as CustomerInfo.extractProductIDAndBasePlan for non-apple products
                let idWithoutBasePlan = id.split(separator: ":").first.map { id in String(id) } ?? id
                return customerInfo.subscriptionsByProductIdentifier[idWithoutBasePlan]
                    ?? customerInfo.subscriptionsByProductIdentifier[id] // fallback in case it fails
            })
            .sorted(by: {
                guard let date1 = $0.expiresDate, let date2 = $1.expiresDate else {
                    return $0.expiresDate != nil
                }

                return date1 < date2
            })

        for subscription in subscriptions {
            let purchaseInfo: PurchaseInformation = await .from(
                transaction: subscription,
                customerInfo: customerInfo,
                purchasesProvider: purchasesProvider,
                changePlans: configuration.changePlans,
                customerCenterStoreKitUtilities: customerCenterStoreKitUtilities,
                localization: configuration.localization
            )

            activeSubscriptionPurchases.append(purchaseInfo)
        }

        if activeSubscriptionPurchases.isEmpty {
            return await loadMostRecentExpiredTransaction(customerInfo: customerInfo, configuration: configuration)
        }
        return activeSubscriptionPurchases
    }

}
#endif
