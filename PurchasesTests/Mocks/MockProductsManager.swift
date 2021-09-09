//
// Created by Andrés Boedo on 8/11/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit
@testable import RevenueCat

class MockProductsManager: ProductsManager {

    var invokedProducts = false
    var invokedProductsCount = 0
    var invokedProductsParameters: Set<String>?
    var invokedProductsParametersList = [Set<String>]()
    var stubbedProductsCompletionResult: Set<SKProduct>?

    override func products(withIdentifiers identifiers: Set<String>, completion: @escaping (Set<SKProduct>) -> Void) {
        invokedProducts = true
        invokedProductsCount += 1
        invokedProductsParameters = identifiers
        invokedProductsParametersList.append(identifiers)
        if let result = stubbedProductsCompletionResult {
            completion(result)
        } else {
            let products: [SKProduct] = identifiers.map { (identifier) -> MockSKProduct in
                let p = MockSKProduct(mockProductIdentifier: identifier)
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
    var invokedCacheProductParameter: SKProduct?

    override func cacheProduct(_ product: SKProduct) {
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
