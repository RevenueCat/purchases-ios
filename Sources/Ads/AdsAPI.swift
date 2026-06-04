//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdsAPI.swift
//
//  Created by Pol Miro on 20/04/2026.

import Foundation

/// Backend transport for ad-related endpoints.
class AdsAPI {

    typealias RewardVerificationStatusResponseHandler = Backend.ResponseHandler<RewardVerificationStatusResponse>

    private let callbackCache: CallbackCache<RewardVerificationStatusCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.callbackCache = .init()
    }

    func getRewardVerificationStatus(
        appUserID: String,
        clientTransactionID: String,
        completion: @escaping RewardVerificationStatusResponseHandler
    ) {
        let config = GetRewardVerificationStatusOperation.Configuration(
            httpClient: self.backendConfig.httpClient,
            appUserID: appUserID,
            clientTransactionID: clientTransactionID
        )

        let factory = GetRewardVerificationStatusOperation.createFactory(
            configuration: config,
            callbackCache: self.callbackCache
        )

        let callback = RewardVerificationStatusCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.callbackCache.add(callback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .none,
            cacheStatus: cacheStatus
        )
    }
}
