//
// Created by Andrés Boedo on 8/12/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

@testable import Purchases

class MockProductsRequestFactory: ProductsRequestFactory {

    var invokedRequest = false
    var invokedRequestCount = 0
    var invokedRequestParameters: Set<String>?
    var invokedRequestParametersList = [Set<String>]()
    var stubbedRequestResult: MockProductsRequest!

    override func request(productIdentifiers: Set<String>) -> SKProductsRequest {
        invokedRequest = true
        invokedRequestCount += 1
        invokedRequestParameters = productIdentifiers
        invokedRequestParametersList.append(productIdentifiers)
        return stubbedRequestResult ?? MockProductsRequest(productIdentifiers: productIdentifiers)
    }
}
