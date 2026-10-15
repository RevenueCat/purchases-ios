//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPreviewProviderTests.swift
//
//  Created by Monika on 6/10/2026.

import Combine
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
@available(iOS 15.0, *)
@MainActor
final class CustomerCenterPreviewProviderTests: TestCase {
    func testLoadingRefreshesCustomerInfoWithoutSyncingForStandardAndPreviewProviders() async {
        for provider in [CustomerCenterStateTestProvider(), PreviewProvider()] {
            let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)

            await root.loadScreen()

            XCTAssertEqual(root.state, .success)
            XCTAssertEqual(root.customerInfo, provider.mock.customerInfo)
            XCTAssertEqual(provider.mock.customerInfoFetchPolicy, .fetchCurrent)
            XCTAssertEqual(provider.mock.syncPurchasesCount, 0)
        }
    }

    func testLoadingUsesSyncedCustomerInfoForStandardAndPreviewProviders() async {
        for provider in [CustomerCenterStateTestProvider(), PreviewProvider()] {
            let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)

            await root.loadScreen(shouldSync: true)

            XCTAssertEqual(root.state, .success)
            XCTAssertEqual(root.customerInfo, provider.mock.syncPurchasesResult)
            XCTAssertEqual(provider.mock.syncPurchasesCount, 1)
            XCTAssertNil(provider.mock.customerInfoFetchPolicy)
        }
    }

    func testPurchaseCancellationIsRecognizedForStandardAndPreviewProviders() async {
        for provider in [CustomerCenterStateTestProvider(), PreviewProvider()] {
            let model = NoSubscriptionsCardViewModel(screenOffering: nil, purchasesProvider: provider)
            provider.purchaseError = NSError(
                domain: ErrorCode.errorDomain, code: ErrorCode.purchaseCancelledError.rawValue
            )

            let result = await model.performPurchase(packageToPurchase: TestData.packageWithIntroOffer)

            XCTAssertTrue(result.userCancelled)
            XCTAssertNil(result.error)
        }
    }

    func testPurchasePreservesOtherErrorsForStandardAndPreviewProviders() async {
        let errors: [NSError] = [
            NSError(domain: "OtherDomain", code: ErrorCode.purchaseCancelledError.rawValue),
            NSError(domain: ErrorCode.errorDomain, code: ErrorCode.networkError.rawValue),
            CancellationError() as NSError
        ]
        for provider in [CustomerCenterStateTestProvider(), PreviewProvider()] {
            let model = NoSubscriptionsCardViewModel(screenOffering: nil, purchasesProvider: provider)
            for error in errors {
                provider.purchaseError = error

                let result = await model.performPurchase(packageToPurchase: TestData.packageWithIntroOffer)

                XCTAssertFalse(result.userCancelled)
                XCTAssertEqual(result.error as NSError?, error)
            }
        }
    }

    func testPurchasePreservesResultsForStandardAndPreviewProviders() async {
        for provider in [CustomerCenterStateTestProvider(), PreviewProvider()] {
            let model = NoSubscriptionsCardViewModel(screenOffering: nil, purchasesProvider: provider)
            for userCancelled in [false, true] {
                provider.mock.purchasePackageResult = .success((nil, TestData.customerInfo, userCancelled))

                let result = await model.performPurchase(packageToPurchase: TestData.packageWithIntroOffer)

                XCTAssertEqual(result.userCancelled, userCancelled)
                XCTAssertNil(result.error)
            }
        }
    }

    func testStandardLoadingPublishesConfigurationBeforeLoadingProducts() async {
        let provider = StandardLoadingProvider()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        let loadedProducts = expectation(description: "Products loaded after configuration")
        loadedProducts.assertForOverFulfill = false
        provider.beforeLoadingProducts = {
            await MainActor.run {
                XCTAssertNotNil(root.configuration)
                loadedProducts.fulfill()
            }
        }

        await root.loadScreen()

        await fulfillment(of: [loadedProducts], timeout: 2)
        XCTAssertEqual(root.state, .success)
        XCTAssertNotNil(root.customerInfo)
    }

    func testStandardLoadingStillReportsCancellationErrors() async {
        let provider = MockCustomerCenterPurchases(customerInfoError: CancellationError())
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)

        await root.loadScreen()

        guard case let .error(error) = root.state else {
            return XCTFail("Standard loading must retain its existing error behavior")
        }
        XCTAssertTrue(error is CancellationError)
    }

    func testPreviewObservationIgnoresStandardProviders() async {
        let provider = CustomerCenterStateTestProvider()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        let originalInfo = root.customerInfo

        await root.observePreviewCustomerInfoUpdates()

        XCTAssertEqual(root.customerInfo, originalInfo)
    }

    func testPreviewActionsDoNotPresentStoreKitOrCallCustomActionCallbacks() async throws {
        let provider = PreviewProvider()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        let detail = SubscriptionDetailViewModel(
            customerInfoViewModel: root,
            screen: try XCTUnwrap(root.configuration?.screens[.management]),
            showPurchaseHistory: false, showVirtualCurrencies: false, allowsMissingPurchaseAction: false,
            actionWrapper: root.actionWrapper,
            purchaseInformation: root.subscriptionsSection.first,
            purchasesProvider: provider
        )
        detail.didAppear()
        var customActionCalled = false
        let callback = root.actionWrapper.customActionSelectedPublisher.sink { _ in customActionCalled = true }
        defer { callback.cancel() }

        await detail.handleHelpPath(.init(id: "cancel", title: "Cancel", type: .cancel, detail: nil))
        await detail.handleHelpPath(.init(id: "change", title: "Change", type: .changePlans, detail: nil))
        await detail.handleHelpPath(.init(
            id: "custom", title: "Custom", type: .customAction, detail: nil, customActionIdentifier: "example"
        ))

        guard provider.actions.count == 3 else { return XCTFail("Expected three preview actions") }
        guard case .manageSubscriptions = provider.actions[0],
              case let .changePlans(productID, productIDs, groupID) = provider.actions[1],
              case let .customAction(identifier) = provider.actions[2] else {
            return XCTFail("Expected isolated preview actions")
        }
        XCTAssertEqual(productID, detail.purchaseInformation?.productIdentifier)
        XCTAssertEqual(productIDs, detail.changePlanProductIDs)
        XCTAssertEqual(groupID, detail.purchaseSubscriptionGroupID)
        XCTAssertEqual(identifier, "example")
        XCTAssertFalse(root.manageSubscriptionsSheet)
        XCTAssertFalse(root.changePlansSheet)
        XCTAssertFalse(customActionCalled)
    }

    func testPreviewNonAppStoreCancellationReportsManagementURL() async throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/manage"))
        for store in [Store.playStore, .stripe, .rcBilling, .unknownStore] {
            let provider = PreviewProvider()
            let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
            await root.loadScreen()
            let model = BaseManageSubscriptionViewModel(
                screen: try XCTUnwrap(root.configuration?.screens[.management]),
                actionWrapper: root.actionWrapper,
                purchaseInformation: .mock(store: store, isSubscription: true, managementURL: url),
                purchasesProvider: provider
            )

            await model.handleHelpPath(.init(id: "cancel", title: "Cancel", type: .cancel, detail: nil))

            XCTAssertEqual(provider.actions.count, 1)
            guard case let .openURL(receivedURL) = provider.actions.first else {
                XCTFail("Expected preview management URL for \(store)")
                continue
            }
            XCTAssertEqual(receivedURL, url)
            XCTAssertNil(model.inAppBrowserURL)
            XCTAssertFalse(root.manageSubscriptionsSheet)
        }
    }

    func testPreviewNonAppStoreCancellationWithoutManagementURLDoesNothing() async throws {
        let provider = PreviewProvider()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        let purchases: [PurchaseInformation?] = [
            .mock(store: .playStore, managementURL: nil),
            .mock(store: .unknownStore, managementURL: nil),
            nil
        ]
        for purchase in purchases {
            let model = BaseManageSubscriptionViewModel(
                screen: try XCTUnwrap(root.configuration?.screens[.management]),
                actionWrapper: root.actionWrapper,
                purchaseInformation: purchase,
                purchasesProvider: provider
            )

            await model.handleHelpPath(.init(id: "cancel", title: "Cancel", type: .cancel, detail: nil))

            XCTAssertTrue(provider.actions.isEmpty)
            XCTAssertNil(model.inAppBrowserURL)
            XCTAssertFalse(root.manageSubscriptionsSheet)
        }
    }

    func testPreviewURLsDoNotPresentAnInAppBrowser() async throws {
        let provider = PreviewProvider()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        let model = BaseManageSubscriptionViewModel(
            screen: try XCTUnwrap(root.configuration?.screens[.management]),
            actionWrapper: root.actionWrapper, purchasesProvider: provider
        )
        let url = try XCTUnwrap(URL(string: "https://example.com/support"))
        for method in [CustomerCenterConfigData.HelpPath.OpenMethod.inApp, .external] {
            await model.handleHelpPath(.init(
                id: "url", title: "URL", url: url, openMethod: method, type: .customUrl, detail: nil
            ))
        }
        XCTAssertEqual(provider.actions.count, 2)
        for action in provider.actions {
            guard case let .openURL(receivedURL) = action else { return XCTFail("Expected preview URL") }
            XCTAssertEqual(receivedURL, url)
        }
        XCTAssertNil(model.inAppBrowserURL)
    }

    func testPreviewActionFailureDoesNotFallBackToLiveActions() async throws {
        let provider = PreviewProvider()
        provider.actionError = ErrorCode.networkError
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        let model = BaseManageSubscriptionViewModel(
            screen: try XCTUnwrap(root.configuration?.screens[.management]),
            actionWrapper: root.actionWrapper,
            purchaseInformation: .mock(store: .appStore),
            purchasesProvider: provider
        )
        var showedManagement = false
        let callback = root.actionWrapper.showingManageSubscriptionsPublisher.sink { showedManagement = true }
        defer { callback.cancel() }

        await model.handleHelpPath(.init(id: "cancel", title: "Cancel", type: .cancel, detail: nil))

        XCTAssertEqual(provider.actions.count, 1)
        XCTAssertFalse(showedManagement)
    }

    func testPreviewCustomerInfoUpdatesRefreshPurchasesAndStopOnCancellation() async {
        let provider = PreviewProvider()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        provider.mock.customerInfoFetchPolicy = nil
        let next = CustomerInfoFixtures.customerInfoWithLifetimePromotional
        let updated = expectation(description: "Preview customer information updated")
        let subscription = root.$customerInfo.sink { if $0 == next { updated.fulfill() } }
        defer { subscription.cancel() }
        let observation = Task { await root.observePreviewCustomerInfoUpdates() }
        provider.continuation.yield(next)
        await fulfillment(of: [updated], timeout: 2)
        XCTAssertEqual(root.customerInfo, next)
        XCTAssertEqual(root.subscriptionsSection.first?.productIdentifier, "rc_promo_pro_cat_lifetime")
        XCTAssertTrue(root.nonSubscriptionsSection.isEmpty)
        XCTAssertNil(provider.mock.customerInfoFetchPolicy)
        XCTAssertEqual(provider.mock.syncPurchasesCount, 0)

        observation.cancel()
        await observation.value
        provider.continuation.yield(CustomerInfoFixtures.customerInfoWithExpiredAppleSubscriptions)
        XCTAssertEqual(root.customerInfo, next)
    }

    func testCancellingInFlightCustomerInfoUpdatePreservesDisplayedPurchases() async {
        let provider = PreviewProvider()
        provider.mock.customerInfo = CustomerInfoFixtures.customerInfoWithLifetimePromotional
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        let originalInfo = root.customerInfo
        let originalProducts = root.subscriptionsSection.map(\.productIdentifier)
        let requestedProducts = expectation(description: "Update is waiting for products")
        let resumeProducts = Atomic<CheckedContinuation<Void, Never>?>(nil)
        let didSuspend = Atomic(false)
        provider.beforeLoadingProducts = {
            if !didSuspend.getAndSet(true) {
                await withCheckedContinuation { continuation in
                    resumeProducts.value = continuation
                    requestedProducts.fulfill()
                }
            }
        }

        let observation = Task { await root.observePreviewCustomerInfoUpdates() }
        provider.continuation.yield(CustomerInfoFixtures.customerInfoWithAppleSubscriptions)
        await fulfillment(of: [requestedProducts], timeout: 2)
        observation.cancel()
        resumeProducts.getAndSet(nil)?.resume()
        await observation.value

        XCTAssertEqual(root.customerInfo, originalInfo)
        XCTAssertEqual(root.subscriptionsSection.map(\.productIdentifier), originalProducts)
        XCTAssertTrue(root.nonSubscriptionsSection.isEmpty)
    }

    func testReloadClearsAppUpdateActionWhenNewConfigurationHasNoProductID() async throws {
        let provider = PreviewProvider()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        XCTAssertNotNil(root.onUpdateAppClick)
        let original = try XCTUnwrap(root.configuration)
        provider.mock.loadCustomerCenterResult = .success(CustomerCenterConfigData(
            screens: original.screens, appearance: original.appearance, localization: original.localization,
            support: original.support, changePlans: original.changePlans,
            lastPublishedAppVersion: original.lastPublishedAppVersion, productId: nil
        ))

        await root.loadScreen()

        XCTAssertNil(root.onUpdateAppClick)
    }

}

