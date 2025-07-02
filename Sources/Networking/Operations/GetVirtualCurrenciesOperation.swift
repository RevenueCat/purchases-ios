//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetVirtualCurrenciesOperation.swift
//
//  Created by Will Taylor on 6/9/25.

import Foundation

final class GetVirtualCurrenciesOperation: CacheableNetworkOperation {

    private let virtualCurrenciesCallbackCache: CallbackCache<VirtualCurrenciesCallback>
    private let configuration: AppUserConfiguration

    static func createFactory(
        configuration: UserSpecificConfiguration,
        callbackCache: CallbackCache<VirtualCurrenciesCallback>
    ) -> CacheableNetworkOperationFactory<GetVirtualCurrenciesOperation> {
        return .init({ cacheKey in
                .init(
                    configuration: configuration,
                    virtualCurrenciesCallbackCache: callbackCache,
                    cacheKey: cacheKey
                )
        },
                     individualizedCacheKeyPart: configuration.appUserID)
    }

    private init(
        configuration: UserSpecificConfiguration,
        virtualCurrenciesCallbackCache: CallbackCache<VirtualCurrenciesCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.virtualCurrenciesCallbackCache = virtualCurrenciesCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getVirtualCurrencies(completion: completion)
    }
}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetVirtualCurrenciesOperation: @unchecked Sendable {}

private extension GetVirtualCurrenciesOperation {

    func getVirtualCurrencies(completion: @escaping () -> Void) {
        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty else {
            self.virtualCurrenciesCallbackCache.performOnAllItemsAndRemoveFromCache(
                withCacheable: self
            ) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let request = HTTPRequest(method: .get, path: .getVirtualCurrencies(appUserID: appUserID))

        httpClient.perform(request) { (response: VerifiedHTTPResponse<VirtualCurrenciesResponse>.Result) in
            defer {
                completion()
            }

            self.virtualCurrenciesCallbackCache.performOnAllItemsAndRemoveFromCache(
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
