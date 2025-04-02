//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppHealthOperation.swift
//
//
//  Created by Pol Piella Abadia on 2/4/25.
//

import Foundation

struct AppHealthCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: (Result<AppHealthResponse, BackendError>) -> Void

}

final class AppHealthOperation: CacheableNetworkOperation {

    private let appHealthCallbackCache: CallbackCache<AppHealthCallback>
    private let configuration: AppUserConfiguration

    static func createFactory(
        configuration: UserSpecificConfiguration,
        callbackCache: CallbackCache<AppHealthCallback>
    ) -> CacheableNetworkOperationFactory<AppHealthOperation> {
        return .init({ cacheKey in
                .init(
                    configuration: configuration,
                    appHealthCallbackCache: callbackCache,
                    cacheKey: cacheKey
                )
        },
                     individualizedCacheKeyPart: configuration.appUserID)
    }

    private init(configuration: UserSpecificConfiguration,
                 appHealthCallbackCache: CallbackCache<AppHealthCallback>,
                 cacheKey: String) {
        self.configuration = configuration
        self.appHealthCallbackCache = appHealthCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getAppHealth(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension AppHealthOperation: @unchecked Sendable {}

private extension AppHealthOperation {

    func getAppHealth(completion: @escaping () -> Void) {
        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty else {
            self.appHealthCallbackCache.performOnAllItemsAndRemoveFromCache(
                withCacheable: self
            ) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let request = HTTPRequest(method: .get, path: .appHealth(appUserID: appUserID))

        httpClient.perform(request) { (response: VerifiedHTTPResponse<AppHealthResponse>.Result) in
            defer {
                completion()
            }

            self.appHealthCallbackCache.performOnAllItemsAndRemoveFromCache(
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
