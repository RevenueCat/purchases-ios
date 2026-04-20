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

/// Backend transport for ad-network–related endpoints.
///
/// Today this only hosts AdMob SSV polling. As the SDK grows additional ad-network
/// endpoints (e.g. other SSV providers, ad-event APIs that don't fit the existing
/// `InternalAPI` events pipeline), they should land here. If the surface area grows
/// unwieldy or the endpoints diverge by network, split into per-network classes
/// (`AdMobAPI`, etc.).
class AdsAPI {

    typealias AdMobSSVStatusResponseHandler = Backend.ResponseHandler<AdMobSSVStatusResponse>

    private let callbackCache: CallbackCache<AdMobSSVStatusCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.callbackCache = .init()
    }

    func getAdMobSSVStatus(
        appUserID: String,
        clientTransactionID: String,
        completion: @escaping AdMobSSVStatusResponseHandler
    ) {
        let config = GetAdMobSSVStatusOperation.Configuration(
            httpClient: self.backendConfig.httpClient,
            appUserID: appUserID,
            clientTransactionID: clientTransactionID
        )

        let factory = GetAdMobSSVStatusOperation.createFactory(
            configuration: config,
            callbackCache: self.callbackCache
        )

        let callback = AdMobSSVStatusCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.callbackCache.add(callback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .none,
            cacheStatus: cacheStatus
        )
    }
}
