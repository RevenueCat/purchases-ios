//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingsCallback.swift
//
//  Created by Joshua Liebowitz on 11/19/21.

import Foundation

struct OfferingsCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<OfferingsResponse, BackendError>) -> Void

}
