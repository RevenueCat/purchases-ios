//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionDetailViewModelTests.swift
//
//  Created by Facundo Menzella on 13/5/25.

import Nimble
@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import StoreKit
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
final class SubscriptionDetailViewModelTests: TestCase {

    func testShouldShowContactSupport() {
        let viewModelAppStore = SubscriptionDetailViewModel(
            customerInfoViewModel: CustomerCenterViewModel(
                uiPreviewPurchaseProvider: MockCustomerCenterPurchases()
            ),
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .appStore, isExpired: false)
        )

        expect(viewModelAppStore.shouldShowContactSupport).to(beFalse())
        expect(viewModelAppStore.allowMissingPurchase).to(beFalse())

        let otherStores = [
            Store.macAppStore,
            .playStore,
            .stripe,
            .promotional,
            .unknownStore,
            .amazon,
            .rcBilling,
            .external
        ]

        otherStores.forEach {
            let viewModelOther = SubscriptionDetailViewModel(
                customerInfoViewModel: CustomerCenterViewModel(
                    uiPreviewPurchaseProvider: MockCustomerCenterPurchases()
                ),
                screen: CustomerCenterConfigData.default.screens[.management]!,
                showPurchaseHistory: false,
                showVirtualCurrencies: false,
                allowsMissingPurchaseAction: true,
                purchaseInformation: .mock(store: $0, isExpired: false)
            )

            expect(viewModelOther.shouldShowContactSupport).to(beTrue())
            expect(viewModelOther.allowMissingPurchase).to(beTrue())
        }
    }

    func testHasActiveSubscription_withActiveSubscriptions() {
        let mockPurchases = MockCustomerCenterPurchases()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)

        // Simulate active subscriptions
        customerInfoViewModel.subscriptionsSection = [
            .mock(store: .playStore, isExpired: false)
        ]

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .playStore, isExpired: false)
        )

        expect(viewModel.hasActiveSubscription).to(beTrue())
    }

    func testHasActiveSubscription_withoutActiveSubscriptions() {
        let mockPurchases = MockCustomerCenterPurchases()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)

        // No active subscriptions
        customerInfoViewModel.subscriptionsSection = []

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .playStore, isExpired: false)
        )

        expect(viewModel.hasActiveSubscription).to(beFalse())
    }

    func testShouldShowCreateTicketButton_customerTypeAll_withActiveSubscription() {
        let mockPurchases = MockCustomerCenterPurchases()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)
        customerInfoViewModel.subscriptionsSection = [.mock(store: .playStore, isExpired: false)]

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .playStore, isExpired: false)
        )

        let supportTickets = CustomerCenterConfigData.Support.SupportTickets(
            allowCreation: true,
            customerType: .all
        )

        expect(viewModel.shouldShowCreateTicketButton(supportTickets: supportTickets)).to(beTrue())
    }

    func testShouldShowCreateTicketButton_customerTypeAll_withoutActiveSubscription() {
        let mockPurchases = MockCustomerCenterPurchases()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)
        customerInfoViewModel.subscriptionsSection = []

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .playStore, isExpired: false)
        )

        let supportTickets = CustomerCenterConfigData.Support.SupportTickets(
            allowCreation: true,
            customerType: .all
        )

        expect(viewModel.shouldShowCreateTicketButton(supportTickets: supportTickets)).to(beTrue())
    }

    func testShouldShowCreateTicketButton_customerTypeActive_withActiveSubscription() {
        let mockPurchases = MockCustomerCenterPurchases()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)
        customerInfoViewModel.subscriptionsSection = [.mock(store: .playStore, isExpired: false)]

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .playStore, isExpired: false)
        )

        let supportTickets = CustomerCenterConfigData.Support.SupportTickets(
            allowCreation: true,
            customerType: .active
        )

        expect(viewModel.shouldShowCreateTicketButton(supportTickets: supportTickets)).to(beTrue())
    }

    func testShouldShowCreateTicketButton_customerTypeActive_withoutActiveSubscription() {
        let mockPurchases = MockCustomerCenterPurchases()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)
        customerInfoViewModel.subscriptionsSection = []

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .playStore, isExpired: false)
        )

        let supportTickets = CustomerCenterConfigData.Support.SupportTickets(
            allowCreation: true,
            customerType: .active
        )

        expect(viewModel.shouldShowCreateTicketButton(supportTickets: supportTickets)).to(beFalse())
    }

    func testShouldShowCreateTicketButton_customerTypeNotActive_withActiveSubscription() {
        let mockPurchases = MockCustomerCenterPurchases()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)
        customerInfoViewModel.subscriptionsSection = [.mock(store: .playStore, isExpired: false)]

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .playStore, isExpired: false)
        )

        let supportTickets = CustomerCenterConfigData.Support.SupportTickets(
            allowCreation: true,
            customerType: .notActive
        )

        expect(viewModel.shouldShowCreateTicketButton(supportTickets: supportTickets)).to(beFalse())
    }

    func testShouldShowCreateTicketButton_customerTypeNotActive_withoutActiveSubscription() {
        let mockPurchases = MockCustomerCenterPurchases()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)
        customerInfoViewModel.subscriptionsSection = []

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .playStore, isExpired: false)
        )

        let supportTickets = CustomerCenterConfigData.Support.SupportTickets(
            allowCreation: true,
            customerType: .notActive
        )

        expect(viewModel.shouldShowCreateTicketButton(supportTickets: supportTickets)).to(beTrue())
    }

    func testShouldShowCreateTicketButton_customerTypeNone() {
        let mockPurchases = MockCustomerCenterPurchases()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)
        customerInfoViewModel.subscriptionsSection = [.mock(store: .playStore, isExpired: false)]

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .playStore, isExpired: false)
        )

        let supportTickets = CustomerCenterConfigData.Support.SupportTickets(
            allowCreation: true,
            customerType: .none
        )

        expect(viewModel.shouldShowCreateTicketButton(supportTickets: supportTickets)).to(beFalse())
    }

    func testShouldShowCreateTicketButton_allowCreationFalse() {
        let mockPurchases = MockCustomerCenterPurchases()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)
        customerInfoViewModel.subscriptionsSection = [.mock(store: .playStore, isExpired: false)]

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .playStore, isExpired: false)
        )

        let supportTickets = CustomerCenterConfigData.Support.SupportTickets(
            allowCreation: false,
            customerType: .all
        )

        expect(viewModel.shouldShowCreateTicketButton(supportTickets: supportTickets)).to(beFalse())
    }

    func testShouldShowCreateTicketButton_nilSupportTickets() {
        let mockPurchases = MockCustomerCenterPurchases()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)
        customerInfoViewModel.subscriptionsSection = [.mock(store: .playStore, isExpired: false)]

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .playStore, isExpired: false)
        )

        expect(viewModel.shouldShowCreateTicketButton(supportTickets: nil)).to(beFalse())
    }
}

#endif
