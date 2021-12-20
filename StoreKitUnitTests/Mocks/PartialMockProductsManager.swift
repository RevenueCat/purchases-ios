//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PartialMockProductsManager.swift
//
//  Created by César de la Vega on 9/22/21.

import Foundation
@testable import RevenueCat
import StoreKit

class PartialMockProductsManager: ProductsManager {

    var invokedProductsFromOptimalStoreKitVersionWithIdentifiers = false
    var invokedProductsFromOptimalStoreKitVersionCount = 0
    var invokedProductsFromOptimalStoreKitVersionParameters: (identifiers: Set<String>, Void)?
    var invokedProductsFromOptimalStoreKitVersionParametersList = [(identifiers: Set<String>, Void)]()
    var stubbedProductsFromOptimalStoreKitVersionCompletionResult: (Set<StoreProduct>, Void)?

    override func productsFromOptimalStoreKitVersion(
        withIdentifiers identifiers: Set<String>,
        completion: @escaping (Result<Set<StoreProduct>, Error>) -> Void
    ) {
        invokedProductsFromOptimalStoreKitVersionWithIdentifiers = true
        invokedProductsFromOptimalStoreKitVersionCount += 1
        invokedProductsFromOptimalStoreKitVersionParameters = (identifiers, ())
        invokedProductsFromOptimalStoreKitVersionParametersList.append((identifiers, ()))
        if let result = stubbedProductsFromOptimalStoreKitVersionCompletionResult {
            completion(.success(result.0))
        } else {
            let products: [SK1Product] = identifiers.map { (identifier) -> MockSK1Product in
                let sk1Product = MockSK1Product(mockProductIdentifier: identifier)
                sk1Product.mockSubscriptionGroupIdentifier = "1234567"
                if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
                    let mockDiscount = MockDiscount()
                    mockDiscount.mockIdentifier = "discount_id"
                    sk1Product.mockDiscount = mockDiscount
                }
                return sk1Product
            }
            let result = Set(products).map { StoreProduct(sk1Product: $0) }

            completion(.success(Set(result)))
        }
    }

    var invokedProducts = false
    var invokedProductsCount = 0
    var invokedProductsParameters: Set<String>?
    var invokedProductsParametersList = [Set<String>]()
    var stubbedProductsCompletionResult: Set<SK1Product>?

    override func products(
        withIdentifiers identifiers: Set<String>,
        completion: @escaping (Result<Set<SK1Product>, Error>) -> Void
    ) {
        invokedProducts = true
        invokedProductsCount += 1
        invokedProductsParameters = identifiers
        invokedProductsParametersList.append(identifiers)
        if let result = stubbedProductsCompletionResult {
            completion(.success(result))
        } else {
            let products: [SK1Product] = identifiers.map { (identifier) -> MockSK1Product in
                let sk1Product = MockSK1Product(mockProductIdentifier: identifier)
                sk1Product.mockSubscriptionGroupIdentifier = "1234567"
                if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
                    let mockDiscount = MockDiscount()
                    mockDiscount.mockIdentifier = "discount_id"
                    sk1Product.mockDiscount = mockDiscount
                }
                return sk1Product
            }
            completion(.success(Set(products)))
        }
    }

    var invokedCacheProduct = false
    var invokedCacheProductCount = 0
    var invokedCacheProductParameter: SK1Product?

    override func cacheProduct(_ product: SK1Product) {
        invokedCacheProduct = true
        invokedCacheProductCount += 1
        invokedCacheProductParameter = product
    }

    func resetMock() {
        invokedProducts = false
        invokedProductsCount = 0
        invokedProductsParameters = nil
        invokedProductsParametersList = []
        stubbedProductsCompletionResult = nil
        invokedCacheProduct = false
        invokedCacheProductCount = 0
        invokedCacheProductParameter = nil
    }
}
