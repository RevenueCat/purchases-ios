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

        httpClient.perform(request) { (response: VerifiedHTTPResponse<OfferingsResponse>.Result) in
            defer {
                completion()
            }

            self.offeringsCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                callbackObject.completion(response
                    .map { $0.body }
                    .mapError(BackendError.networkError)
                )
            }
        }
    }

}
