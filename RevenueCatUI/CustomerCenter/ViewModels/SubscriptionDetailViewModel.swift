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

import Combine
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

    @Published
    var isRefreshing: Bool = false

    let showPurchaseHistory: Bool

    var shouldShowContactSupport: Bool {
        purchaseInformation?.store != .appStore
    }

    override var allowMissingPurchase: Bool {
        allowsMissingPurchaseAction
    }

    private var allowsMissingPurchaseAction: Bool = true

    private var cancellable: AnyCancellable?
    private let customerInfoViewModel: CustomerCenterViewModel

    init(
        customerInfoViewModel: CustomerCenterViewModel,
        screen: CustomerCenterConfigData.Screen,
        showPurchaseHistory: Bool,
        allowsMissingPurchaseAction: Bool,
        actionWrapper: CustomerCenterActionWrapper,
        purchaseInformation: PurchaseInformation? = nil,
        refundRequestStatus: RefundRequestStatus? = nil,
        purchasesProvider: CustomerCenterPurchasesType,
        loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType? = nil) {
            self.showPurchaseHistory = showPurchaseHistory
            self.allowsMissingPurchaseAction = allowsMissingPurchaseAction
            self.customerInfoViewModel = customerInfoViewModel

            super.init(
                screen: screen,
                actionWrapper: actionWrapper,
                purchaseInformation: purchaseInformation,
                refundRequestStatus: refundRequestStatus,
                purchasesProvider: purchasesProvider,
                loadPromotionalOfferUseCase: loadPromotionalOfferUseCase
            )
        }

    func refreshPurchase() {
        cancellable = customerInfoViewModel.publisher(for: purchaseInformation)?
            .dropFirst() // skip current value
            .sink(receiveValue: { [weak self] in
                defer { self?.isRefreshing = false }

                self?.purchaseInformation = $0
            })

        isRefreshing = true

        Task {
            await customerInfoViewModel.loadScreen(shouldSync: true)
            // In case loadScreen does not trigger a new update (error)
            isRefreshing = false
        }
    }

    // Previews
    convenience init(
        customerInfoViewModel: CustomerCenterViewModel,
        screen: CustomerCenterConfigData.Screen,
        showPurchaseHistory: Bool,
        allowsMissingPurchaseAction: Bool,
        purchaseInformation: PurchaseInformation? = nil,
        refundRequestStatus: RefundRequestStatus? = nil
    ) {
        self.init(
            customerInfoViewModel: customerInfoViewModel,
            screen: screen,
            showPurchaseHistory: showPurchaseHistory,
            allowsMissingPurchaseAction: allowsMissingPurchaseAction,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchaseInformation,
            refundRequestStatus: refundRequestStatus,
            purchasesProvider: MockCustomerCenterPurchases(),
            loadPromotionalOfferUseCase: nil
        )
    }
}

#endif
