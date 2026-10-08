//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterDataStateTests.swift
//
//  Created by Monika on 2026-10-07.

@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
import UIKit

@available(iOS 15.0, *)
@MainActor
final class CustomerCenterDataStateTests: TestCase {
    func testDetailObservesRefundWithoutFirstOpeningManagementSheet() async throws {
        let provider = MockCustomerCenterPurchases()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        let detail = SubscriptionDetailViewModel(
            customerInfoViewModel: root,
            screen: try XCTUnwrap(root.configuration?.screens[.management]),
            showPurchaseHistory: false,
            showVirtualCurrencies: false,
            allowsMissingPurchaseAction: false,
            purchaseObservationMode: .currentPurchase,
            actionWrapper: root.actionWrapper,
            purchaseInformation: root.subscriptionsSection.first,
            purchasesProvider: provider
        )
        detail.didAppear()
        let selectedDetail = SubscriptionDetailViewModel(
            customerInfoViewModel: root,
            screen: try XCTUnwrap(root.configuration?.screens[.management]),
            showPurchaseHistory: false, showVirtualCurrencies: false,
            allowsMissingPurchaseAction: true, purchaseObservationMode: .selectedPurchase,
            actionWrapper: root.actionWrapper,
            purchaseInformation: root.subscriptionsSection.first, purchasesProvider: provider
        )
        selectedDetail.didAppear()
        XCTAssertFalse(try XCTUnwrap(detail.purchaseInformation).isExpired)
        provider.customerInfo = CustomerInfoFixtures.customerInfoWithExpiredAppleSubscriptions
        await root.loadScreen()
        XCTAssertTrue(try XCTUnwrap(detail.purchaseInformation).isExpired)
        XCTAssertTrue(try XCTUnwrap(selectedDetail.purchaseInformation).isExpired)
        XCTAssertFalse(selectedDetail.shouldDismissDetail)
        XCTAssertFalse(detail.relevantPathsForPurchase.contains { $0.type == .cancel || $0.type == .changePlans })
        provider.customerInfo = CustomerInfoFixtures.customerInfoWithLifetimePromotional
        await root.loadScreen()
        XCTAssertEqual(
            detail.purchaseInformation?.productIdentifier,
            "rc_promo_pro_cat_lifetime"
        )
        XCTAssertNil(selectedDetail.purchaseInformation)
        XCTAssertTrue(root.hasAnyPurchases)
        XCTAssertTrue(selectedDetail.shouldDismissDetail)
        XCTAssertFalse(detail.shouldDismissDetail)
        provider.customerInfo = CustomerInfoFixtures.customerInfo(subscriptions: [], entitlements: [])
        await root.loadScreen()
        XCTAssertNil(detail.purchaseInformation)
        XCTAssertFalse(detail.shouldDismissDetail)
    }

    func testMissingSelectedPurchaseReturnsToThePurchasesList() async throws {
        for usesNavigationStack in [false, true] {
            try await assertMissingPurchaseDismissesDetail(usesNavigationStack: usesNavigationStack)
        }
    }

