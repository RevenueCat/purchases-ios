//
// Created by Andrés Boedo on 8/12/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat
import StoreKit

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
    var responseTime: DispatchTimeInterval

    init(productIdentifiers: Set<String>, responseTime: DispatchTimeInterval = .seconds(0)) {
        self.requestedIdentifiers = productIdentifiers
        self.responseTime = responseTime
        super.init()
    }

    override func start() {
        startCalled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + self.responseTime) {
            if self.fails {
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
