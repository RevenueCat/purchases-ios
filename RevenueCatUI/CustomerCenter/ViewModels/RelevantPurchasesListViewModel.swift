//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RelevantPurchasesListViewModel.swift
//
//  Created by Facundo Menzella on 14/5/25.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
final class RelevantPurchasesListViewModel: BaseManageSubscriptionViewModel {

    static let maxNonSubscriptionsToShow = 2

    let shouldShowSeeAllPurchases: Bool

    override var relevantPathsForPurchase: [CustomerCenterConfigData.HelpPath] {
        paths.relevantPaths(for: nil, allowMissingPurchase: allowMissingPurchase)
    }

    init(
        screen: CustomerCenterConfigData.Screen,
        actionWrapper: CustomerCenterActionWrapper,
        shouldShowSeeAllPurchases: Bool,
        refundRequestStatus: RefundRequestStatus? = nil,
        purchasesProvider: CustomerCenterPurchasesType,
        loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType? = nil) {
            self.shouldShowSeeAllPurchases = shouldShowSeeAllPurchases

            super.init(
                screen: screen,
                actionWrapper: actionWrapper,
                purchaseInformation: nil,
                refundRequestStatus: refundRequestStatus,
                purchasesProvider: purchasesProvider,
                loadPromotionalOfferUseCase: loadPromotionalOfferUseCase
            )
        }

    // Used for Previews
    convenience init(
        screen: CustomerCenterConfigData.Screen,
        activePurchases: [PurchaseInformation] = [],
        nonSubscriptionPurchases: [PurchaseInformation] = [],
        shouldShowSeeAllPurchases: Bool,
        originalPurchaseDate: Date? = nil
    ) {
        self.init(
            screen: screen,
            actionWrapper: CustomerCenterActionWrapper(),
            shouldShowSeeAllPurchases: shouldShowSeeAllPurchases,
            purchasesProvider: MockCustomerCenterPurchases()
        )
    }
}

#endif
