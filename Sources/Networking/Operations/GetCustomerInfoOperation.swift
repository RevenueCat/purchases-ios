//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetCustomerInfoOperation.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

final class GetCustomerInfoOperation: CacheableNetworkOperation {

    private let customerInfoResponseHandler: CustomerInfoResponseHandler
    private let customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>
    private let configuration: UserSpecificConfiguration

    static func createFactory(
        configuration: UserSpecificConfiguration,
        customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>,
        offlineCreator: OfflineCustomerInfoCreator?
    ) -> CacheableNetworkOperationFactory<GetCustomerInfoOperation> {
        return Self.createFactory(
            configuration: configuration,
            customerInfoResponseHandler: .init(
                offlineCreator: offlineCreator,
                userID: configuration.appUserID,
                failIfInvalidSubscriptionKeyDetectedInDebug: false
            ),
            customerInfoCallbackCache: customerInfoCallbackCache)
    }

    static func createFactory(
        configuration: UserSpecificConfiguration,
        customerInfoResponseHandler: CustomerInfoResponseHandler,
        customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>
    ) -> CacheableNetworkOperationFactory<GetCustomerInfoOperation> {
        return .init({
            .init(configuration: configuration,
                  customerInfoResponseHandler: customerInfoResponseHandler,
                  customerInfoCallbackCache: customerInfoCallbackCache,
                  cacheKey: $0) },
            individualizedCacheKeyPart: configuration.appUserID
        )
    }

    private init(
        configuration: UserSpecificConfiguration,
        customerInfoResponseHandler: CustomerInfoResponseHandler,
        customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.customerInfoResponseHandler = customerInfoResponseHandler
        self.customerInfoCallbackCache = customerInfoCallbackCache

        super.init(configuration: configuration,
                   cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getCustomerInfo(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetCustomerInfoOperation: @unchecked Sendable {}

private extension GetCustomerInfoOperation {

    func getCustomerInfo(completion: @escaping () -> Void) {
        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty else {
            self.customerInfoCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let request = HTTPRequest(method: .get,
                                  path: .getCustomerInfo(appUserID: appUserID))

        self.httpClient.perform(
            request
        ) { (response: VerifiedHTTPResponse<CustomerInfoResponseHandler.Response>.Result) in
            self.customerInfoResponseHandler.handle(customerInfoResponse: response) { result in
                self.customerInfoCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                    callback.completion(result)
                }
            }

            completion()
        }
    }

}
