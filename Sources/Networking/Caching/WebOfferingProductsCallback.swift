//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebOfferingProductsCallback.swift
//
//  Created by Toni Rico on 5/6/25.

import Foundation

struct WebOfferingProductsCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<WebOfferingProductsResponse, BackendError>) -> Void

}
