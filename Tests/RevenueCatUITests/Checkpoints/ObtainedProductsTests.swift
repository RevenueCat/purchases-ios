//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ObtainedProductsTests.swift
//
//  Created by Toni Rico.
//

@_spi(Internal) @testable import RevenueCat
@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) @testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ObtainedProductsTests: TestCase {

    private static let monthly = ObtainedProductsTests.storeProduct(identifier: "monthly")
    private static let annual = ObtainedProductsTests.storeProduct(identifier: "annual")

    func testProductPurchasedSinceTheBaselineIsReported() throws {
        let obtained = try Self.customerInfo(purchaseDatesByProductId: ["monthly": Self.date(10)])
            .obtainedProducts(comparedTo: Self.customerInfo(), from: [Self.monthly, Self.annual])

        XCTAssertEqual(obtained.map(\.product.productIdentifier), ["monthly"])
    }

    func testProductPurchasedOnTheBaselineDateIsNotReported() throws {
        let obtained = try Self.customerInfo(purchaseDatesByProductId: ["monthly": Self.date(10)])
            .obtainedProducts(
                comparedTo: Self.customerInfo(purchaseDatesByProductId: ["monthly": Self.date(10)]),
                from: [Self.monthly]
            )

        XCTAssertTrue(obtained.isEmpty)
    }

    func testProductWithAChangedPurchaseDateIsReported() throws {
        let obtained = try Self.customerInfo(purchaseDatesByProductId: ["monthly": Self.date(20)])
            .obtainedProducts(
                comparedTo: Self.customerInfo(purchaseDatesByProductId: ["monthly": Self.date(10)]),
                from: [Self.monthly]
            )

        XCTAssertEqual(obtained.map(\.product.productIdentifier), ["monthly"])
    }

    func testProductTheFlowDoesNotSellIsNotReported() throws {
        let obtained = try Self.customerInfo(purchaseDatesByProductId: ["lifetime": Self.date(10)])
            .obtainedProducts(comparedTo: Self.customerInfo(), from: [Self.monthly, Self.annual])

        XCTAssertTrue(obtained.isEmpty)
    }

    func testWithoutABaselineEveryPurchasedProductSoldIsReported() throws {
        let obtained = try Self.customerInfo(
            purchaseDatesByProductId: ["monthly": Self.date(10), "annual": Self.date(5), "lifetime": Self.date(1)]
        ).obtainedProducts(comparedTo: nil, from: [Self.monthly, Self.annual])

        XCTAssertEqual(Set(obtained.map(\.product.productIdentifier)), ["monthly", "annual"])
    }

    func testProductSoldByMultiplePackagesIsReportedOnce() throws {
        let obtained = try Self.customerInfo(purchaseDatesByProductId: ["monthly": Self.date(10)])
            .obtainedProducts(
                comparedTo: Self.customerInfo(),
                from: [Self.monthly, Self.storeProduct(identifier: "monthly"), Self.annual]
            )

        XCTAssertEqual(obtained.map(\.product.productIdentifier), ["monthly"])
        XCTAssertEqual(Set(obtained).count, 1)
    }

    func testInstallmentPlanIsMatchedByItsPlanIdentifierAndLookedUpByEither() throws {
        let installments = Self.storeProduct(identifier: "monthly", installmentsInfo: Self.monthlyInstallments)
        let obtained = try Self.customerInfo(purchaseDatesByProductId: ["monthly:monthly": Self.date(10)])
            .obtainedProducts(comparedTo: Self.customerInfo(), from: [installments])
        let flowResult = FlowResult(obtainedEntitlements: [], obtainedProducts: Set(obtained))

        XCTAssertEqual(obtained.map(\.product.id), ["monthly:monthly"])
        XCTAssertEqual(flowResult.obtainedProduct("monthly:monthly")?.product.id, "monthly:monthly")
        XCTAssertTrue(flowResult.didObtainProduct("monthly:monthly"))
        XCTAssertEqual(flowResult.obtainedProduct("monthly")?.product.id, "monthly:monthly")
        XCTAssertTrue(flowResult.didObtainProduct("monthly"))
    }

    func testLookupPrefersTheExactBillingPlanOverThePlainIdentifier() {
        let installments = Self.storeProduct(identifier: "monthly", installmentsInfo: Self.monthlyInstallments)
        let flowResult = FlowResult(
            obtainedEntitlements: [],
            obtainedProducts: [ObtainedProduct(product: installments), ObtainedProduct(product: Self.monthly)]
        )

        XCTAssertEqual(flowResult.obtainedProduct("monthly")?.product.id, "monthly")
        XCTAssertEqual(flowResult.obtainedProduct("monthly:monthly")?.product.id, "monthly:monthly")
        XCTAssertNil(flowResult.obtainedProduct("annual"))
    }

    func testOnlyThePurchasedBillingPlanOfAProductIsReported() throws {
        let installments = Self.storeProduct(identifier: "monthly", installmentsInfo: Self.monthlyInstallments)
        let upFront = Self.monthly

        let obtainedUpFront = try Self.customerInfo(purchaseDatesByProductId: ["monthly": Self.date(10)])
            .obtainedProducts(comparedTo: Self.customerInfo(), from: [upFront, installments])
        let obtainedInstallments = try Self.customerInfo(purchaseDatesByProductId: ["monthly:monthly": Self.date(10)])
            .obtainedProducts(comparedTo: Self.customerInfo(), from: [upFront, installments])

        XCTAssertEqual(obtainedUpFront.map(\.product.id), ["monthly"])
        XCTAssertEqual(obtainedInstallments.map(\.product.id), ["monthly:monthly"])
        XCTAssertNotEqual(ObtainedProduct(product: upFront), ObtainedProduct(product: installments))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension ObtainedProductsTests {

    static let monthlyInstallments = InstallmentsInfo(
        commitmentInstallmentsCount: 12,
        commitmentInstallmentPeriod: SubscriptionPeriod(value: 1, unit: .month),
        installmentBillingPrice: 1.99,
        installmentBillingDisplayPrice: "$1.99",
        commitmentTotalPeriod: SubscriptionPeriod(value: 1, unit: .year),
        commitmentTotalPrice: 23.88,
        commitmentTotalDisplayPrice: "$23.88",
        billingPlanType: .monthly
    )

    static func date(_ seconds: TimeInterval) -> Date {
        return Date(timeIntervalSince1970: seconds)
    }

    static func storeProduct(identifier: String, installmentsInfo: InstallmentsInfo? = nil) -> StoreProduct {
        return TestStoreProduct(
            localizedTitle: identifier,
            price: 1.99,
            currencyCode: "USD",
            localizedPriceString: "$1.99",
            productIdentifier: identifier,
            productType: .autoRenewableSubscription,
            localizedDescription: identifier,
            locale: Locale(identifier: "en_US"),
            installmentsInfo: installmentsInfo
        ).toStoreProduct()
    }

    static func customerInfo(purchaseDatesByProductId: [String: Date] = [:]) throws -> CustomerInfo {
        return CustomerInfo(
            entitlements: EntitlementInfos(entitlements: [:]),
            purchaseDatesByProductId: purchaseDatesByProductId,
            allPurchasedProductIds: Set(purchaseDatesByProductId.keys),
            requestDate: Self.date(0),
            firstSeen: Self.date(0),
            originalAppUserId: "test-user"
        )
    }

}
