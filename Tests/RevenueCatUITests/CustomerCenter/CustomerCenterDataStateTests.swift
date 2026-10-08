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
        XCTAssertFalse(detail.relevantPathsForPurchase.contains { $0.type == .cancel || $0.type == .changePlans })
        provider.customerInfo = CustomerInfoFixtures.customerInfoWithLifetimePromotional
        await root.loadScreen()
        XCTAssertEqual(
            detail.purchaseInformation?.productIdentifier,
            "rc_promo_pro_cat_lifetime"
        )
        XCTAssertNil(selectedDetail.purchaseInformation)
        XCTAssertTrue(root.hasAnyPurchases)
        provider.customerInfo = CustomerInfoFixtures.customerInfo(subscriptions: [], entitlements: [])
        await root.loadScreen()
        XCTAssertNil(detail.purchaseInformation)
    }

    func testListClearsSelectionWhenThePurchaseDisappears() async throws {
        let provider = MockCustomerCenterPurchases()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        let list = RelevantPurchasesListViewModel(
            screen: try XCTUnwrap(root.configuration?.screens[.management]),
            actionWrapper: root.actionWrapper, shouldShowSeeAllPurchases: false,
            purchasesProvider: provider
        )
        list.updateSelectedPurchase(using: root)
        XCTAssertNil(list.purchaseInformation)
        list.purchaseInformation = try XCTUnwrap(root.subscriptionsSection.first)
        provider.customerInfo = CustomerInfoFixtures.customerInfoWithExpiredAppleSubscriptions
        await root.loadScreen()
        list.updateSelectedPurchase(using: root)
        XCTAssertTrue(try XCTUnwrap(list.purchaseInformation).isExpired)
        provider.customerInfo = CustomerInfoFixtures.customerInfoWithLifetimePromotional
        await root.loadScreen()
        list.updateSelectedPurchase(using: root)
        XCTAssertTrue(root.hasAnyPurchases)
        XCTAssertNil(list.purchaseInformation)
        list.updateSelectedPurchase(using: root)
        XCTAssertNil(list.purchaseInformation)
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

    func testCapturedOfferingsIncludeV2ComponentsWithoutAnotherFetch() throws {
        let product = TestStoreProduct(
            localizedTitle: "Lifetime", price: 199,
            localizedPriceString: "$199",
            productIdentifier: "test_non_consumable",
            productType: .nonConsumable,
            localizedDescription: "Lifetime"
        ).toStoreProduct()
        let components = PaywallComponentsData(
            templateName: "preview", assetBaseURL: URL(string: "https://example.com")!,
            componentsConfig: .init(base: .init(stack: .init(components: []), stickyFooter: nil,
                                                background: .color(.init(light: .hex("#ffffff"))))),
            componentsLocalizations: ["en_US": [:]], revision: 1, defaultLocaleIdentifier: "en_US"
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        var selected: [String: Any] = [
            "identifier": "template_001", "description": "Preview",
            "paywall_components": try JSONSerialization.jsonObject(with: encoder.encode(components))
        ]
        var response: [String: Any] = [
            "ui_config": try JSONSerialization.jsonObject(with: encoder.encode(PreviewUIConfig.make()))
        ]
        selected["packages"] = [["identifier": "$rc_lifetime", "platform_product_identifier": "test_non_consumable"]]
        response["offerings"] = [selected]
        response["current_offering_id"] = "template_001"
        let offerings = try Offerings.preview(
            responseData: JSONSerialization.data(withJSONObject: response), products: [product]
        )
        XCTAssertNotNil(offerings.current)
        XCTAssertNotNil(offerings.current?.internalPaywallComponents)
        XCTAssertEqual(offerings.current?.lifetime?.storeProduct.productIdentifier, "test_non_consumable")
        selected["paywall_components"] = ["template_name": "unsupported"]
        response["offerings"] = [selected]
        let fallback = try Offerings.preview(
            responseData: JSONSerialization.data(withJSONObject: response), products: [product]
        )
        XCTAssertNotNil(fallback.current?.lifetime)
        XCTAssertNil(fallback.current?.internalPaywallComponents)
        XCTAssertFalse(fallback.current?.hasPaywallComponents ?? true)
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
