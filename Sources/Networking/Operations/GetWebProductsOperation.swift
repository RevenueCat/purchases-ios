//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetOfferingsOperation.swift
//
//  Created by Joshua Liebowitz on 11/19/21.

import Foundation

final class GetWebProductsOperation: CacheableNetworkOperation {

    private let webProductsCallbackCache: CallbackCache<WebProductsCallback>
    private let configuration: AppUserConfiguration
    private let productIds: Set<String>

    static func createFactory(
        configuration: UserSpecificConfiguration,
        productIds: Set<String>,
        webProductsCallbackCache: CallbackCache<WebProductsCallback>
    ) -> CacheableNetworkOperationFactory<GetWebProductsOperation> {
        return .init({ cacheKey in
                    .init(
                        configuration: configuration,
                        productIds: productIds,
                        webProductsCallbackCache: webProductsCallbackCache,
                        cacheKey: cacheKey
                    )
            },
            individualizedCacheKeyPart: configuration.appUserID)
    }

    private init(configuration: UserSpecificConfiguration,
                 productIds: Set<String>,
                 webProductsCallbackCache: CallbackCache<WebProductsCallback>,
                 cacheKey: String) {
        self.configuration = configuration
        self.productIds = productIds
        self.webProductsCallbackCache = webProductsCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getWebProducts(productIds: productIds, completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetWebProductsOperation: @unchecked Sendable {}

private extension GetWebProductsOperation {

    func getWebProducts(productIds: Set<String>, completion: @escaping () -> Void) {
        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty, !productIds.isEmpty else {
            self.webProductsCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let request = HTTPRequest(method: .get, path: .getWebProducts(appUserId: appUserID, productIds: productIds))

        httpClient.perform(request) { (response: VerifiedHTTPResponse<WebProductsResponse>.Result) in
            defer {
                completion()
            }

            self.webProductsCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                callbackObject.completion(response
                    .map { $0.body }
                    .mapError(BackendError.networkError)
                )
            }
        }
    }

}
