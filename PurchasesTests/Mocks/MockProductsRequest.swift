//
// Created by Andrés Boedo on 8/12/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit
@testable import RevenueCat

class MockProductResponse: SKProductsResponse {
    var mockProducts: [MockSKProduct]

    init(productIdentifiers: Set<String>) {
        self.mockProducts = productIdentifiers.map { identifier in
            return MockSKProduct(mockProductIdentifier: identifier)
        }
        super.init()
    }

    override var products: [SKProduct] {
        return self.mockProducts
    }
}

enum StoreKitError: Error {
    case unknown
}

class MockProductsRequest: SKProductsRequest {
    var startCalled = false
    var requestedIdentifiers: Set<String>
    var fails = false
    var responseTimeInSeconds: Double

    init(productIdentifiers: Set<String>, responseTimeInSeconds: Double = 0) {
        self.requestedIdentifiers = productIdentifiers
        self.responseTimeInSeconds = responseTimeInSeconds
        super.init()
    }

    override func start() {
        startCalled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + responseTimeInSeconds) {
            if (self.fails) {
                self.delegate?.request!(self, didFailWithError: StoreKitError.unknown)
            } else {
                let response = MockProductResponse(productIdentifiers: self.requestedIdentifiers)
                self.delegate?.productsRequest(self, didReceive: response)
            }
        }
    }
}
