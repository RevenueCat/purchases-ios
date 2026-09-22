//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckoutStatusCallback.swift
//
//  Created by Antonio Pallares on 22/9/26.

import Foundation

struct HostedCheckoutStatusCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<HostedCheckoutStatusResponse, BackendError>) -> Void

}