    private func assertMissingPurchaseDismissesDetail(usesNavigationStack: Bool) async throws {
        let provider = MockCustomerCenterPurchases()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        let selected = try XCTUnwrap(root.subscriptionsSection.first)
        let screen = try XCTUnwrap(root.configuration?.screens[.management])
        var isPresented = true
        let popped = expectation(description: "Unavailable purchase detail dismissed")
        let appeared = expectation(description: "Purchase detail appeared")
        let content = Text("Purchases")
            .compatibleNavigation(isPresented: Binding(get: { isPresented }, set: {
                let wasPresented = isPresented
                isPresented = $0
                if wasPresented && !$0 { popped.fulfill() }
            }), usesNavigationStack: usesNavigationStack) {
                SubscriptionDetailView(
                    customerInfoViewModel: root, screen: screen, purchaseInformation: selected,
                    showPurchaseHistory: false, showVirtualCurrencies: false,
                    allowsMissingPurchaseAction: false, purchasesProvider: provider,
                    actionWrapper: root.actionWrapper
                )
                .onAppear { appeared.fulfill() }
            }
            .environment(\.navigationOptions, .init(usesNavigationStack: usesNavigationStack))
        let view = Group {
            if usesNavigationStack {
                CompatibilityNavigationStack { content }
            } else {
                NavigationView { content }.navigationViewStyle(.stack)
            }
        }
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 600))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        controller.view.layoutIfNeeded()
        await fulfillment(of: [appeared], timeout: 3)
        provider.customerInfo = CustomerInfoFixtures.customerInfoWithLifetimePromotional
        await root.loadScreen()
        await fulfillment(of: [popped], timeout: 3)
        XCTAssertFalse(isPresented)
        XCTAssertTrue(root.hasAnyPurchases)
    }

    func testHistoryRecoversAfterFetchFailure() async {
        let provider = CustomerCenterStateTestProvider()
        provider.mock = MockCustomerCenterPurchases(customerInfoError: ErrorCode.networkError)
        let history = PurchaseHistoryViewModel(purchasesProvider: provider, localization: .default)
        await history.didAppear()
        XCTAssertNotNil(history.errorMessage)
        provider.mock = MockCustomerCenterPurchases()
        await history.didAppear()
        XCTAssertNil(history.errorMessage)
        XCTAssertFalse(history.isEmpty)
    }

}

@available(iOS 15.0, *)
class CustomerCenterStateTestProvider: CustomerCenterPurchasesType, @unchecked Sendable {
    var mock = MockCustomerCenterPurchases()
    var purchaseError: Error?
    var isSandbox: Bool { true }
    var appUserID: String { "preview" }
    var isConfigured: Bool { true }
    var storeFrontCountryCode: String? { "US" }
    func customerInfo() async throws -> CustomerInfo { try await mock.customerInfo() }
    func customerInfo(fetchPolicy: CacheFetchPolicy) async throws -> CustomerInfo {
        try await mock.customerInfo(fetchPolicy: fetchPolicy)
    }
    func products(_ ids: [String]) async -> [StoreProduct] { await mock.products(ids) }
    func promotionalOffer(
        forProductDiscount discount: StoreProductDiscount, product: StoreProduct
    ) async throws -> PromotionalOffer {
        try await mock.promotionalOffer(forProductDiscount: discount, product: product)
    }
    func purchase(product: StoreProduct, promotionalOffer: PromotionalOffer?) async throws -> PurchaseResultData {
        try await mock.purchase(product: product, promotionalOffer: promotionalOffer)
    }
    func purchase(package: Package) async throws -> PurchaseResultData {
        if let purchaseError { throw purchaseError }
        return try await mock.purchase(package: package)
    }
    func track(customerCenterEvent: any CustomerCenterEventType) {}
    func loadCustomerCenter() async throws -> CustomerCenterConfigData { try await mock.loadCustomerCenter() }
    func restorePurchases() async throws -> CustomerInfo { try await mock.restorePurchases() }
    func syncPurchases() async throws -> CustomerInfo { try await mock.syncPurchases() }
    func invalidateVirtualCurrenciesCache() {}
    func virtualCurrencies() async throws -> VirtualCurrencies { try await mock.virtualCurrencies() }
    func offerings() async throws -> Offerings { try await mock.offerings() }
    func createTicket(customerEmail: String, ticketDescription: String) async throws -> Bool { true }
    func beginRefundRequest(forProduct productID: String) async throws -> RefundRequestStatus { .success }
    @MainActor func manageSubscriptionsSheetViewModifier(
        isPresented: Binding<Bool>, subscriptionGroupID: String?
    ) -> ManageSubscriptionSheetModifier {
        .init(isPresented: .constant(false), subscriptionGroupID: nil)
    }
}
#endif
