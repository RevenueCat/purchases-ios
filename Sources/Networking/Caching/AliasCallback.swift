//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AliasCallback.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

struct AliasCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: ((BackendError?) -> Void)?

}
