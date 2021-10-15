//
// Created by Andrés Boedo on 8/12/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit
@testable import RevenueCat

class MockProductsRequestFactory: ProductsRequestFactory {

    var invokedRequest = false
    var invokedRequestCount = 0
    var invokedRequestParameters: Set<String>?
    var invokedRequestParametersList = [Set<String>]()
    var stubbedRequestResult: MockProductsRequest!
    var requestResponseTimeInSeconds: Int = 0

    override func request(productIdentifiers: Set<String>) -> SKProductsRequest {
        invokedRequest = true
        invokedRequestCount += 1
        invokedRequestParameters = productIdentifiers
        invokedRequestParametersList.append(productIdentifiers)
        return stubbedRequestResult ?? MockProductsRequest(productIdentifiers: productIdentifiers,
                                                           responseTimeInSeconds: requestResponseTimeInSeconds)
    }
}
