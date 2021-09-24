//
// Created by Andrés Boedo on 8/11/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit
@testable import RevenueCat

class MockProductsManager: ProductsManager {

    var invokedProductsFromOptimalStoreKitVersion = false
    var invokedProductsFromOptimalStoreKitVersionCount = 0
    var invokedProductsFromOptimalStoreKitVersionParameters: (identifiers: Set<String>, Void)?
    var invokedProductsFromOptimalStoreKitVersionParametersList = [(identifiers: Set<String>, Void)]()
    var stubbedProductsFromOptimalStoreKitVersionCompletionResult: (Set<ProductDetails>, Void)?

    override func productsFromOptimalStoreKitVersion(withIdentifiers identifiers: Set<String>,
                                                     completion: @escaping (Set<ProductDetails>) -> Void) {
        invokedProductsFromOptimalStoreKitVersion = true
        invokedProductsFromOptimalStoreKitVersionCount += 1
        invokedProductsFromOptimalStoreKitVersionParameters = (identifiers, ())
        invokedProductsFromOptimalStoreKitVersionParametersList.append((identifiers, ()))
        if let result = stubbedProductsFromOptimalStoreKitVersionCompletionResult {
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

    var invokedProductsFromOptimalStoreKitVersionAsync = false
    var invokedProductsFromOptimalStoreKitVersionAsyncCount = 0
    var invokedProductsFromOptimalStoreKitVersionAsyncParameters: (identifiers: Set<String>, Void)?
    var invokedProductsFromOptimalStoreKitVersionAsyncParametersList = [(identifiers: Set<String>, Void)]()

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    override func productsFromOptimalStoreKitVersion(withIdentifiers identifiers: Set<String>) async -> Set<ProductDetails> {
        invokedProductsFromOptimalStoreKitVersionAsync = true
        invokedProductsFromOptimalStoreKitVersionAsyncCount += 1
        invokedProductsFromOptimalStoreKitVersionAsyncParameters = (identifiers, ())
        invokedProductsFromOptimalStoreKitVersionAsyncParametersList.append((identifiers, ()))
        let result = stubbedProductsFromOptimalStoreKitVersionCompletionResult?.0 ?? Set<ProductDetails>()
        return result
    }

    var invokedSk2ProductDetails = false
    var invokedSk2ProductDetailsCount = 0
    var invokedSk2ProductDetailsParameters: (identifiers: Set<String>, Void)?
    var invokedSk2ProductDetailsParametersList = [(identifiers: Set<String>, Void)]()

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    override func sk2ProductDetails(withIdentifiers identifiers: Set<String>) async -> Set<SK2ProductDetails> {
        invokedSk2ProductDetails = true
        invokedSk2ProductDetailsCount += 1
        invokedSk2ProductDetailsParameters = (identifiers, ())
        invokedSk2ProductDetailsParametersList.append((identifiers, ()))
        return Set()
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
