//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetWebProductsOperation.swift
//
//  Created by Antonio Pallares on 23/7/25.

import Foundation

final class GetWebProductsOperation: CacheableNetworkOperation {

    private let webProductsCallbackCache: CallbackCache<WebProductsCallback>
    private let configuration: AppUserConfiguration
    private let productIds: Set<String>

    static func createFactory(
        configuration: UserSpecificConfiguration,
        webProductsCallbackCache: CallbackCache<WebProductsCallback>,
        productIds: Set<String>
    ) -> CacheableNetworkOperationFactory<GetWebProductsOperation> {
        return .init({ cacheKey in
                    .init(
                        configuration: configuration,
                        webProductsCallbackCache: webProductsCallbackCache,
                        productIds: productIds,
                        cacheKey: cacheKey
                    )
            },
            individualizedCacheKeyPart: configuration.appUserID + "\n" + productIds.sorted().joined(separator: "\n"))
    }

    private init(configuration: UserSpecificConfiguration,
                 webProductsCallbackCache: CallbackCache<WebProductsCallback>,
                 productIds: Set<String>,
                 cacheKey: String) {
        self.configuration = configuration
        self.webProductsCallbackCache = webProductsCallbackCache
        self.productIds = productIds

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getWebProducts(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetWebProductsOperation: @unchecked Sendable {}

private extension GetWebProductsOperation {

    func getWebProducts(completion: @escaping () -> Void) {
        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty else {
            self.webProductsCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let request = HTTPRequest(method: .get, path: .getWebProducts(userId: appUserID, productIds: self.productIds))

        httpClient.perform(request) { (response: VerifiedHTTPResponse<WebProductsResponse>.Result) in
            defer {
                completion()
            }

            self.webProductsCallbackCache.performOnAllItemsAndRemoveFromCache(
                withCacheable: self
            ) { callbackObject in
                callbackObject.completion(response
                    .map { $0.body }
                    .mapError(BackendError.networkError)
                )
            }
        }
    }

}
