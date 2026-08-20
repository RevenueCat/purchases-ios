//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ChangePlansEmptyConfigTests.swift
//
//  Created by Facundo Menzella on 20/8/26.

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import StoreKit
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
final class ChangePlansEmptyConfigTests: TestCase {

    // A subscription group holding exactly two products. The dashboard treats a group
    // that size as non-configurable, so it never writes a `change_plans` entry and the
    // served config carries `[]`.
    private static let groupID = "pro_group"
    private static let monthlyID = "com.revenuecat.monthly"
    private static let yearlyID = "com.revenuecat.yearly"

    func testEmptyChangePlansConfigLeavesNothingToOffer() async throws {
        let viewModel = await Self.viewModel(changePlans: [])

        // Nothing in the served config matches the subscribed product's group, so the
        // SDK has no product list to hand to StoreKit.
        expect(viewModel.purchaseInformation?.changePlan).to(beNil())
        expect(viewModel.changePlanProductIDs) == []

        // `ChangePlansSheetViewModifier` gates on `productIDs.count >= 2`, so with an
        // empty list it renders `SubscriptionStoreView(groupID:)` instead, showing the
        // entire App Store subscription group rather than the configured products.
        expect(viewModel.changePlanProductIDs.count >= 2).to(beFalse())
    }

    func testConfiguredTwoProductGroupOffersBothProducts() async throws {
        // The response a dashboard that stopped skipping two-product groups would send.
        let changePlan = CustomerCenterConfigData.ChangePlan(
            groupId: Self.groupID,
            groupName: "Pro",
            products: [
                .init(productId: Self.monthlyID, selected: true),
                .init(productId: Self.yearlyID, selected: true)
            ]
        )

        let viewModel = await Self.viewModel(changePlans: [changePlan])

        expect(viewModel.purchaseInformation?.changePlan).toNot(beNil())
        expect(viewModel.changePlanProductIDs) == [Self.monthlyID, Self.yearlyID]

        // Two ids clear the gate, so the sheet lists exactly these products.
        expect(viewModel.changePlanProductIDs.count >= 2).to(beTrue())
    }

    private static func viewModel(
        changePlans: [CustomerCenterConfigData.ChangePlan]
    ) async -> BaseManageSubscriptionViewModel {
        let product = TestStoreProduct(
            localizedTitle: "Monthly Pro",
            price: 9.99,
            currencyCode: "USD",
            localizedPriceString: "$9.99",
            productIdentifier: monthlyID,
            productType: .autoRenewableSubscription,
            localizedDescription: "Pro",
            subscriptionGroupIdentifier: groupID,
            subscriptionPeriod: .init(value: 1, unit: .month),
            locale: Locale(identifier: "en_US")
        ).toStoreProduct()

        let transaction = MockTransaction(
            productIdentifier: monthlyID,
            store: .appStore,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Date().addingTimeInterval(60 * 60 * 24),
                isTrial: false,
                ownershipType: .purchased
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 9.99),
            displayName: "Monthly Pro",
            periodType: .normal,
            purchaseDate: Date(),
            unsubscribeDetectedAt: nil,
            billingIssuesDetectedAt: nil,
            gracePeriodExpiresDate: nil,
            refundedAtDate: nil,
            storeIdentifier: nil,
            identifier: nil,
            originalPurchaseDate: nil,
            isSandbox: false,
            isSubscription: true
        )

        let purchasesProvider = MockCustomerCenterPurchases(products: [product])

        let purchaseInformation = await PurchaseInformation.from(
            transaction: transaction,
            customerInfo: CustomerInfoFixtures.customerInfoWithAppleSubscriptions,
            purchasesProvider: purchasesProvider,
            changePlans: changePlans,
            customerCenterStoreKitUtilities: MockCustomerCenterStoreKitUtilities(),
            localization: CustomerCenterConfigData.mock(lastPublishedAppVersion: nil).localization
        )

        return BaseManageSubscriptionViewModel(
            screen: .init(type: .management, title: "Manage", subtitle: nil, paths: [], offering: nil),
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchaseInformation,
            purchasesProvider: purchasesProvider
        )
    }
}

#endif
