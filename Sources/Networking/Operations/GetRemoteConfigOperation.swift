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

    let appUserID: String
    let domain: String
    let manifest: String?
    let prefetchedBlobs: [String]

    private enum CodingKeys: String, CodingKey {
        // JSONDecoder.default converts `app_user_id` to `appUserId` before matching CodingKeys.
        case appUserID = "appUserId"
        case manifest
        case prefetchedBlobs
    }

    init(
        appUserID: String,
        domain: String = RemoteConfiguration.defaultDomain,
        manifest: String? = nil,
        prefetchedBlobs: [String] = []
    ) {
        self.appUserID = appUserID
        self.domain = domain
        self.manifest = manifest
        self.prefetchedBlobs = prefetchedBlobs
    }

    var cacheKey: String {
        [
            "app_user_id=\(self.appUserID)",
            "domain=\(self.domain)",
            "manifest=\(self.manifest ?? "")",
            "prefetched_blobs=\(self.prefetchedBlobs.sorted().joined(separator: ","))"
        ].joined(separator: "|")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.appUserID, forKey: .appUserID)
        try container.encodeIfPresent(self.manifest, forKey: .manifest)
        try container.encode(self.prefetchedBlobs, forKey: .prefetchedBlobs)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.appUserID = try container.decode(String.self, forKey: .appUserID)
        self.domain = RemoteConfiguration.defaultDomain
        self.manifest = try container.decodeIfPresent(String.self, forKey: .manifest)
        self.prefetchedBlobs = try container.decodeIfPresent([String].self, forKey: .prefetchedBlobs) ?? []
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetRemoteConfigOperation: @unchecked Sendable {}

private extension GetRemoteConfigOperation {

    func getRemoteConfig(completion: @escaping () -> Void) {
        let request = HTTPRequest(method: .post(self.request), path: .remoteConfig(domain: self.request.domain))

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<RemoteConfigContainer?>.Result) in
            defer {
                completion()
            }

            self.callbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(
                    response
                        .map(RemoteConfigFetchResult.init(response:))
                        .mapError(BackendError.networkError)
                )
            }
        }
    }

}
