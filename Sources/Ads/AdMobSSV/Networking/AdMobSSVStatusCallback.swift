//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdMobSSVStatusCallback.swift
//
//  Created by Pol Miro on 20/04/2026.

import Foundation

struct AdMobSSVStatusCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<AdMobSSVStatusResponse, BackendError>) -> Void

}
