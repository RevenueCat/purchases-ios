//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitTestHelpers.swift
//
//  Created by Nacho Soto on 1/24/22.

@testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension StoreKitConfigTestCase {

    @MainActor
    @discardableResult
    func simulateAnyPurchase() async throws -> SK2Product {
        let product = try await fetchSk2Product()
        _ = try await product.purchase()

        return product
    }

    @MainActor
    func createTransactionWithPurchase() async throws -> Transaction {
        let product = try await self.simulateAnyPurchase()

        let latestTransaction = await product.latestTransaction
        let transaction = try XCTUnwrap(latestTransaction)

        switch transaction {
        case let .verified(transaction):
            return transaction
        default:
            XCTFail("Invalid transaction: \(transaction)")
            fatalError("Unreachable")
        }
    }

    @MainActor
    private func fetchSk2Product() async throws -> SK2Product {
        let products: [Any] = try await StoreKit.Product.products(for: [Self.productID])
        return try XCTUnwrap(products.first as? SK2Product)
    }
}

extension StoreKitConfigTestCase {

    static let productID = "com.revenuecat.monthly_4.99.1_week_intro"

}
