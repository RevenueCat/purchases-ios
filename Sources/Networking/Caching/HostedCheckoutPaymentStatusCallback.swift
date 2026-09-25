//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckoutPaymentStatusCallback.swift
//
//  Created by Antonio Pallares on 25/9/26.

import Foundation

struct HostedCheckoutPaymentStatusCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<HostedCheckoutPaymentStatusResponse, BackendError>) -> Void

}
