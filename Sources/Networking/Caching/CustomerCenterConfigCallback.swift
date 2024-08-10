//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterConfigCallback.swift
//
//
//  Created by Cesar de la Vega on 31/5/24.
//

import Foundation

struct CustomerCenterConfigCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<CustomerCenterConfigResponse, BackendError>) -> Void

}
