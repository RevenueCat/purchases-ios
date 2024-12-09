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
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.redeemWebPurchaseResponseCallbacksCache = .init()
    }

    func postRedeemWebPurchase(appUserID: String,
                               redemptionToken: String,
                               completion: @escaping RedeemWebPurchaseResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)

        let factory = PostRedeemWebPurchaseOperation.createFactory(
            configuration: config,
            postData: .init(appUserID: appUserID, redemptionToken: redemptionToken),
            customerInfoCallbackCache: self.redeemWebPurchaseResponseCallbacksCache
        )

        let callback = CustomerInfoCallback(cacheKey: factory.cacheKey,
                                            source: PostRedeemWebPurchaseOperation.self,
                                            completion: completion)
        let cacheStatus = self.redeemWebPurchaseResponseCallbacksCache.add(callback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .none,
            cacheStatus: cacheStatus
        )
    }

}
