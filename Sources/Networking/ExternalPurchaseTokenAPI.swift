//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseTokenAPI.swift
//
//  Created by Antonio Pallares on 3/9/26.

import Foundation

class ExternalPurchaseTokenAPI {

    typealias ExternalPurchaseTokenResponseHandler = Backend.ResponseHandler<ExternalPurchaseTokenResponse>

    private let externalPurchaseTokenCallbacksCache: CallbackCache<ExternalPurchaseTokenCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.externalPurchaseTokenCallbacksCache = .init()
    }

    func postExternalPurchaseToken(appUserID: String,
                                   purchaseType: ExternalPurchaseTokenType,
                                   token: String?,
                                   completion: @escaping ExternalPurchaseTokenResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)

        let factory = PostExternalPurchaseTokenOperation.createFactory(
            configuration: config,
            postData: .init(appUserID: appUserID, purchaseType: purchaseType, token: token),
            externalPurchaseTokenCallbackCache: self.externalPurchaseTokenCallbacksCache
        )

        let callback = ExternalPurchaseTokenCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.externalPurchaseTokenCallbacksCache.add(callback)

        // The customer is waiting on this request before checkout can open, so it is never delayed.
        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .none,
            cacheStatus: cacheStatus
        )
    }

}
