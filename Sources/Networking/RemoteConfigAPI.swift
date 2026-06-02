//
//  RemoteConfigAPI.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

class RemoteConfigAPI {

    typealias RemoteConfigResponseHandler = Backend.ResponseHandler<RemoteConfigResponse>

    private let callbackCache: CallbackCache<RemoteConfigCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.callbackCache = .init()
    }

    func getRemoteConfig(
        isAppBackgrounded: Bool,
        completion: @escaping RemoteConfigResponseHandler
    ) {
        let factory = GetRemoteConfigOperation.createFactory(
            configuration: self.backendConfig,
            callbackCache: self.callbackCache
        )

        let callback = RemoteConfigCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.callbackCache.add(callback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .default(forBackgroundedApp: isAppBackgrounded),
            cacheStatus: cacheStatus
        )
    }

}
