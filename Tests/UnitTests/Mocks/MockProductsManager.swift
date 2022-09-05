//
// Created by Andrés Boedo on 8/11/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat
import StoreKit

class MockProductsManager: ProductsManager {

    var invokedProducts = false
    var invokedProductsCount = 0
    var invokedProductsParameters: Set<String>?
    var invokedProductsParametersList = [(identifiers: Set<String>, Void)]()
    var stubbedProductsCompletionResult: Result<Set<StoreProduct>, PurchasesError>?

    override func products(withIdentifiers identifiers: Set<String>,
                           completion: @escaping (Result<Set<StoreProduct>, PurchasesError>) -> Void) {
        invokedProducts = true
        invokedProductsCount += 1
        invokedProductsParameters = identifiers
        invokedProductsParametersList.append((identifiers, ()))
        if let result = self.stubbedProductsCompletionResult {
            completion(result)
        } else {
            let products: [StoreProduct] = identifiers
                .map { (identifier) -> MockSK1Product in
                    let product = MockSK1Product(mockProductIdentifier: identifier)
                    product.mockSubscriptionGroupIdentifier = "1234567"
                    if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
                        let mockDiscount = MockSKProductDiscount()
                        mockDiscount.mockIdentifier = "discount_id"
                        product.mockDiscount = mockDiscount
                    }
                    return product
                }
                .map(StoreProduct.init(sk1Product:))

            completion(.success(Set(products)))
        }
    }

    @available(iOS 13.0, tvOS 13.0, watchOS 6.2, macOS 10.15, *)
    override func products(
        withIdentifiers identifiers: Set<String>
    ) async throws -> Set<StoreProduct> {
        invokedProducts = true
        invokedProductsCount += 1
        invokedProductsParameters = identifiers
        invokedProductsParametersList.append((identifiers, ()))

        return try self.stubbedProductsCompletionResult?.get() ?? []
    }

    var invokedCacheProduct = false
    var invokedCacheProductCount = 0
    var invokedCacheProductParameter: SK1Product?

    override func cacheProduct(_ product: SK1Product) {
        invokedCacheProduct = true
        invokedCacheProductCount += 1
        invokedCacheProductParameter = product
    }

    var invokedSk2StoreProducts = false
    var invokedSk2StoreProductsCount = 0
    var invokedSk2StoreProductsParameter: Set<String>?

    var stubbedSk2StoreProductsThrowsError = false
    struct MockSk2StoreProductsError: Error {}

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    override func sk2StoreProducts(withIdentifiers identifiers: Set<String>) async throws -> Set<SK2StoreProduct> {
        invokedSk2StoreProducts = true
        invokedSk2StoreProductsCount += 1
        invokedSk2StoreProductsParameter = identifiers

        if stubbedSk2StoreProductsThrowsError {
            throw MockSk2StoreProductsError()
        } else {
            return try await super.sk2StoreProducts(withIdentifiers: identifiers)
        }
    }

    var invokedInvalidateAndReFetchCachedProductsIfAppropiateCount = 0
    override func invalidateAndReFetchCachedProductsIfAppropiate() {
        invokedInvalidateAndReFetchCachedProductsIfAppropiateCount += 1
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
        invokedInvalidateAndReFetchCachedProductsIfAppropiateCount = 0
    }
}
