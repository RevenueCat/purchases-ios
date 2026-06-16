//
//  GetRemoteConfigOperation.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

final class GetRemoteConfigOperation: CacheableNetworkOperation {

    private let callbackCache: CallbackCache<RemoteConfigCallback>
    private let request: RemoteConfigRequest

    static func createFactory(
        configuration: NetworkConfiguration,
        callbackCache: CallbackCache<RemoteConfigCallback>,
        request: RemoteConfigRequest
    ) -> CacheableNetworkOperationFactory<GetRemoteConfigOperation> {
        return .init({ cacheKey in
                .init(
                    configuration: configuration,
                    callbackCache: callbackCache,
                    request: request,
                    cacheKey: cacheKey
                )
        },
                     individualizedCacheKeyPart: request.cacheKey)
    }

    private init(
        configuration: NetworkConfiguration,
        callbackCache: CallbackCache<RemoteConfigCallback>,
        request: RemoteConfigRequest,
        cacheKey: String
    ) {
        self.callbackCache = callbackCache
        self.request = request
        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getRemoteConfig(completion: completion)
    }

}

struct RemoteConfigRequest: Codable, Equatable, HTTPRequestBody {

    let manifest: RemoteConfiguration.Manifest

    private enum CodingKeys: String, CodingKey {
        case manifest
    }

    init(manifest: RemoteConfiguration.Manifest = .init()) {
        self.manifest = manifest
    }

    var cacheKey: String {
        self.manifest.cacheKey
    }

    var contentForSignature: [(key: String, value: String?)] {
        return [
            (Self.CodingKeys.manifest.stringValue, self.manifest.cacheKey)
        ]
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetRemoteConfigOperation: @unchecked Sendable {}

private extension GetRemoteConfigOperation {

    func getRemoteConfig(completion: @escaping () -> Void) {
        let request = HTTPRequest(method: .post(self.request), path: .remoteConfig)

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

private extension RemoteConfiguration.Manifest {

    var cacheKey: String {
        let topicsKey = self.topics
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ",")
        return [
            "domain=\(self.domain)",
            "topics={\(topicsKey)}",
            "prefetch_blobs=\(self.prefetchBlobs.sorted().joined(separator: ","))",
            "prefetched_blobs=\(self.prefetchedBlobs.sorted().joined(separator: ","))",
            "last_refresh_at=\(self.lastRefreshAt)"
        ].joined(separator: "|")
    }

}
