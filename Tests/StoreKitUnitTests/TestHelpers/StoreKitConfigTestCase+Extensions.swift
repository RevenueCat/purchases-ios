//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitConfigTestCase+Extensions.swift
//
//  Created by Nacho Soto on 11/17/22.

import Nimble
@testable import RevenueCat
@preconcurrency import StoreKit
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

        let transaction = try await XCTAsyncUnwrap(await product.latestTransaction)

        switch transaction {
        case let .verified(transaction):
            return transaction
        default:
            XCTFail("Invalid transaction: \(transaction)")
            fatalError("Unreachable")
        }
    }

    @MainActor
    func fetchSk2Product(_ productID: String = StoreKitConfigTestCase.productID) async throws -> SK2Product {
        let products: [SK2Product] = try await StoreKit.Product.products(for: [productID])
        return try XCTUnwrap(products.first)
    }

    @MainActor
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func fetchSk2StoreProduct(_ productID: String = StoreKitConfigTestCase.productID) async throws -> SK2StoreProduct {
        return SK2StoreProduct(sk2Product: try await self.fetchSk2Product(productID))
    }

}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *)
extension StoreKitConfigTestCase {

    /// Updates `SKTestSession.storefront` and waits for `Storefront.current` to reflect the change
    /// This is necessary because the change is aynchronous within `StoreKit`, and otherwise code that depends
    /// on the change might not see it in time, resulting in race conditions and flaky tests.
    func changeStorefront(
        _ new: String,
        file: FileString = #fileID,
        line: UInt = #line
    ) async {
        self.testSession.storefront = new

        await asyncWait(
            until: { await Storefront.currentStorefront?.countryCode == new },
            timeout: .seconds(1),
            pollInterval: .milliseconds(100),
            description: "Storefront change not detected"
        )
    }

}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *)
extension StoreKitConfigTestCase {

    static let productID = "com.revenuecat.monthly_4.99.1_week_intro"
    static let lifetimeProductID = "lifetime"

}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *)
fileprivate extension StoreKitConfigTestCase {

    enum Error: Swift.Error {

        case noProductsFound
        case multipleProductsFound

    }

}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *)
extension ProductsFetcherSK1 {

    func product(withIdentifier identifier: String) async throws -> StoreProduct {
        let products = try await self.products(withIdentifiers: Set([identifier]))

        switch products.count {
        case 0: throw StoreKitConfigTestCase.Error.noProductsFound
        case 1: return StoreProduct.from(product: products.first!)
        default: throw StoreKitConfigTestCase.Error.multipleProductsFound
        }
    }

}

@MainActor
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension ProductsFetcherSK2 {

    func product(withIdentifier identifier: String) async throws -> StoreProduct {
        let products = try await self.products(identifiers: Set([identifier]))

        switch products.count {
        case 0: throw StoreKitConfigTestCase.Error.noProductsFound
        case 1: return StoreProduct.from(product: products.first!)
        default: throw StoreKitConfigTestCase.Error.multipleProductsFound
        }
    }

}
