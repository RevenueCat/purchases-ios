//
// Created by Andrés Boedo on 8/12/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit
@testable import RevenueCat

class MockProductResponse: SKProductsResponse {
    var mockProducts: [MockSK1Product]

    init(productIdentifiers: Set<String>) {
        self.mockProducts = productIdentifiers.map { identifier in
            return MockSK1Product(mockProductIdentifier: identifier)
        }
        super.init()
    }

    override var products: [SK1Product] {
        return self.mockProducts
    }
}

class MockProductsRequest: SKProductsRequest {

    enum Error: Swift.Error {
        case unknown
    }

    var startCalled = false
    var cancelCalled = false
    var requestedIdentifiers: Set<String>
    var fails = false
    var responseTimeInSeconds: Int

    init(productIdentifiers: Set<String>, responseTimeInSeconds: Int = 0) {
        self.requestedIdentifiers = productIdentifiers
        self.responseTimeInSeconds = responseTimeInSeconds
        super.init()
    }

    override func start() {
        startCalled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(responseTimeInSeconds)) {
            if (self.fails) {
                self.delegate?.request!(self, didFailWithError: Error.unknown)
            } else {
                let response = MockProductResponse(productIdentifiers: self.requestedIdentifiers)
                self.delegate?.productsRequest(self, didReceive: response)
            }
        }
    }

    override func cancel() {
        cancelCalled = true
    }

}
