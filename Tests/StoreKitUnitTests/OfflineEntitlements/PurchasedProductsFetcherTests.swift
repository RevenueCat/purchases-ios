//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasedProductsFetcherTests.swift
//
//  Created by Nacho Soto on 3/24/23.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class BasePurchasedProductsFetcherTests: StoreKitConfigTestCase {

    fileprivate var sandboxDetector: SandboxEnvironmentDetector!
    fileprivate var fetcher: PurchasedProductsFetcher!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.sandboxDetector = MockSandboxEnvironmentDetector(isSandbox: .random())
        self.fetcher = PurchasedProductsFetcher(sandboxDetector: self.sandboxDetector)
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class PurchasedProductsFetcherTests: BasePurchasedProductsFetcherTests {

    func testNoPurchasedProducts() async throws {
        let products = try await self.fetcher.fetchPurchasedProducts()
        expect(products).to(beEmpty())
    }

    func testOnePurchasedProduct() async throws {
        let transaction = try await self.createTransactionWithPurchase()
        let expiration = try XCTUnwrap(transaction.expirationDate)

        let products = try await self.fetcher.fetchPurchasedProducts()
        expect(products).to(haveCount(1))

        let product = try XCTUnwrap(products.onlyElement)
        let subscription = product.subscription
        let entitlement = product.entitlement

        expect(product.productIdentifier) == transaction.productID

        expect(subscription.periodType) == .trial
        expect(subscription.purchaseDate).to(beCloseToNow())
        expect(subscription.originalPurchaseDate).to(beCloseToNow())
        expect(subscription.expiresDate).to(beCloseToDate(expiration))
        expect(subscription.store) == .appStore
        expect(subscription.isSandbox) == self.sandboxDetector.isSandbox
        expect(subscription.ownershipType) == .purchased

        expect(entitlement.expiresDate).to(beCloseToDate(expiration))
        expect(entitlement.productIdentifier) == transaction.productID
        expect(entitlement.purchaseDate).to(beCloseToNow())
    }

    func testTwoPurchasedProduct() async throws {
        let product1 = try await self.fetchSk2Product(Self.productID)
        let product2 = try await self.fetchSk2Product("com.revenuecat.annual_39.99_no_trial")

        _ = try await self.createTransactionWithPurchase(product: product1)
        _ = try await self.createTransactionWithPurchase(product: product2)

        let products = try await self.fetcher.fetchPurchasedProducts()
        expect(products).to(haveCount(2))
        expect(products.map(\.productIdentifier)).to(contain([
            product1.id,
            product2.id
        ]))
    }

}
