//
// Created by Andrés Boedo on 8/11/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@_spi(Internal) @testable import RevenueCat
import StoreKit

class MockProductsManager: ProductsManager {

    var invokedProducts = false
    var invokedProductsCount = 0
    var invokedProductsParameters: Set<String>?
    var invokedProductsParametersList = [Set<String>]()
    var stubbedProductsCompletionResult: Result<Set<StoreProduct>, PurchasesError>?
    var productResultDelay: TimeInterval?
    var fetchProductsFromStoreKit = false
    var shouldDeferProductsCompletion = false

    // A request is ready only after its result and completion have both been captured.
    var deferredProductsRequestCount: Int {
        self.deferredProductsCompletions.value.count
    }

    private let deferredProductsCompletions: Atomic<[() -> Void]> = .init([])

    override func products(withIdentifiers identifiers: Set<String>,
                           completion: @escaping (Result<Set<StoreProduct>, PurchasesError>) -> Void) {
        self.invokedProducts = true
        self.invokedProductsCount += 1
        self.invokedProductsParameters = identifiers
        self.invokedProductsParametersList.append(identifiers)
        if self.fetchProductsFromStoreKit, self.stubbedProductsCompletionResult == nil {
            super.products(withIdentifiers: identifiers, completion: completion)
            return
        }
        let result: Result<Set<StoreProduct>, PurchasesError>
        if let stubbedResult = self.stubbedProductsCompletionResult {
            result = stubbedResult
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

            result = .success(Set(products))
        }

        let complete = { completion(result) }
        if self.shouldDeferProductsCompletion {
            self.deferredProductsCompletions.modify { $0.append(complete) }
        } else if let delay = self.productResultDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: complete)
        } else {
            complete()
        }
    }

    func completeDeferredProductsRequest(at index: Int) {
        self.deferredProductsCompletions.value[index]()
    }

    var invokedCacheProduct = false
    var invokedCacheProductCount = 0
    var invokedCacheProductParameter: StoreProductType?

    override func cache(_ product: StoreProductType) {
        invokedCacheProduct = true
        invokedCacheProductCount += 1
        invokedCacheProductParameter = product
    }

    var invokedClearCacheCount = 0
    var clearCacheHandler: (() -> Void)?
    override func clearCache() {
        self.invokedClearCacheCount += 1
        self.clearCacheHandler?()
    }

    func resetMock() {
        self.invokedProducts = false
        self.invokedProductsCount = 0
        self.invokedProductsParameters = nil
        self.invokedProductsParametersList = []
        self.stubbedProductsCompletionResult = nil
        self.shouldDeferProductsCompletion = false
        self.deferredProductsCompletions.value = []
        self.invokedCacheProduct = false
        self.invokedCacheProductCount = 0
        self.invokedCacheProductParameter = nil
        self.invokedClearCacheCount = 0
        self.clearCacheHandler = nil
    }
}

extension MockProductsManager: @unchecked Sendable {}
