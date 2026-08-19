//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardVerificationStatusCallback.swift
//
//  Created by Pol Miro on 20/04/2026.

import Foundation

struct RewardVerificationStatusCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<RewardVerificationStatusResponse, BackendError>) -> Void

}
