//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ObserverModeManager.swift
//
//  Created by Nacho Soto on 7/27/23.

import Foundation
@testable import RevenueCat
import StoreKit
import XCTest

/// A helper for observer mode tests.
final class ObserverModeManager: ObservableObject {

    private let productFetcherSK1: SK1ProductFetcher
    private let productFetcherSK2: SK2ProductFetcher
    private let purchasesManager: ExternalPurchasesManager

    init() {
        self.productFetcherSK1 = .init()
        self.productFetcherSK2 = .init()
        self.purchasesManager = .init(finishTransactions: true)
    }

    @discardableResult
    func purchaseProductFromStoreKit1(
        productIdentifier: String = BaseStoreKitIntegrationTests.monthlyNoIntroProductID
    ) async throws -> SK1Transaction {
        let products = try await self.productFetcherSK1.products(with: [productIdentifier])
        let product = try XCTUnwrap(products.onlyElement)

        return try await self.purchasesManager.purchase(sk1Product: product)
    }

    /// Purchases a product directly with StoreKit.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    @discardableResult
    func purchaseProductFromStoreKit2(
        productIdentifier: String = BaseStoreKitIntegrationTests.monthlyNoIntroProductID
    ) async throws -> Product.PurchaseResult {
        let products = try await StoreKit.Product.products(for: [productIdentifier])
        let product = try XCTUnwrap(products.onlyElement)

        return try await self.purchasesManager.purchase(sk2Product: product)
    }
}
