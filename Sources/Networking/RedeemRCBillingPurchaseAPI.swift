//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RedeemRCBillingPurchaseAPI.swift
//
//  Created by Antonio Rico Diez on 2024-10-17.

import Foundation

class RedeemRCBillingPurchaseAPI {

    typealias RedeemRCBillingPurchaseResponseHandler = Backend.ResponseHandler<CustomerInfo>

    private let redeemRCBillingPurchaseResponseCallbacksCache: CallbackCache<CustomerInfoCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.redeemRCBillingPurchaseResponseCallbacksCache = .init()
    }

    func postRedeemRCBillingPurchase(appUserID: String,
                                     redemptionToken: String,
                                     completion: @escaping RedeemRCBillingPurchaseResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)

        let factory = PostRedeemRCBillingPurchaseOperation.createFactory(
            configuration: config,
            postData: .init(appUserID: appUserID, redemptionToken: redemptionToken),
            customerInfoCallbackCache: self.redeemRCBillingPurchaseResponseCallbacksCache
        )

        let callback = CustomerInfoCallback(cacheKey: factory.cacheKey,
                                            source: PostRedeemRCBillingPurchaseOperation.self,
                                            completion: completion)
        let cacheStatus = self.redeemRCBillingPurchaseResponseCallbacksCache.add(callback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .none,
            cacheStatus: cacheStatus
        )
    }

}
