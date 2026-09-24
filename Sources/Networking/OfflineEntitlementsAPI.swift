//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfflineEntitlementsAPI.swift
//
//  Created by Nacho Soto on 3/22/23.

import Foundation

class OfflineEntitlementsAPI {

    typealias ProductEntitlementMappingResponseHandler = Backend.ResponseHandler<ProductEntitlementMappingResponse>

    private let productEntitlementMappingCallbacksCache: CallbackCache<ProductEntitlementMappingCallback>
    private let backendLanes: BackendLanes

    init(backendLanes: BackendLanes) {
        self.backendLanes = backendLanes
        self.productEntitlementMappingCallbacksCache = .init()
    }

    func getProductEntitlementMapping(isAppBackgrounded: Bool,
                                      completion: @escaping ProductEntitlementMappingResponseHandler) {
        let backendConfig = self.backendLanes[HTTPRequest.Path.getProductEntitlementMapping]
        let factory = GetProductEntitlementMappingOperation.createFactory(
            configuration: backendConfig,
            callbackCache: self.productEntitlementMappingCallbacksCache
        )

        let callback = ProductEntitlementMappingCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.productEntitlementMappingCallbacksCache.add(callback)

        backendConfig.addCacheableOperation(
            with: factory,
            delay: .default(forBackgroundedApp: isAppBackgrounded),
            cacheStatus: cacheStatus
        )
    }

}
