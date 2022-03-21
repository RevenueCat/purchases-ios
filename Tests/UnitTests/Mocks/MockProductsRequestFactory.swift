//
// Created by Andrés Boedo on 8/12/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat
import StoreKit

class MockProductsRequestFactory: ProductsRequestFactory {

    var invokedRequest = false
    var invokedRequestCount = 0
    var invokedRequestParameters: Set<String>?
    var invokedRequestParametersList = [Set<String>]()
    var stubbedRequestResult: MockProductsRequest!
    var requestResponseTime: DispatchTimeInterval = .seconds(0)

    override func request(productIdentifiers: Set<String>) -> SKProductsRequest {
        invokedRequest = true
        invokedRequestCount += 1
        invokedRequestParameters = productIdentifiers
        invokedRequestParametersList.append(productIdentifiers)
        return stubbedRequestResult ?? MockProductsRequest(productIdentifiers: productIdentifiers,
                                                           responseTime: requestResponseTime)
    }
}
