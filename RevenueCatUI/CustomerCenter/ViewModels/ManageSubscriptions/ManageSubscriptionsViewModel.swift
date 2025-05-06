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
    private(set) var activePurchases: [PurchaseInformation] = []

    var purchasesMightBeDuplicated: Bool {
        activePurchases.first(where: { $0.store == .appStore }) != nil
            && activePurchases.first(where: { $0.store != .appStore }) != nil
    }

    init(
        screen: CustomerCenterConfigData.Screen,
        actionWrapper: CustomerCenterActionWrapper,
        activePurchases: [PurchaseInformation] = [],
        refundRequestStatus: RefundRequestStatus? = nil,
        purchasesProvider: CustomerCenterPurchasesType,
        loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType? = nil) {
            self.activePurchases = activePurchases
            super.init(
                screen: screen,
                actionWrapper: actionWrapper,
                purchaseInformation: nil,
                refundRequestStatus: refundRequestStatus,
                purchasesProvider: purchasesProvider,
                loadPromotionalOfferUseCase: loadPromotionalOfferUseCase
            )
        }

    func updatePurchases(_ activePurchases: [PurchaseInformation]) {
        self.activePurchases = activePurchases
        // go back to the list
        self.purchaseInformation = nil
    }
}

#endif
