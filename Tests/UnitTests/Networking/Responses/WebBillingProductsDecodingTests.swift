//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBillingProductsDecodingTests.swift
//
//  Created by Antonio Pallares on 28/7/25.

import Nimble
@testable import RevenueCat
import XCTest

class WebBillingProductsDecodingTests: BaseHTTPResponseTest {

    func testResponseDataIsCorrect() throws {
        let response: WebBillingProductsResponse = try Self.decodeFixture("WebProducts")

        let products = response.productDetails
        expect(products.count).to(equal(2))

        // Then: Validate the yearly product
        let yearly = try XCTUnwrap(products.first { $0.identifier == "product_annual" })
        expect(yearly.title).to(equal("Test Yearly Subscription"))
        expect(yearly.description).to(equal("A test yearly subscription product"))
        expect(yearly.productType).to(equal(.subscription))
        expect(yearly.defaultPurchaseOptionId).to(equal("base_option"))

        let yearlyPurchaseOption = try XCTUnwrap(yearly.purchaseOptions["base_option"])
        let yearlyBase = try XCTUnwrap(yearlyPurchaseOption.base)
        expect(yearlyBase.periodDuration).to(equal("P1Y"))
        expect(yearlyBase.cycleCount).to(equal(1))
        let yearlyPrice = try XCTUnwrap(yearlyBase.price)
        expect(yearlyPrice.amountMicros).to(equal(99_990_000))
        expect(yearlyPrice.currency).to(equal("EUR"))

        // Then: Validate the monthly product
        let monthly = try XCTUnwrap(products.first { $0.identifier == "product_monthly" })
        expect(monthly.title).to(equal("Test Monthly Subscription"))
        expect(monthly.description).to(equal("A test monthly subscription product"))
        expect(monthly.productType).to(equal(.subscription))
        expect(monthly.defaultPurchaseOptionId).to(equal("base_option"))

        let monthlyPurchaseOption = try XCTUnwrap(monthly.purchaseOptions["base_option"])
        let monthlyBase = try XCTUnwrap(monthlyPurchaseOption.base)
        expect(monthlyBase.periodDuration).to(equal("P1M"))
        expect(monthlyBase.cycleCount).to(equal(1))
        let monthlyPrice = try XCTUnwrap(monthlyBase.price)
        expect(monthlyPrice.amountMicros).to(equal(9_990_000))
        expect(monthlyPrice.currency).to(equal("EUR"))
    }

    func testResponseDataIsCorrectWith0WebProducts() throws {
        let response: WebBillingProductsResponse = try Self.decodeFixture("WebProductsEmpty")
        expect(response.productDetails).to(beEmpty())
    }
}
