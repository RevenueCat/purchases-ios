//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrenciesAPI.swift
//
//  Created by Will Taylor on 6/10/25.

import Foundation

class VirtualCurrenciesAPI {

    typealias VirtualCurrenciesResponseHandler = Backend.ResponseHandler<VirtualCurrenciesResponse>

    private let virtualCurrenciesResponseCallbacksCache: CallbackCache<VirtualCurrenciesCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.virtualCurrenciesResponseCallbacksCache = .init()
    }

    func getVirtualCurrencies(
        appUserID: String,
        isAppBackgrounded: Bool,
        completion: @escaping VirtualCurrenciesResponseHandler
    ) {
        let config = NetworkOperation.UserSpecificConfiguration(
            httpClient: self.backendConfig.httpClient,
            appUserID: appUserID
        )

        let factory = GetVirtualCurrenciesOperation.createFactory(
            configuration: config,
            callbackCache: self.virtualCurrenciesResponseCallbacksCache
        )

        let callback = VirtualCurrenciesCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.virtualCurrenciesResponseCallbacksCache.add(callback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .default(forBackgroundedApp: isAppBackgrounded),
            cacheStatus: cacheStatus
        )
    }
}
