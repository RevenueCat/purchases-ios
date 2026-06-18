//
//  RemoteConfigCallback.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

struct RemoteConfigCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<RCContainer, BackendError>) -> Void

}
