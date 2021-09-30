//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockRequestFetcher: RCStoreKitRequestFetcher {
    var refreshReceiptCalled = false
    var returnEmptyProducts = false
    var requestedProducts: Set<String?>?

    override func fetchProducts(_ identifiers: Set<String>, completion: @escaping RCFetchProductsCompletionHandler) {
        if (returnEmptyProducts) {
            completion([SKProduct]())
            return
        }
        requestedProducts = identifiers
        let products = identifiers.map { (identifier) -> MockSKProduct in
            let p = MockSKProduct(mockProductIdentifier: identifier)
            p.mockSubscriptionGroupIdentifier = "1234567"
            if #available(iOS 12.2, *) {
                let mockDiscount = MockDiscount()
                mockDiscount.mockIdentifier = "discount_id"
                p.mockDiscount = mockDiscount
            }
            return p
        }
        completion(products)
    }

    override func fetchReceiptData(_ completion: @escaping RCFetchReceiptCompletionHandler) {
        refreshReceiptCalled = true
        completion()
    }
}
