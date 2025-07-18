//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RatingsCallback.swift
//
//  Created by RevenueCat on 1/2/25.
//

import Foundation

struct RatingsCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<RatingsResponse, BackendError>) -> Void

}
