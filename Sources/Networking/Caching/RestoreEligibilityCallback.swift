//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RestoreEligibilityCallback.swift
//
//  Created by Will Taylor on 2/4/26.

import Foundation

struct RestoreEligibilityCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<WillPurchaseBeBlockedByRestoreBehaviorResponse, BackendError>) -> Void

}
