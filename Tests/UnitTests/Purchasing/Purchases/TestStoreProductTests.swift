//
//  TestStoreProductTests.swift
//  UnitTests
//
//  Created by Will Taylor on 5/14/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
import Nimble
@testable import RevenueCat

class TestStoreProductTests: TestCase {

    func testIdReturnsProductIdentifierWithoutInstallmentsInfo() {
        let productIdentifier = "com.revenuecat.product"
        let product = Self.product(productIdentifier: productIdentifier, installmentsInfo: nil)

        expect(product.id) == productIdentifier
    }

    func testIdAddsMonthlyProductPlanIdentifierForMonthlyInstallmentsInfo() {
        let productIdentifier = "com.revenuecat.product"
        let product = Self.product(
            productIdentifier: productIdentifier,
            installmentsInfo: Self.installmentsInfo(billingPlanType: .monthly)
        )

        expect(product.id) == "\(productIdentifier):monthly"
    }

    func testIdReturnsProductIdentifierForUpFrontInstallmentsInfo() {
        let productIdentifier = "com.revenuecat.product"
        let product = Self.product(
            productIdentifier: productIdentifier,
            installmentsInfo: Self.installmentsInfo(billingPlanType: .upFront)
        )

        expect(product.id) == productIdentifier
    }

    func testIdIsUsedByWrappedStoreProduct() {
        let productIdentifier = "com.revenuecat.product"
        let product = Self.product(
            productIdentifier: productIdentifier,
            installmentsInfo: Self.installmentsInfo(billingPlanType: .monthly)
        )

        expect(product.toStoreProduct().id) == "\(productIdentifier):monthly"
    }
}

private extension TestStoreProductTests {

    static func product(
        productIdentifier: String,
        installmentsInfo: InstallmentsInfo?
    ) -> TestStoreProduct {
        return TestStoreProduct(
            localizedTitle: "product",
            price: 3.99,
            currencyCode: "USD",
            localizedPriceString: "$3.99",
            productIdentifier: productIdentifier,
            productType: .autoRenewableSubscription,
            localizedDescription: "",
            subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
            locale: Locale(identifier: "en_US"),
            installmentsInfo: installmentsInfo
        )
    }

    static func installmentsInfo(
        billingPlanType: BillingPlanType
    ) -> InstallmentsInfo {
        return InstallmentsInfo(
            commitmentInstallmentsCount: 3,
            commitmentInstallmentPeriod: SubscriptionPeriod(value: 1, unit: .month),
            installmentBillingPrice: 3.99,
            installmentBillingDisplayPrice: "$3.99",
            commitmentTotalPeriod: SubscriptionPeriod(value: 3, unit: .month),
            commitmentTotalPrice: 11.97,
            commitmentTotalDisplayPrice: "$11.97",
            billingPlanType: billingPlanType
        )
    }

}
