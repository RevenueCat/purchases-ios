//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionDetailViewModel.swift
//
//
//  Created by Facundo Menzella on 3/5/25.
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
final class SubscriptionDetailViewModel: BaseManageSubscriptionViewModel {

    let showPurchaseHistory: Bool

    var shouldShowContactSupport: Bool {
        purchaseInformation?.store != .appStore
    }

    init(
        screen: CustomerCenterConfigData.Screen,
        showPurchaseHistory: Bool,
        actionWrapper: CustomerCenterActionWrapper,
        purchaseInformation: PurchaseInformation? = nil,
        refundRequestStatus: RefundRequestStatus? = nil,
        purchasesProvider: CustomerCenterPurchasesType,
        loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType? = nil) {
        self.showPurchaseHistory = showPurchaseHistory

        super.init(
            screen: screen,
            actionWrapper: actionWrapper,
            purchaseInformation: purchaseInformation,
            refundRequestStatus: refundRequestStatus,
            purchasesProvider: purchasesProvider,
            loadPromotionalOfferUseCase: loadPromotionalOfferUseCase
        )
    }

    func reloadPurchaseInformation(_ purchaseInformation: PurchaseInformation?) {
        self.purchaseInformation = purchaseInformation
    }

    // Previews
    convenience init(
        screen: CustomerCenterConfigData.Screen,
        showPurchaseHistory: Bool,
        purchaseInformation: PurchaseInformation? = nil,
        refundRequestStatus: RefundRequestStatus? = nil
    ) {
        self.init(
            screen: screen,
            showPurchaseHistory: showPurchaseHistory,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchaseInformation,
            refundRequestStatus: refundRequestStatus,
            purchasesProvider: MockCustomerCenterPurchases(),
            loadPromotionalOfferUseCase: nil
        )
    }
}

#endif
