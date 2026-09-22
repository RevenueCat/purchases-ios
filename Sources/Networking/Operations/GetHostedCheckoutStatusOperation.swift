//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetHostedCheckoutStatusOperation.swift
//
//  Created by Antonio Pallares on 22/9/26.

import Foundation

final class GetHostedCheckoutStatusOperation: CacheableNetworkOperation {

    private let configuration: AppUserConfiguration
    private let operationSessionID: String
    private let callbackCache: CallbackCache<HostedCheckoutStatusCallback>

    static func createFactory(
        configuration: UserSpecificConfiguration,
        operationSessionID: String,
        callbackCache: CallbackCache<HostedCheckoutStatusCallback>
    ) -> CacheableNetworkOperationFactory<GetHostedCheckoutStatusOperation> {
        return .init({ cacheKey in
                    .init(
                        configuration: configuration,
                        operationSessionID: operationSessionID,
                        callbackCache: callbackCache,
                        cacheKey: cacheKey
                    )
            },
            individualizedCacheKeyPart: configuration.appUserID + "\n" + operationSessionID)
    }

    private init(configuration: UserSpecificConfiguration,
                 operationSessionID: String,
                 callbackCache: CallbackCache<HostedCheckoutStatusCallback>,
                 cacheKey: String) {
        self.configuration = configuration
        self.operationSessionID = operationSessionID
        self.callbackCache = callbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getStatus(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetHostedCheckoutStatusOperation: @unchecked Sendable {}

private extension GetHostedCheckoutStatusOperation {

    func getStatus(completion: @escaping () -> Void) {
        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty else {
            self.callbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let request = HTTPRequest(method: .get,
                                  path: .getHostedCheckoutStatus(operationSessionID: self.operationSessionID,
                                                                 appUserID: appUserID))

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<HostedCheckoutStatusResponse>.Result) in
            defer {
                completion()
            }

            self.callbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                callbackObject.completion(response
                    .map { $0.body }
                    .mapError(BackendError.networkError)
                )
            }
        }
    }

}
