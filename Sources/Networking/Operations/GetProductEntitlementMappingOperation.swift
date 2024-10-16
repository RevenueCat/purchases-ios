//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetProductEntitlementMappingOperation.swift
//
//  Created by Nacho Soto on 3/17/23.

import Foundation

final class GetProductEntitlementMappingOperation: CacheableNetworkOperation {

    private let callbackCache: CallbackCache<ProductEntitlementMappingCallback>

    static func createFactory(
        configuration: NetworkConfiguration,
        callbackCache: CallbackCache<ProductEntitlementMappingCallback>
    ) -> CacheableNetworkOperationFactory<GetProductEntitlementMappingOperation> {
        return .init({ cacheKey in
                .init(
                    configuration: configuration,
                    callbackCache: callbackCache,
                    cacheKey: cacheKey
                )
        },
                     individualizedCacheKeyPart: "")
    }

    private init(configuration: NetworkConfiguration,
                 callbackCache: CallbackCache<ProductEntitlementMappingCallback>,
                 cacheKey: String) {
        self.callbackCache = callbackCache
        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getResponse(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetProductEntitlementMappingOperation: @unchecked Sendable {}

private extension GetProductEntitlementMappingOperation {

    func getResponse(completion: @escaping () -> Void) {
        let request = HTTPRequest(method: .get, path: .getProductEntitlementMapping)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<ProductEntitlementMappingResponse>.Result) in
            defer {
                completion()
            }

            self.callbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                callbackObject.completion(response
                    .map { $0.body }
                    .mapError(BackendError.networkError)
                )
            }
        }
    }

}
