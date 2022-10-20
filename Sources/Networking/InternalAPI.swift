//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InternalAPI.swift
//
//  Created by Nacho Soto on 10/5/22.

import Foundation

final class InternalAPI {

    typealias ResponseHandler = (BackendError?) -> Void

    private let backendConfig: BackendConfiguration
    private let callbackCache: CallbackCache<HealthOperation.Callback>

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.callbackCache = .init()
    }

    func healthRequest(completion: @escaping ResponseHandler) {
        let operation = HealthOperation(httpClient: self.backendConfig.httpClient,
                                        callbackCache: self.callbackCache)

        let callback = HealthOperation.Callback(cacheKey: operation.cacheKey, completion: completion)
        let cacheStatus = self.callbackCache.add(callback)

        self.backendConfig.addCacheableOperation(operation,
                                                 withRandomDelay: false,
                                                 cacheStatus: cacheStatus)
    }

}

// MARK: - Health

private class HealthOperation: CacheableNetworkOperation {

    struct Callback: CacheKeyProviding {

        let cacheKey: String
        let completion: InternalAPI.ResponseHandler

    }

    struct Configuration: NetworkConfiguration {

        let httpClient: HTTPClient

    }

    private let callbackCache: CallbackCache<Callback>

    init(httpClient: HTTPClient,
         callbackCache: CallbackCache<Callback>) {
        self.callbackCache = callbackCache

        super.init(configuration: Configuration(httpClient: httpClient),
                   individualizedCacheKeyPart: "")
    }

    override func begin(completion: @escaping () -> Void) {
        self.httpClient.perform(
            .init(method: .get, path: .health)
        ) { (response: HTTPResponse<HTTPEmptyResponseBody>.Result) in
            self.callbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(
                    response
                        .mapError(BackendError.networkError)
                        .error
                )
            }

            completion()
        }
    }

}
