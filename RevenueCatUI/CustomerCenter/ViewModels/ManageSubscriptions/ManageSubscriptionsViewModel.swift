//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ManageSubscriptionsViewModel.swift
//
//
//  Created by Cesar de la Vega on 27/5/24.
//

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
final class ManageSubscriptionsViewModel: BaseManageSubscriptionViewModel {

    @Published
    private(set) var purchasesActive: [PurchaseInformation] = []

    @Published
    var showAllPurchases = false

    init(
        screen: CustomerCenterConfigData.Screen,
        actionWrapper: CustomerCenterActionWrapper,
        purchasesActive: [PurchaseInformation] = [],
        refundRequestStatus: RefundRequestStatus? = nil,
        purchasesProvider: CustomerCenterPurchasesType,
        loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType? = nil) {
            self.purchasesActive = purchasesActive
            super.init(
                screen: screen,
                actionWrapper: actionWrapper,
                purchaseInformation: nil,
                refundRequestStatus: refundRequestStatus,
                purchasesProvider: purchasesProvider,
                loadPromotionalOfferUseCase: loadPromotionalOfferUseCase
            )
        }

    func updatePurchases(_ purchasesActive: [PurchaseInformation]) {
        self.purchasesActive = purchasesActive
        // go back to the list
        self.purchaseInformation = nil
    }
}

#endif
