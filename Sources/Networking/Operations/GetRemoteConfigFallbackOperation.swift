//
//  GetRemoteConfigFallbackOperation.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 09/07/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

final class GetRemoteConfigFallbackOperation: CacheableNetworkOperation {

    private let callbackCache: CallbackCache<RemoteConfigFallbackCallback>
    private let domain: String

    static func createFactory(
        configuration: NetworkConfiguration,
        callbackCache: CallbackCache<RemoteConfigFallbackCallback>,
        domain: String
    ) -> CacheableNetworkOperationFactory<GetRemoteConfigFallbackOperation> {
        return .init({ cacheKey in
                .init(
                    configuration: configuration,
                    callbackCache: callbackCache,
                    domain: domain,
                    cacheKey: cacheKey
                )
        },
                     individualizedCacheKeyPart: "domain=\(domain)")
    }

    private init(
        configuration: NetworkConfiguration,
        callbackCache: CallbackCache<RemoteConfigFallbackCallback>,
        domain: String,
        cacheKey: String
    ) {
        self.callbackCache = callbackCache
        self.domain = domain
        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getRemoteConfigFallback(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetRemoteConfigFallbackOperation: @unchecked Sendable {}

private extension GetRemoteConfigFallbackOperation {

    func getRemoteConfigFallback(completion: @escaping () -> Void) {
        let request = HTTPRequest(method: .get, path: HTTPRequest.FallbackPath.remoteConfig(domain: self.domain))

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<RemoteConfiguration>.Result) in
            defer {
                completion()
            }

            self.callbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(
                    response
                        .map(RemoteConfigFallbackFetchResult.init(response:))
                        .mapError(BackendError.networkError)
                )
            }
        }
    }

}
