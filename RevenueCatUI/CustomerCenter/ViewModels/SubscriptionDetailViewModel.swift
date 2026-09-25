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

#if os(macOS)
import AppKit
#endif

#if os(iOS) || os(macOS)

@available(iOS 15.0, macOS 13.0, tvOS 15.0, watchOS 8.0, *)
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
        customerInfoViewModel.subscriptionsSection.contains(where: { !$0.isExpired })
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

    #if os(macOS)
    /// Whether this screen has sent the customer to the App Store's subscriptions page, after
    /// which every return to the app refreshes it.
    private var hasOpenedManageSubscriptions = false

    /// When the page was last opened, while the app has not lost focus since.
    private var lastManageSubscriptionsOpening: Date?
    #endif

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
        loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType? = nil,
        localization: CustomerCenterConfigData.Localization = .default) {
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
            loadPromotionalOfferUseCase: loadPromotionalOfferUseCase,
            localization: localization
        )
    }

    func didAppear() {
        cancellables.removeAll()

        // promotionalOfferSuccessPublisher fires in both paths: with-transaction
        // (via handleAction side effect) and nil-transaction (direct send).
        actionWrapper.promotionalOfferSuccessPublisher
            .sink { [weak self] in self?.refreshPurchase() }
            .store(in: &cancellables)

        actionWrapper.showingManageSubscriptionsPublisher
            .sink { [weak self] in self?.showManageSubscriptions() }
            .store(in: &cancellables)

        actionWrapper.showingChangePlansPublisher
            .sink { [weak self] _ in self?.showChangePlans() }
            .store(in: &cancellables)

        #if os(macOS)
        // macOS opens the App Store's subscriptions page rather than a sheet, so nothing tells the
        // screen the customer is done there: it refreshes when they come back to the app.
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.refreshAfterReturningFromManageSubscriptions() }
            .store(in: &cancellables)
        #endif
    }

    /// Raises `manageSubscriptionsSheet`, which presents StoreKit's manage-subscriptions sheet on
    /// iOS. macOS has no such sheet, so it also opens the App Store's subscriptions page through
    /// the same `showManageSubscriptions()` the core SDK uses (it opens the URL with
    /// `NSWorkspace`); the flag comes back down when the app becomes active again.
    private func showManageSubscriptions() {
        #if os(macOS)
        // A second click while the browser comes up would open the page again. Only for a
        // moment: if the app never loses focus (nothing opened), a later click still works.
        if let lastOpening = self.lastManageSubscriptionsOpening,
           Date().timeIntervalSince(lastOpening) < Self.manageSubscriptionsReopenDelay {
            return
        }
        self.lastManageSubscriptionsOpening = Date()
        self.hasOpenedManageSubscriptions = true
        #endif
        self.customerInfoViewModel.manageSubscriptionsSheet = true
        #if os(macOS)
        Task { [weak self, purchasesProvider] in
            do {
                try await purchasesProvider.showManageSubscriptions()
            } catch {
                Logger.warning(Strings.could_not_show_manage_subscriptions(error))
                // Nothing opened, so no return to the app will lower it, and a retry is welcome.
                self?.customerInfoViewModel.manageSubscriptionsSheet = false
                self?.lastManageSubscriptionsOpening = nil
            }
        }
        #endif
    }

    /// Raises `changePlansSheet`. On macOS, when `SubscriptionStoreView` cannot show (below
    /// macOS 14.0, or no subscription group and fewer than two products), it falls back to
    /// managing the subscription in the App Store, as iOS falls back to StoreKit's
    /// manage-subscriptions sheet: the sheet modifier presents nothing there.
    private func showChangePlans() {
        #if os(macOS)
        guard #available(macOS 14.0, *), ChangePlansSheetViewModifier.presentsStoreView(
            subscriptionGroupID: self.purchaseSubscriptionGroupID,
            productIDs: self.changePlanProductIDs
        ) else {
            self.showManageSubscriptions()
            return
        }
        #endif
        self.customerInfoViewModel.changePlansSheet = true
    }

    #if os(macOS)
    private static let manageSubscriptionsReopenDelay: TimeInterval = 3

    /// The first return lowers the flag, which runs the refresh the sheet's dismissal runs on iOS.
    /// The customer can come back before they finish on the App Store page (it signs them in on
    /// the web first), so every later return refreshes as well, for as long as this screen lives.
    private func refreshAfterReturningFromManageSubscriptions() {
        // Back from wherever the page opened, so a click now is a new request.
        self.lastManageSubscriptionsOpening = nil
        if self.customerInfoViewModel.manageSubscriptionsSheet {
            self.customerInfoViewModel.manageSubscriptionsSheet = false
        } else if self.hasOpenedManageSubscriptions, !self.isRefreshing {
            self.refreshPurchase()
        }
    }
    #endif

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
