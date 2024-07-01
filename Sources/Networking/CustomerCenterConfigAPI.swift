//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterConfigAPI.swift
//
//  Created by Cesar de la Vega on 31/5/24.
//

import Foundation

class CustomerCenterConfigAPI {

    typealias CustomerCenterConfigResponseHandler = Backend.ResponseHandler<CustomerCenterConfigResponse>

    private let customerCenterConfigResponseCallbacksCache: CallbackCache<CustomerCenterConfigCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.customerCenterConfigResponseCallbacksCache = .init()
    }

    func getCustomerCenterConfig(appUserID: String,
                                 isAppBackgrounded: Bool,
                                 completion: @escaping CustomerCenterConfigResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)

        let factory = GetCustomerCenterConfigOperation.createFactory(
            configuration: config,
            callbackCache: self.customerCenterConfigResponseCallbacksCache
        )

        let callback = CustomerCenterConfigCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.customerCenterConfigResponseCallbacksCache.add(callback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .default(forBackgroundedApp: isAppBackgrounded),
            cacheStatus: cacheStatus
        )
    }

}
