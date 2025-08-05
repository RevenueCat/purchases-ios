//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBillingProductsCallback.swift
//
//  Created by Antonio Pallares on 23/7/25.

import Foundation

struct WebBillingProductsCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<WebBillingProductsResponse, BackendError>) -> Void

}
