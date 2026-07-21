//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetOfferingsOperation.swift
//
//  Created by Joshua Liebowitz on 11/19/21.

import Foundation

final class GetOfferingsOperation: CacheableNetworkOperation {

    private let offeringsCallbackCache: CallbackCache<OfferingsCallback>
    private let configuration: AppUserConfiguration

    static func createFactory(
        configuration: UserSpecificConfiguration,
        offeringsCallbackCache: CallbackCache<OfferingsCallback>
    ) -> CacheableNetworkOperationFactory<GetOfferingsOperation> {
        return .init({ cacheKey in
                    .init(
                        configuration: configuration,
                        offeringsCallbackCache: offeringsCallbackCache,
                        cacheKey: cacheKey
                    )
            },
            individualizedCacheKeyPart: configuration.appUserID)
    }

    private init(configuration: UserSpecificConfiguration,
                 offeringsCallbackCache: CallbackCache<OfferingsCallback>,
                 cacheKey: String) {
        self.configuration = configuration
        self.offeringsCallbackCache = offeringsCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getOfferings(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetOfferingsOperation: @unchecked Sendable {}

private extension GetOfferingsOperation {

    func getOfferings(completion: @escaping () -> Void) {
        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty else {
            self.offeringsCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let request = HTTPRequest(method: .get, path: .getOfferings(appUserID: appUserID))

        httpClient.perform(request) { (response: VerifiedHTTPResponse<Data>.Result) in
            defer {
                completion()
            }

            var resultsByDecodingMode: [OfferingsResponse.DecodingMode: OfferingsResponseHandlerResult] = [:]

            self.offeringsCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                let decodingMode = callbackObject.decodingMode
                let result: OfferingsResponseHandlerResult
                if let cachedResult = resultsByDecodingMode[decodingMode] {
                    result = cachedResult
                } else {
                    result = Self.decode(response, using: decodingMode)
                    resultsByDecodingMode[decodingMode] = result
                }

                callbackObject.completion(result)
            }
        }
    }

    typealias OfferingsResponseHandlerResult = Result<Offerings.Contents, BackendError>

    static func decode(
        _ response: VerifiedHTTPResponse<Data>.Result,
        using decodingMode: OfferingsResponse.DecodingMode
    ) -> OfferingsResponseHandlerResult {
        let responseDataForCache = try? response.get().body
        let decodedResponse: VerifiedHTTPResponse<OfferingsResponse>.Result = response.parseResponse { data, _ in
            try OfferingsResponse.create(with: data, decodingMode: decodingMode)
        }

        return decodedResponse
            .map {
                Offerings.Contents(response: $0.body,
                                   httpResponseOriginalSource: $0.originalSource,
                                   responseDataForCache: responseDataForCache)
            }
            .mapError(BackendError.networkError)
    }

}
