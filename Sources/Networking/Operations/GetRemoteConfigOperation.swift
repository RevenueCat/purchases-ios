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
    let responseFormat: RemoteConfigResponseFormat

    private enum CodingKeys: String, CodingKey {
        case appUserID = "appUserId"
        case manifest
        case prefetchedBlobs
    }

    init(
        appUserID: String,
        domain: String = RemoteConfiguration.defaultDomain,
        manifest: String? = nil,
        prefetchedBlobs: [String] = [],
        responseFormat: RemoteConfigResponseFormat = .rcContainer
    ) {
        self.appUserID = appUserID
        self.domain = domain
        self.manifest = manifest
        self.prefetchedBlobs = prefetchedBlobs
        self.responseFormat = responseFormat
    }

    var cacheKey: String {
        [
            "app_user_id=\(self.appUserID)",
            "domain=\(self.domain)",
            "response_format=\(self.responseFormat.rawValue)",
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
        self.responseFormat = .rcContainer
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetRemoteConfigOperation: @unchecked Sendable {}

private extension GetRemoteConfigOperation {

    func getRemoteConfig(completion: @escaping () -> Void) {
        let request = HTTPRequest(
            method: .post(self.request),
            path: .remoteConfig(domain: self.request.domain, responseFormat: self.request.responseFormat)
        )

        switch self.request.responseFormat {
        case .rcContainer:
            self.perform(request, completion: completion) { (response: VerifiedHTTPResponse<RemoteConfigContainer?>) in
                try RemoteConfigFetchResult(containerResponse: response)
            }
        case .json:
            self.perform(request, completion: completion) { (response: VerifiedHTTPResponse<RemoteConfiguration?>) in
                RemoteConfigFetchResult(configurationResponse: response)
            }
        }
    }

    func perform<ResponseBody: HTTPResponseBody>(
        _ request: HTTPRequest,
        completion: @escaping () -> Void,
        mapResponse: @escaping (VerifiedHTTPResponse<ResponseBody>) throws -> RemoteConfigFetchResult
    ) {
        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<ResponseBody>.Result) in
            defer {
                completion()
            }

            self.callbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(
                    response
                        .flatMap { response in
                            Result { try mapResponse(response) }.mapError { NetworkError.decoding($0, Data()) }
                        }
                        .mapError(BackendError.networkError)
                )
            }
        }
    }

}
