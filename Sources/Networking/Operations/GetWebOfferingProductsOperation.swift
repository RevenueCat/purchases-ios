//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetWebOfferingProductsOperation.swift
//
//  Created by Toni Rico on 5/6/25.

import Foundation

final class GetWebOfferingProductsOperation: CacheableNetworkOperation {

    private let webOfferingProductsCallbackCache: CallbackCache<WebOfferingProductsCallback>
    private let configuration: AppUserConfiguration

    static func createFactory(
        configuration: UserSpecificConfiguration,
        webOfferingProductsCallbackCache: CallbackCache<WebOfferingProductsCallback>
    ) -> CacheableNetworkOperationFactory<GetWebOfferingProductsOperation> {
        return .init({ cacheKey in
                    .init(
                        configuration: configuration,
                        webOfferingProductsCallbackCache: webOfferingProductsCallbackCache,
                        cacheKey: cacheKey
                    )
            },
            individualizedCacheKeyPart: configuration.appUserID)
    }

    private init(configuration: UserSpecificConfiguration,
                 webOfferingProductsCallbackCache: CallbackCache<WebOfferingProductsCallback>,
                 cacheKey: String) {
        self.configuration = configuration
        self.webOfferingProductsCallbackCache = webOfferingProductsCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getWebOfferingProducts(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetWebOfferingProductsOperation: @unchecked Sendable {}

private extension GetWebOfferingProductsOperation {

    func getWebOfferingProducts(completion: @escaping () -> Void) {
        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty else {
            self.webOfferingProductsCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let request = HTTPRequest(method: .get, path: .getWebOfferingProducts(appUserID: appUserID))

        httpClient.perform(request) { (response: VerifiedHTTPResponse<WebOfferingProductsResponse>.Result) in
            defer {
                completion()
            }

            self.webOfferingProductsCallbackCache.performOnAllItemsAndRemoveFromCache(
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
