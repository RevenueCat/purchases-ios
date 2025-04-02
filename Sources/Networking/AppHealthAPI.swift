//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppHealthAPI.swift
//
//  Created by Pol Piella on 4/2/25.

import Foundation

class AppHealthAPI {

    typealias AppHealthResponseHandler = Backend.ResponseHandler<AppHealthResponse>

    private let appHealthCallbackCache: CallbackCache<AppHealthCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.appHealthCallbackCache = .init()
    }
    
    func getAppHealth(appUserID: String, completion: @escaping AppHealthResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = AppHealthOperation.createFactory(
            configuration: config,
            callbackCache: self.appHealthCallbackCache
        )
        let appHealthCallback = AppHealthCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.appHealthCallbackCache.add(appHealthCallback)
        
        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .default,
            cacheStatus: cacheStatus
        )
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension AppHealthAPI: @unchecked Sendable {}
