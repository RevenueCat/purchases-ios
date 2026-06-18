//
//  GetRemoteConfigOperation.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

final class GetRemoteConfigOperation: CacheableNetworkOperation {

    private let callbackCache: CallbackCache<RemoteConfigCallback>

    static func createFactory(
        configuration: NetworkConfiguration,
        callbackCache: CallbackCache<RemoteConfigCallback>
    ) -> CacheableNetworkOperationFactory<GetRemoteConfigOperation> {
        return .init({ cacheKey in
                .init(
                    configuration: configuration,
                    callbackCache: callbackCache,
                    cacheKey: cacheKey
                )
        },
                     individualizedCacheKeyPart: "")
    }

    private init(
        configuration: NetworkConfiguration,
        callbackCache: CallbackCache<RemoteConfigCallback>,
        cacheKey: String
    ) {
        self.callbackCache = callbackCache
        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getRemoteConfig(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetRemoteConfigOperation: @unchecked Sendable {}

private extension GetRemoteConfigOperation {

    func getRemoteConfig(completion: @escaping () -> Void) {
        let request = HTTPRequest(method: .post(RemoteConfigRequest()), path: .remoteConfig)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<RCContainer?>.Result) in
            defer {
                completion()
            }

            self.callbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(response.map(\.body).mapError(BackendError.networkError))
            }
        }
    }

}
