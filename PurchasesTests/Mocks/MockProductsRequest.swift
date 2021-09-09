//
// Created by Andrés Boedo on 8/12/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit
@testable import RevenueCat

class MockProductResponse: SKProductsResponse {
    var mockProducts: [MockLegacySKProduct]

    init(productIdentifiers: Set<String>) {
        self.mockProducts = productIdentifiers.map { identifier in
            return MockLegacySKProduct(mockProductIdentifier: identifier)
        }
        super.init()
    }

    override var products: [LegacySKProduct] {
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

    override init(productIdentifiers: Set<String>) {
        self.requestedIdentifiers = productIdentifiers
        super.init()
    }

    override func start() {
        startCalled = true
        DispatchQueue.main.async {
            if (self.fails) {
                self.delegate?.request!(self, didFailWithError: StoreKitError.unknown)
            } else {
                let response = MockProductResponse(productIdentifiers: self.requestedIdentifiers)
                self.delegate?.productsRequest(self, didReceive: response)
            }
        }
    }
}