@available(iOS 15.0, *)
private final class StandardLoadingProvider: CustomerCenterStateTestProvider, @unchecked Sendable {
    var beforeLoadingProducts: (@Sendable () async -> Void)?

    override func products(_ ids: [String]) async -> [StoreProduct] {
        await beforeLoadingProducts?()
        return await super.products(ids)
    }
}

@available(iOS 15.0, *)
private final class PreviewProvider: CustomerCenterStateTestProvider,
                                     CustomerCenterPreviewProvider, @unchecked Sendable {
    let stream: AsyncStream<CustomerInfo>
    let continuation: AsyncStream<CustomerInfo>.Continuation
    var actions: [CustomerCenterPreviewAction] = []
    var actionError: Error?
    var beforeLoadingProducts: (@Sendable () async -> Void)?
    override init() {
        (stream, continuation) = AsyncStream.makeStream()
        super.init()
    }
    override func products(_ ids: [String]) async -> [StoreProduct] {
        await beforeLoadingProducts?()
        return await super.products(ids)
    }
    func customerInfoUpdates() async -> AsyncStream<CustomerInfo> { stream }
    func handlePreviewAction(_ action: CustomerCenterPreviewAction) async throws {
        actions.append(action)
        if let actionError { throw actionError }
    }
}
#endif
