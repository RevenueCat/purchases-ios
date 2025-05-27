//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfo+SeeAllPurchases.swift
//
//  Created by Facundo Menzella on 21/5/25.

import RevenueCat

extension CustomerInfo {

    /// Determines whether the "See All Purchases" button should be shown.
    ///
    /// - Parameters:
    ///   - maxNonSubscriptions: The maximum number of non-subscription purchases allowed before showing the button.
    ///
    /// - Returns: `true` if:
    ///   - There's both active and inactive subscriptions.
    ///   - There's only inactive subscriptions and more than one of them.
    ///   - The number of non-subscription purchases exceeds `maxNonSubscriptions`.
    ///   Otherwise, returns `false`.
    func shouldShowSeeAllPurchasesButton(
        maxNonSubscriptions: Int
    ) -> Bool {
        let totalSubscriptions = subscriptionsByProductIdentifier.count
        let activeSubscriptionsCount = activeSubscriptions.count
        let inactiveSubscriptionsCount = totalSubscriptions - activeSubscriptionsCount

        if activeSubscriptionsCount > 0 && inactiveSubscriptionsCount > 0 {
            return true
        }

        if activeSubscriptionsCount == 0 && inactiveSubscriptionsCount > 1 {
            return true
        }

        if nonSubscriptions.count > maxNonSubscriptions {
            return true
        }

        return false
    }
}
