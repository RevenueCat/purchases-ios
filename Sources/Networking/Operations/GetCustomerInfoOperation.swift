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

class GetCustomerInfoOperation: CacheableNetworkOperation {

    private let customerInfoResponseHandler: CustomerInfoResponseHandler
    private let customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>
    private let configuration: UserSpecificConfiguration

    init(configuration: UserSpecificConfiguration,
         customerInfoResponseHandler: CustomerInfoResponseHandler = CustomerInfoResponseHandler(),
         customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>) {
        self.configuration = configuration
        self.customerInfoResponseHandler = customerInfoResponseHandler
        self.customerInfoCallbackCache = customerInfoCallbackCache

        var individualizedCacheKeyPart = configuration.appUserID

        // If there is any enqueued `PostReceiptDataOperation` we don't want this new
        // `GetCustomerInfoOperation` to share the same cache key.
        // If it did, future `GetCustomerInfoOperation` would receive a cached value
        // instead of an up-to-date `CustomerInfo` after those post receipt operations finish.
        if customerInfoCallbackCache.hasPostReceiptOperations {
            individualizedCacheKeyPart += "-\(customerInfoCallbackCache.numberOfGetCustomerInfoOperations)"
        }

        super.init(configuration: configuration,
                   individualizedCacheKeyPart: individualizedCacheKeyPart)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getCustomerInfo(completion: completion)
    }

}

private extension GetCustomerInfoOperation {

    func getCustomerInfo(completion: @escaping () -> Void) {
        guard let appUserID = try? configuration.appUserID.escapedOrError() else {
            self.customerInfoCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let request = HTTPRequest(method: .get,
                                  path: .getCustomerInfo(appUserID: appUserID))

        httpClient.perform(request) { (response: HTTPResponse<CustomerInfoResponseHandler.Response>.Result) in
            self.customerInfoCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                self.customerInfoResponseHandler.handle(customerInfoResponse: response,
                                                        completion: callback.completion)
            }

            completion()
        }
    }

}

private extension CallbackCache where T == CustomerInfoCallback {

    var numberOfGetCustomerInfoOperations: Int {
        return self.callbacks(ofType: GetCustomerInfoOperation.self)
    }

    var hasPostReceiptOperations: Bool {
        return self.callbacks(ofType: PostReceiptDataOperation.self) > 0
    }

    private func callbacks(ofType type: NetworkOperation.Type) -> Int {
        return self
            .cachedCallbacksByKey
            .value
            .lazy
            .flatMap(\.value)
            .filter { $0.source == type }
            .count
    }

}
