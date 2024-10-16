//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetCustomerCenterConfigOperation.swift
//
//
//  Created by Cesar de la Vega on 31/5/24.
//

import Foundation

final class GetCustomerCenterConfigOperation: CacheableNetworkOperation {

    private let customerCenterConfigCallbackCache: CallbackCache<CustomerCenterConfigCallback>
    private let configuration: AppUserConfiguration

    static func createFactory(
        configuration: UserSpecificConfiguration,
        callbackCache: CallbackCache<CustomerCenterConfigCallback>
    ) -> CacheableNetworkOperationFactory<GetCustomerCenterConfigOperation> {
        return .init({ cacheKey in
                .init(
                    configuration: configuration,
                    customerCenterConfigCallbackCache: callbackCache,
                    cacheKey: cacheKey
                )
        },
                     individualizedCacheKeyPart: configuration.appUserID)
    }

    private init(configuration: UserSpecificConfiguration,
                 customerCenterConfigCallbackCache: CallbackCache<CustomerCenterConfigCallback>,
                 cacheKey: String) {
        self.configuration = configuration
        self.customerCenterConfigCallbackCache = customerCenterConfigCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getCustomerCenterConfig(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetCustomerCenterConfigOperation: @unchecked Sendable {}

private extension GetCustomerCenterConfigOperation {

    func getCustomerCenterConfig(completion: @escaping () -> Void) {
        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty else {
            self.customerCenterConfigCallbackCache.performOnAllItemsAndRemoveFromCache(
                withCacheable: self
            ) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let request = HTTPRequest(method: .get, path: .getCustomerCenterConfig(appUserID: appUserID))

        httpClient.perform(request) { (response: VerifiedHTTPResponse<CustomerCenterConfigResponse>.Result) in
            defer {
                completion()
            }

            self.customerCenterConfigCallbackCache.performOnAllItemsAndRemoveFromCache(
                withCacheable: self
            ) { callback in
                callback.completion(
                    response
                        .map { $0.body }
                        .mapError(BackendError.networkError)
                )
            }
        }
    }

}
