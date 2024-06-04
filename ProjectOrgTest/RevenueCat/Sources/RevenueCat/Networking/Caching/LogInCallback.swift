//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LogInCallback.swift
//
//  Created by Joshua Liebowitz on 11/19/21.

import Foundation

struct LogInCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<(info: CustomerInfo, created: Bool), BackendError>) -> Void

}
