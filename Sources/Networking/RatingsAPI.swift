//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RatingsAPI.swift
//
//  Created by RevenueCat on 1/2/25.
//

import Foundation

class RatingsAPI {

    typealias RatingsResponseHandler = Backend.ResponseHandler<RatingsResponse>

    private let ratingsResponseCallbacksCache: CallbackCache<RatingsCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.ratingsResponseCallbacksCache = .init()
    }

    func getRatings(appUserID: String,
                   isAppBackgrounded: Bool,
                   completion: @escaping RatingsResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)

        let factory = GetRatingsOperation.createFactory(
            configuration: config,
            callbackCache: self.ratingsResponseCallbacksCache
        )

        let callback = RatingsCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.ratingsResponseCallbacksCache.add(callback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .default(forBackgroundedApp: isAppBackgrounded),
            cacheStatus: cacheStatus
        )
    }

}
