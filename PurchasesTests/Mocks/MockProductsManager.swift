//
// Created by Andrés Boedo on 8/11/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit
@testable import RevenueCat

class MockProductsManager: ProductsManager {

    var invokedProductsFromOptimalStoreKitVersionWithIdentifiers = false
    var invokedProductsFromOptimalStoreKitVersionWithIdentifiersCount = 0
    var invokedProductsFromOptimalStoreKitVersionWithIdentifiersParameters: (identifiers: Set<String>, Void)?
    var invokedProductsFromOptimalStoreKitVersionWithIdentifiersParametersList = [(identifiers: Set<String>, Void)]()
    var stubbedProductsFromOptimalStoreKitVersionWithIdentifiersCompletionResult: (Set<ProductDetails>, Void)?

    override func productsFromOptimalStoreKitVersion(withIdentifiers identifiers: Set<String>,
        completion: @escaping (Set<ProductDetails>) -> Void) {
        invokedProductsFromOptimalStoreKitVersionWithIdentifiers = true
        invokedProductsFromOptimalStoreKitVersionWithIdentifiersCount += 1
        invokedProductsFromOptimalStoreKitVersionWithIdentifiersParameters = (identifiers, ())
        invokedProductsFromOptimalStoreKitVersionWithIdentifiersParametersList.append((identifiers, ()))
        if let result = stubbedProductsFromOptimalStoreKitVersionWithIdentifiersCompletionResult {
            completion(result.0)
        } else {
            let products: [SK1Product] = identifiers.map { (identifier) -> MockSK1Product in
                let p = MockSK1Product(mockProductIdentifier: identifier)
                p.mockSubscriptionGroupIdentifier = "1234567"
                if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
                    let mockDiscount = MockDiscount()
                    mockDiscount.mockIdentifier = "discount_id"
                    p.mockDiscount = mockDiscount
                }
                return p
            }
            let result = Set(products).map { SK1ProductDetails(sk1Product: $0) }

            completion(Set(result))
        }
    }

    var invokedProducts = false
    var invokedProductsCount = 0
    var invokedProductsParameters: Set<String>?
    var invokedProductsParametersList = [Set<String>]()
    var stubbedProductsCompletionResult: Set<SK1Product>?

    override func products(withIdentifiers identifiers: Set<String>, completion: @escaping (Set<SK1Product>) -> Void) {
        invokedProducts = true
        invokedProductsCount += 1
        invokedProductsParameters = identifiers
        invokedProductsParametersList.append(identifiers)
        if let result = stubbedProductsCompletionResult {
            completion(result)
        } else {
            let products: [SK1Product] = identifiers.map { (identifier) -> MockSK1Product in
                let p = MockSK1Product(mockProductIdentifier: identifier)
                p.mockSubscriptionGroupIdentifier = "1234567"
                if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
                    let mockDiscount = MockDiscount()
                    mockDiscount.mockIdentifier = "discount_id"
                    p.mockDiscount = mockDiscount
                }
                return p
            }
            completion(Set(products))
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
