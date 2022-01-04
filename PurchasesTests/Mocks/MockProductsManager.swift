//
// Created by Andrés Boedo on 8/11/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat
import StoreKit

// swiftlint:disable line_length
// swiftlint:disable identifier_name
class MockProductsManager: ProductsManager {

    var invokedProductsFromOptimalStoreKitVersionWithIdentifiers = false
    var invokedProductsFromOptimalStoreKitVersionWithIdentifiersCount = 0
    var invokedProductsFromOptimalStoreKitVersionWithIdentifiersParameters: (identifiers: Set<String>, Void)?
    var invokedProductsFromOptimalStoreKitVersionWithIdentifiersParametersList = [(identifiers: Set<String>, Void)]()
    var stubbedProductsFromOptimalStoreKitVersionWithIdentifiersCompletionResult: (Set<StoreProduct>, Void)?

    override func productsFromOptimalStoreKitVersion(withIdentifiers identifiers: Set<String>,
                                                     completion: @escaping (Result<Set<StoreProduct>, Error>) -> Void) {
        invokedProductsFromOptimalStoreKitVersionWithIdentifiers = true
        invokedProductsFromOptimalStoreKitVersionWithIdentifiersCount += 1
        invokedProductsFromOptimalStoreKitVersionWithIdentifiersParameters = (identifiers, ())
        invokedProductsFromOptimalStoreKitVersionWithIdentifiersParametersList.append((identifiers, ()))
        if let result = stubbedProductsFromOptimalStoreKitVersionWithIdentifiersCompletionResult {
            completion(.success(result.0))
        } else {
            let products: [SK1Product] = identifiers.map { (identifier) -> MockSK1Product in
                let product = MockSK1Product(mockProductIdentifier: identifier)
                product.mockSubscriptionGroupIdentifier = "1234567"
                if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
                    let mockDiscount = MockDiscount()
                    mockDiscount.mockIdentifier = "discount_id"
                    product.mockDiscount = mockDiscount
                }
                return product
            }
            let result = Set(products).map { StoreProduct(sk1Product: $0) }

            completion(.success(Set(result)))
        }
    }

    var invokedProductsFromOptimalStoreKitVersion = false
    var invokedProductsFromOptimalStoreKitVersionCount = 0
    var invokedProductsFromOptimalStoreKitVersionParameters: (identifiers: Set<String>, Void)?
    var invokedProductsFromOptimalStoreKitVersionParametersList = [(identifiers: Set<String>, Void)]()

    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    override func productsFromOptimalStoreKitVersion(withIdentifiers identifiers: Set<String>) async -> Set<StoreProduct> {
        invokedProductsFromOptimalStoreKitVersion = true
        invokedProductsFromOptimalStoreKitVersionCount += 1
        invokedProductsFromOptimalStoreKitVersionParameters = (identifiers, ())
        invokedProductsFromOptimalStoreKitVersionParametersList.append((identifiers, ()))
        let result = stubbedProductsFromOptimalStoreKitVersionWithIdentifiersCompletionResult?.0 ?? Set<StoreProduct>()
        return result
    }

    var invokedSk2StoreProduct = false
    var invokedSk2StoreProductCount = 0
    var invokedSk2StoreProductParameters: (identifiers: Set<String>, Void)?
    var invokedSk2StoreProductParametersList = [(identifiers: Set<String>, Void)]()

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    override func sk2StoreProducts(withIdentifiers identifiers: Set<String>) async -> Set<SK2StoreProduct> {
        invokedSk2StoreProduct = true
        invokedSk2StoreProductCount += 1
        invokedSk2StoreProductParameters = (identifiers, ())
        invokedSk2StoreProductParametersList.append((identifiers, ()))
        return Set()
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
                let product = MockSK1Product(mockProductIdentifier: identifier)
                product.mockSubscriptionGroupIdentifier = "1234567"
                if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
                    let mockDiscount = MockDiscount()
                    mockDiscount.mockIdentifier = "discount_id"
                    product.mockDiscount = mockDiscount
                }
                return product
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
