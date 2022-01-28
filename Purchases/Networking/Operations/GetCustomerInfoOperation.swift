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

        super.init(configuration: configuration, individualizedCacheKeyPart: configuration.appUserID)
    }

    override func begin() {
        self.getCustomerInfo()
    }

}

private extension GetCustomerInfoOperation {

    func getCustomerInfo() {
        guard let appUserID = try? configuration.appUserID.escapedOrError() else {
            self.customerInfoCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(nil, ErrorUtils.missingAppUserIDError())
            }
            return
        }

        let path = "/subscribers/\(appUserID)"

        httpClient.performGETRequest(serially: true,
                                     path: path,
                                     headers: authHeaders) { statusCode, response, error in
            self.customerInfoCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                self.customerInfoResponseHandler.handle(customerInfoResponse: response,
                                                        statusCode: statusCode,
                                                        maybeError: error,
                                                        completion: callback.completion)
            }
        }
    }

}
