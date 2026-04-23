//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetAdMobSSVStatusOperation.swift
//
//  Created by Pol Miro on 20/04/2026.

import Foundation

final class GetAdMobSSVStatusOperation: CacheableNetworkOperation {

    struct Configuration: AppUserConfiguration, NetworkConfiguration {

        let httpClient: HTTPClient
        let appUserID: String
        let clientTransactionID: String

    }

    private let callbackCache: CallbackCache<AdMobSSVStatusCallback>
    private let configuration: Configuration

    static func createFactory(
        configuration: Configuration,
        callbackCache: CallbackCache<AdMobSSVStatusCallback>
    ) -> CacheableNetworkOperationFactory<GetAdMobSSVStatusOperation> {
        return .init({ cacheKey in
                .init(
                    configuration: configuration,
                    callbackCache: callbackCache,
                    cacheKey: cacheKey
                )
        },
                     // Use app user ID + client transaction ID to dedupe concurrent polls.
                     // Newline separator avoids collisions (e.g. ("a-b","c") vs ("a","b-c")).
                     individualizedCacheKeyPart: configuration.appUserID + "\n" + configuration.clientTransactionID)
    }

    private init(
        configuration: Configuration,
        callbackCache: CallbackCache<AdMobSSVStatusCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.callbackCache = callbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getAdMobSSVStatus(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetAdMobSSVStatusOperation: @unchecked Sendable {}

private extension GetAdMobSSVStatusOperation {

    func getAdMobSSVStatus(completion: @escaping () -> Void) {
        let appUserID = self.configuration.appUserID
        let clientTransactionID = self.configuration.clientTransactionID

        guard appUserID.isNotEmpty else {
            self.callbackCache.performOnAllItemsAndRemoveFromCache(
                withCacheable: self
            ) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        guard clientTransactionID.isNotEmpty else {
            self.callbackCache.performOnAllItemsAndRemoveFromCache(
                withCacheable: self
            ) { callback in
                callback.completion(.failure(.missingClientTransactionID()))
            }
            completion()

            return
        }

        let request = HTTPRequest(
            method: .get,
            path: .adMobSSVStatus(
                appUserID: appUserID,
                clientTransactionID: clientTransactionID
            )
        )

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<AdMobSSVStatusResponse>.Result) in
            defer { completion() }

            self.callbackCache.performOnAllItemsAndRemoveFromCache(
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
