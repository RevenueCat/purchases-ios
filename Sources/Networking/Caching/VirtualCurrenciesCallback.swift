//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrenciesCallback.swift
//
//  Created by Will Taylor on 6/10/25.

import Foundation

struct VirtualCurrenciesCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<VirtualCurrenciesResponse, BackendError>) -> Void

}
