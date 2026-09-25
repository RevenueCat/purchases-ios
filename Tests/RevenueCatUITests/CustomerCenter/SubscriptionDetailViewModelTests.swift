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

#if os(macOS)
import AppKit
#endif

#if os(iOS) || os(macOS)

@available(iOS 15.0, macOS 13.0, tvOS 15.0, watchOS 8.0, *)
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

    func testHasActiveSubscription_withMultipleActiveSubscriptions() {
        let mockPurchases = MockCustomerCenterPurchases()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)
        customerInfoViewModel.subscriptionsSection = [
            .mock(store: .appStore, isExpired: false),
            .mock(store: .appStore, isExpired: false)
        ]

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .appStore, isExpired: false)
        )

        expect(viewModel.hasActiveSubscription).to(beTrue())
    }

    func testHasActiveSubscription_withExpiredSubscriptionInSection() {
        // Regression: when subscriptionsSection contains an expired subscription
        // (loaded via loadMostRecentExpiredTransaction), hasActiveSubscription must be false
        // regardless of how many subscriptions are in the section.
        let mockPurchases = MockCustomerCenterPurchases()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)
        customerInfoViewModel.subscriptionsSection = [.mock(store: .appStore, isExpired: true)]

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .appStore, isExpired: true)
        )

        expect(viewModel.hasActiveSubscription).to(beFalse())
    }

    func testHasActiveSubscription_withoutActiveSubscriptions() {
        let mockPurchases = MockCustomerCenterPurchases()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)
        customerInfoViewModel.subscriptionsSection = []

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: nil
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
        customerInfoViewModel.subscriptionsSection = [.mock(store: .appStore, isExpired: true)]

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .appStore, isExpired: true)
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
        customerInfoViewModel.subscriptionsSection = [.mock(store: .appStore, isExpired: true)]

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .appStore, isExpired: true)
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
        customerInfoViewModel.subscriptionsSection = [.mock(store: .appStore, isExpired: true)]

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .mock(store: .appStore, isExpired: true)
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

    func testShowingManageSubscriptionsRaisesTheManageSubscriptionsFlag() throws {
        let (viewModel, customerInfoViewModel, actionWrapper, _) = try Self.makeManagementViewModel(
            purchaseInformation: .mock(store: .appStore, isExpired: false)
        )
        viewModel.didAppear()

        actionWrapper.handleAction(.showingManageSubscriptions)

        // Presents StoreKit's sheet on iOS; on macOS it is what the refresh on return keys off.
        expect(customerInfoViewModel.manageSubscriptionsSheet) == true
    }

    #if os(macOS)
    // StoreKit's manage-subscriptions sheet is unavailable on macOS: showing it opens the App
    // Store's subscriptions page through `CustomerCenterPurchasesType.showManageSubscriptions()`,
    // and the flag comes back down when the app becomes active again, which refreshes the screen.
    func testShowingManageSubscriptionsOpensTheAppStoreAndLowersTheFlagOnReturnOnMacOS() async throws {
        let (viewModel, customerInfoViewModel, actionWrapper, mockPurchases) = try Self.makeManagementViewModel(
            purchaseInformation: .mock(store: .appStore, isExpired: false)
        )
        viewModel.didAppear()

        expect(mockPurchases.showManageSubscriptionsCallCount) == 0

        actionWrapper.handleAction(.showingManageSubscriptions)

        await expect(mockPurchases.showManageSubscriptionsCallCount).toEventually(equal(1))
        expect(customerInfoViewModel.manageSubscriptionsSheet) == true

        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)

        expect(customerInfoViewModel.manageSubscriptionsSheet) == false
    }

    // The customer can come back before finishing on the App Store page (it signs them in on the
    // web first), so the first return cannot be the only one that refreshes.
    func testEveryLaterReturnRefreshesTheScreenOnMacOS() async throws {
        let (viewModel, customerInfoViewModel, actionWrapper, mockPurchases) = try Self.makeManagementViewModel(
            purchaseInformation: .mock(store: .appStore, isExpired: false)
        )
        viewModel.didAppear()

        actionWrapper.handleAction(.showingManageSubscriptions)
        await expect(mockPurchases.showManageSubscriptionsCallCount).toEventually(equal(1))

        // The first return lowers the flag, and the view's reaction to that runs the refresh.
        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        expect(customerInfoViewModel.manageSubscriptionsSheet) == false
        expect(mockPurchases.syncPurchasesCount) == 0

        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        await expect(mockPurchases.syncPurchasesCount).toEventually(equal(1))
    }

    func testReturningWithoutHavingOpenedTheAppStoreDoesNotRefreshOnMacOS() async throws {
        let (viewModel, _, _, mockPurchases) = try Self.makeManagementViewModel(
            purchaseInformation: .mock(store: .appStore, isExpired: false)
        )
        viewModel.didAppear()

        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)

        await expect(mockPurchases.syncPurchasesCount).toNever(beGreaterThan(0), until: .milliseconds(300))
    }

    // A second click while the browser comes up must not open the page again.
    func testASecondClickBeforeReturningDoesNotOpenTheAppStoreAgainOnMacOS() async throws {
        let (viewModel, _, actionWrapper, mockPurchases) = try Self.makeManagementViewModel(
            purchaseInformation: .mock(store: .appStore, isExpired: false)
        )
        viewModel.didAppear()

        actionWrapper.handleAction(.showingManageSubscriptions)
        actionWrapper.handleAction(.showingManageSubscriptions)

        await expect(mockPurchases.showManageSubscriptionsCallCount).toEventually(equal(1))
        await expect(mockPurchases.showManageSubscriptionsCallCount)
            .toNever(beGreaterThan(1), until: .milliseconds(300))
    }

    func testAClickAfterReturningOpensTheAppStoreAgainOnMacOS() async throws {
        let (viewModel, _, actionWrapper, mockPurchases) = try Self.makeManagementViewModel(
            purchaseInformation: .mock(store: .appStore, isExpired: false)
        )
        viewModel.didAppear()

        actionWrapper.handleAction(.showingManageSubscriptions)
        await expect(mockPurchases.showManageSubscriptionsCallCount).toEventually(equal(1))

        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        actionWrapper.handleAction(.showingManageSubscriptions)

        await expect(mockPurchases.showManageSubscriptionsCallCount).toEventually(equal(2))
    }

    func testAFailedOpenLowersTheFlagSoTheRowWorksAgainOnMacOS() async throws {
        let mockPurchases = MockCustomerCenterPurchases(
            showManageSubscriptionsError: NSError(domain: "test", code: 1)
        )
        let (viewModel, customerInfoViewModel, actionWrapper, _) = try Self.makeManagementViewModel(
            purchaseInformation: .mock(store: .appStore, isExpired: false),
            mockPurchases: mockPurchases
        )
        viewModel.didAppear()

        actionWrapper.handleAction(.showingManageSubscriptions)

        await expect(customerInfoViewModel.manageSubscriptionsSheet).toEventually(beFalse())

        actionWrapper.handleAction(.showingManageSubscriptions)
        await expect(mockPurchases.showManageSubscriptionsCallCount).toEventually(equal(2))
    }

    // Without a subscription group or two products `SubscriptionStoreView` has nothing to show,
    // and macOS has no manage-subscriptions sheet to fall back to as iOS does.
    func testChangePlansWithoutAStoreViewOpensTheAppStoreOnMacOS() async throws {
        let (viewModel, customerInfoViewModel, actionWrapper, mockPurchases) = try Self.makeManagementViewModel(
            purchaseInformation: .mock(store: .appStore, isExpired: false, subscriptionGroupID: nil)
        )
        viewModel.didAppear()

        actionWrapper.handleAction(.showingChangePlans(nil))

        await expect(mockPurchases.showManageSubscriptionsCallCount).toEventually(equal(1))
        expect(customerInfoViewModel.changePlansSheet) == false
        expect(customerInfoViewModel.manageSubscriptionsSheet) == true
    }
    #endif

    func testChangePlansWithASubscriptionGroupRaisesTheChangePlansFlag() throws {
        let (viewModel, customerInfoViewModel, actionWrapper, mockPurchases) = try Self.makeManagementViewModel(
            purchaseInformation: .mock(store: .appStore, isExpired: false, subscriptionGroupID: "group")
        )
        viewModel.didAppear()

        actionWrapper.handleAction(.showingChangePlans("group"))

        expect(customerInfoViewModel.changePlansSheet) == true
        expect(mockPurchases.showManageSubscriptionsCallCount) == 0
    }

    private static func makeManagementViewModel(
        purchaseInformation: PurchaseInformation,
        mockPurchases: MockCustomerCenterPurchases = MockCustomerCenterPurchases()
    ) throws -> (SubscriptionDetailViewModel, CustomerCenterViewModel, CustomerCenterActionWrapper,
                 MockCustomerCenterPurchases) {
        let actionWrapper = CustomerCenterActionWrapper()
        let customerInfoViewModel = CustomerCenterViewModel(uiPreviewPurchaseProvider: mockPurchases)
        let screen = try XCTUnwrap(CustomerCenterConfigData.default.screens[.management])

        let viewModel = SubscriptionDetailViewModel(
            customerInfoViewModel: customerInfoViewModel,
            screen: screen,
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            actionWrapper: actionWrapper,
            purchaseInformation: purchaseInformation,
            purchasesProvider: mockPurchases
        )
        return (viewModel, customerInfoViewModel, actionWrapper, mockPurchases)
    }
}

#endif
