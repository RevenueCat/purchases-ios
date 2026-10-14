//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterViewModel+Presentation.swift
//
//
//  Created by Monika on 2026-10-14.
//

import Combine
import Foundation
@_spi(Internal) import RevenueCat

#if os(iOS)
@available(iOS 15.0, *)
extension CustomerCenterViewModel {

    /// Whether or not the Customer Center should warn the customer that they're on an outdated version of the app.
    var shouldShowAppUpdateWarnings: Bool {
        return !appIsLatestVersion && (configuration?.support.shouldWarnCustomerToUpdate ?? true)
    }

    /// Whether or not the user has any purchases (subscriptions, non-subscriptions, virtual currencies)
    var hasAnyPurchases: Bool {
        !subscriptionsSection.isEmpty
            || !nonSubscriptionsSection.isEmpty
            || !(virtualCurrencies?.balanceIsZero ?? true)
    }

    var shouldShowList: Bool {
        let virtualCurrenciesCount = virtualCurrencies.map { $0.all.count } ?? 0
        let nonVirtualCurrencyCount = subscriptionsSection.count + nonSubscriptionsSection.count

        return nonVirtualCurrencyCount + virtualCurrenciesCount > 1
    }

    var originalAppUserId: String {
        customerInfo?.originalAppUserId ?? ""
    }

    var originalPurchaseDate: Date? {
        customerInfo?.originalPurchaseDate
    }

    var shouldShowSeeAllPurchases: Bool {
        configuration?.support.displayPurchaseHistoryLink == true
        && customerInfo?.shouldShowSeeAllPurchasesButton(
            maxNonSubscriptions: RelevantPurchasesListViewModel.maxNonSubscriptionsToShow
        ) ?? false
    }

    var shouldShowVirtualCurrencies: Bool {
        configuration?.support.displayVirtualCurrencies == true
    }

    var shouldShowUserDetailsSection: Bool {
        configuration?.support.displayUserDetailsSection ?? true
    }

    func publisher(for purchase: PurchaseInformation?) -> AnyPublisher<PurchaseInformation?, Never> {
        $customerInfo.map { [weak self] _ -> PurchaseInformation? in
            guard let self else { return nil }
            let purchases = self.subscriptionsSection + self.nonSubscriptionsSection
            guard let purchase else { return purchases.first }
            return self.purchase(matching: purchase)
        }
        .eraseToAnyPublisher()
    }

    func purchase(matching purchase: PurchaseInformation) -> PurchaseInformation? {
        let purchases = subscriptionsSection + nonSubscriptionsSection
        return purchases.first { $0.productIdentifier == purchase.productIdentifier }
            ?? purchases.first {
                purchase.subscriptionGroupID != nil
                    && $0.subscriptionGroupID == purchase.subscriptionGroupID
                    && $0.store == purchase.store
            }
    }

    func onDismissRestorePurchasesAlert() {
        currentTask = Task {
            await loadScreen()
        }
    }
}

private extension VirtualCurrencies {

    var balanceIsZero: Bool {
        all.map(\.value.balance).reduce(0, +) <= 0
    }
}

#endif
