//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowsCallback.swift
//
//  Created by RevenueCat.

import Foundation

struct WorkflowDetailCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<WorkflowDataResult, BackendError>) -> Void

}
