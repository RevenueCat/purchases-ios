//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RedeemWebPurchaseAPI.swift
//
//  Created by Antonio Rico Diez on 2024-10-17.

import Foundation

class RedeemWebPurchaseAPI {

    typealias RedeemWebPurchaseResponseHandler = Backend.ResponseHandler<CustomerInfo>

    private let redeemWebPurchaseResponseCallbacksCache: CallbackCache<CustomerInfoCallback>
    private let backendLanes: BackendLanes

    init(backendLanes: BackendLanes) {
        self.backendLanes = backendLanes
        self.redeemWebPurchaseResponseCallbacksCache = .init()
    }

    func postRedeemWebPurchase(appUserID: String,
                               redemptionToken: String,
                               completion: @escaping RedeemWebPurchaseResponseHandler) {
        let backendConfig = self.backendLanes[HTTPRequest.Path.postRedeemWebPurchase]
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: backendConfig.httpClient,
                                                                appUserID: appUserID)

        let factory = PostRedeemWebPurchaseOperation.createFactory(
            configuration: config,
            postData: .init(appUserID: appUserID, redemptionToken: redemptionToken),
            customerInfoCallbackCache: self.redeemWebPurchaseResponseCallbacksCache
        )

        let callback = CustomerInfoCallback(cacheKey: factory.cacheKey,
                                            appUserID: appUserID,
                                            source: PostRedeemWebPurchaseOperation.self,
                                            completion: completion)
        let cacheStatus = self.redeemWebPurchaseResponseCallbacksCache.add(callback)

        backendConfig.addCacheableOperation(
            with: factory,
            delay: .none,
            cacheStatus: cacheStatus
        )
    }

}
