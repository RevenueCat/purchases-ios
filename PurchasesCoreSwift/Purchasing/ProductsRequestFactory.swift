//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// Created by Andrés Boedo on 8/12/20.
//

import Foundation
import StoreKit

class ProductsRequestFactory {

    func request(productIdentifiers: Set<String>) -> SKProductsRequest {
        return SKProductsRequest(productIdentifiers: productIdentifiers)
    }

}
