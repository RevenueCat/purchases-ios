//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductEntitlementMappingCallback.swift
//
//  Created by Nacho Soto on 3/17/23.

import Foundation

struct ProductEntitlementMappingCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<ProductEntitlementMappingResponse, BackendError>) -> Void

}
