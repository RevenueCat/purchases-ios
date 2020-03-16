//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockRequestFetcher: RCStoreKitRequestFetcher {
    var refreshReceiptCalled = false
    var failProducts = false
    var requestedProducts: Set<String?>?

    override func fetchProducts(_ identifiers: Set<String>, completion: @escaping RCFetchProductsCompletionHandler) {
        if (failProducts) {
            completion([SKProduct]())
            return
        }
        requestedProducts = identifiers
        let products = identifiers.map { (identifier) -> MockProduct in
            let p = MockProduct(mockProductIdentifier: identifier)
            p.mockSubscriptionGroupIdentifier = "1234567"
            p.mockDiscountIdentifier = "discount_id"
            return p
        }
        completion(products)
    }

    override func fetchReceiptData(_ completion: @escaping RCFetchReceiptCompletionHandler) {
        refreshReceiptCalled = true
        completion()
    }
}