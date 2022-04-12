//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoCallback.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

struct CustomerInfoCallback: CacheKeyProviding {

    typealias Completion = (Result<CustomerInfo, BackendError>) -> Void

    let cacheKey: String
    let source: NetworkOperation.Type
    let completion: Completion

    init(operation: CacheableNetworkOperation, completion: @escaping Completion) {
        self.cacheKey = operation.cacheKey
        self.source = type(of: operation)
        self.completion = completion
    }

}
