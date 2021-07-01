//
// Created by Andrés Boedo on 8/12/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit

// todo: make internal
@objc(RCProductsRequestFactory) public class ProductsRequestFactory: NSObject {
    func request(productIdentifiers: Set<String>) -> SKProductsRequest {
        return SKProductsRequest(productIdentifiers: productIdentifiers)
    }
}
