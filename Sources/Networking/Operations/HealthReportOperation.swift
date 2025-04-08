//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HealthOperation.swift
//
//  Created by Pol Piella on 4/8/25.

import Foundation

final class HealthReportOperation: CacheableNetworkOperation {

    struct Callback: CacheKeyProviding {

        let cacheKey: String
        let completion: InternalAPI.ResponseHandler

    }

    struct Configuration: NetworkConfiguration {

        let httpClient: HTTPClient

    }

    private let callbackCache: CallbackCache<Callback>

    static func createFactory(
        httpClient: HTTPClient,
        callbackCache: CallbackCache<Callback>
    ) -> CacheableNetworkOperationFactory<HealthReportOperation> {
        return .init({ .init(httpClient: httpClient,
                             callbackCache: callbackCache,
                             cacheKey: $0) },
                     individualizedCacheKeyPart: "")
    }

    private init(httpClient: HTTPClient,
                 callbackCache: CallbackCache<Callback>,
                 cacheKey: String) {
        self.callbackCache = callbackCache

        super.init(configuration: Configuration(httpClient: httpClient), cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        let request: HTTPRequest = .init(method: .get, path: .health)

        self.httpClient.perform(
            request
        ) { (response: VerifiedHTTPResponse<HTTPEmptyResponseBody>.Result) in
            self.finish(with: response, completion: completion)
        }
    }

    private func finish(with response: VerifiedHTTPResponse<HTTPEmptyResponseBody>.Result,
                        completion: () -> Void) {
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

// Restating inherited @unchecked Sendable from Foundation's Operation
extension HealthReportOperation: @unchecked Sendable {}
