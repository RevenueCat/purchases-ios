//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfo+ActiveTransaction.swift
//
//  Created by Facundo Menzella on 14/4/25.

import RevenueCat

extension CustomerInfo {

    /// Returns the earliest expiring `Transaction`.
    ///
    /// The logic prioritizes active App Store subscriptions first, followed by:
    /// 1. Active App Store subscriptions
    /// 2. Non-subscription App Store transactions
    /// 3. Active subscriptions from other stores
    /// 4. Non-subscription transactions from other stores
    ///
    /// Within each group, transactions are sorted by their expiration date in ascending order.
    ///
    /// - Note: This is a **temporary** implementation and should eventually be replaced by
    ///         backend-side logic for consistency and accuracy.
    ///
    func earliestExpiringTransaction() -> Transaction? {
        let activeSubscriptions = subscriptionsByProductIdentifier.values
            .filter(\.isActive)
            .sorted(by: {
                guard let date1 = $0.expiresDate, let date2 = $1.expiresDate else {
                    return $0.expiresDate != nil
                }
                return date1 < date2
            })

        let (activeAppleSubscriptions, activeWebSubscriptions, otherActiveSubscriptions) = (
            activeSubscriptions.filter { $0.store == .appStore },
            activeSubscriptions.filter { $0.store == .rcBilling },
            activeSubscriptions.filter { $0.store != .appStore && $0.store != .rcBilling }
        )

        let (appleNonSubscriptions, webNonSubscriptions, otherNonSubscriptions) = (
            nonSubscriptions.filter { $0.store == .appStore },
            nonSubscriptions.filter { $0.store == .rcBilling },
            nonSubscriptions.filter { $0.store != .appStore && $0.store != .rcBilling }
        )

        return activeAppleSubscriptions.first ??
        activeWebSubscriptions.first ??
        appleNonSubscriptions.first ??
        webNonSubscriptions.first ??
        otherActiveSubscriptions.first ??
        otherNonSubscriptions.first
    }
}
