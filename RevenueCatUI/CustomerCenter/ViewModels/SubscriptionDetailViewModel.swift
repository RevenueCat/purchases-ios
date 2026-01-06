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
    let showVirtualCurrencies: Bool

    var shouldShowContactSupport: Bool {
        purchaseInformation?.store != .appStore
    }

    var hasActiveSubscription: Bool {
        !customerInfoViewModel.subscriptionsSection.isEmpty
    }

    func shouldShowCreateTicketButton(
        supportTickets: CustomerCenterConfigData.Support.SupportTickets?
    ) -> Bool {
        guard let supportTickets = supportTickets,
              supportTickets.allowCreation else {
            return false
        }

        switch supportTickets.customerType {
        case .all:
            return true
        case .active:
            return hasActiveSubscription
        case .notActive:
            return !hasActiveSubscription
        case .none:
            return false
        }
    }

    override var allowMissingPurchase: Bool {
        allowsMissingPurchaseAction
    }

    private var allowsMissingPurchaseAction: Bool = true

    private var refreshingCancellable: AnyCancellable?
    private var cancellables: Set<AnyCancellable> = []
    private let customerInfoViewModel: CustomerCenterViewModel

    init(
        customerInfoViewModel: CustomerCenterViewModel,
        screen: CustomerCenterConfigData.Screen,
        showPurchaseHistory: Bool,
        showVirtualCurrencies: Bool,
        allowsMissingPurchaseAction: Bool,
        actionWrapper: CustomerCenterActionWrapper,
        purchaseInformation: PurchaseInformation? = nil,
        refundRequestStatus: RefundRequestStatus? = nil,
        purchasesProvider: CustomerCenterPurchasesType,
        loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType? = nil) {
            self.showVirtualCurrencies = showVirtualCurrencies
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

    func didAppear() {
        cancellables.removeAll()

        actionWrapper.promotionalOfferSuccessPublisher
            .sink { [weak self] in self?.refreshPurchase() }
            .store(in: &cancellables)

        actionWrapper.showingManageSubscriptionsPublisher
            .sink { [weak self] in self?.customerInfoViewModel.manageSubscriptionsSheet = true }
            .store(in: &cancellables)

        actionWrapper.showingChangePlansPublisher
            .sink { [weak self] _ in self?.customerInfoViewModel.changePlansSheet = true }
            .store(in: &cancellables)
    }

    func refreshPurchase() {
        refreshingCancellable = customerInfoViewModel.publisher(for: purchaseInformation)?
            .dropFirst() // skip current value
            .sink(receiveValue: { @MainActor [weak self] in
                self?.purchaseInformation = $0
                self?.isRefreshing = false
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
        showVirtualCurrencies: Bool,
        allowsMissingPurchaseAction: Bool,
        purchaseInformation: PurchaseInformation? = nil,
        refundRequestStatus: RefundRequestStatus? = nil
    ) {
        self.init(
            customerInfoViewModel: customerInfoViewModel,
            screen: screen,
            showPurchaseHistory: showPurchaseHistory,
            showVirtualCurrencies: showVirtualCurrencies,
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
