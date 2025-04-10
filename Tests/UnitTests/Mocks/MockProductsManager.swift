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
    var invokedProductsParametersList = [Set<String>]()
    var stubbedProductsCompletionResult: Result<Set<StoreProduct>, PurchasesError>?
    var productResultDelay: TimeInterval?

    override func products(withIdentifiers identifiers: Set<String>,
                           completion: @escaping (Result<Set<StoreProduct>, PurchasesError>) -> Void) {
        self.invokedProducts = true
        self.invokedProductsCount += 1
        self.invokedProductsParameters = identifiers
        self.invokedProductsParametersList.append(identifiers)
        if let result = self.stubbedProductsCompletionResult {
            if let delay = self.productResultDelay {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    completion(result)
                }
            } else {
                completion(result)
            }
        } else {
            Logger.error("\(type(of: self)): no stubbed products, returning fake products for \(identifiers)")

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

    var invokedCacheProduct = false
    var invokedCacheProductCount = 0
    var invokedCacheProductParameter: StoreProductType?

    override func cache(_ product: StoreProductType) {
        invokedCacheProduct = true
        invokedCacheProductCount += 1
        invokedCacheProductParameter = product
    }

    var invokedSk2StoreProducts = false
    var invokedSk2StoreProductsCount = 0
    var invokedSk2StoreProductsParameter: Set<String>?
    var invokedSk2StoreProductsParameterList: [Set<String>] = []

    // values must be `SK2StoreProduct` (can't use the type because it requires an @available
    var stubbedSk2StoreProductsResult: Result<Set<AnyHashable>, PurchasesError>?

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    override func sk2Products(
        withIdentifiers identifiers: Set<String>,
        completion: @escaping (Result<Set<SK2StoreProduct>, PurchasesError>) -> Void
    ) {
        self.invokedSk2StoreProducts = true
        self.invokedSk2StoreProductsCount += 1
        self.invokedSk2StoreProductsParameter = identifiers
        self.invokedSk2StoreProductsParameterList.append(identifiers)

        if let result = self.stubbedSk2StoreProductsResult {
            // swiftlint:disable:next force_cast
            let storeProducts = result.map { Set($0.map { $0 as! SK2StoreProduct }) }

            if let delay = self.productResultDelay {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    completion(storeProducts)
                }
            } else {
                completion(storeProducts)
            }
        } else {
            super.sk2Products(withIdentifiers: identifiers, completion: completion)
        }
    }

    var invokedClearCacheCount = 0
    override func clearCache() {
        self.invokedClearCacheCount += 1
    }

    func resetMock() {
        self.invokedProducts = false
        self.invokedProductsCount = 0
        self.invokedProductsParameters = nil
        self.invokedProductsParametersList = []
        self.stubbedProductsCompletionResult = nil
        self.invokedCacheProduct = false
        self.invokedCacheProductCount = 0
        self.invokedCacheProductParameter = nil
        self.invokedClearCacheCount = 0
    }
}

extension MockProductsManager: @unchecked Sendable {}
