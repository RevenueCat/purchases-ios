//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBillingAPI.swift
//
//  Created by Antonio Pallares on 7/29/25.

import Foundation

class WebBillingAPI {

    typealias WebBillingProductsResponseHandler = Backend.ResponseHandler<WebBillingProductsResponse>
    typealias HostedCheckoutResponseHandler = Backend.ResponseHandler<HostedCheckoutResponse>

    private let webBillingProductsCallbackCache: CallbackCache<WebBillingProductsCallback>
    private let hostedCheckoutCallbackCache: CallbackCache<HostedCheckoutCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.webBillingProductsCallbackCache = .init()
        self.hostedCheckoutCallbackCache = .init()
    }

    func getWebBillingProducts(
        appUserID: String, productIds: Set<String>, completion: @escaping WebBillingProductsResponseHandler
    ) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = GetWebBillingProductsOperation.createFactory(
            configuration: config,
            webBillingProductsCallbackCache: self.webBillingProductsCallbackCache,
            productIds: productIds
        )

        let webProductsCallback = WebBillingProductsCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.webBillingProductsCallbackCache.add(webProductsCallback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .none,
            cacheStatus: cacheStatus
        )
    }

    /// Creates a checkout session with the payment provider and returns the page to present for it.
    func postHostedCheckout(
        appUserID: String,
        packageID: String,
        presentedOfferingIdentifier: String,
        completion: @escaping HostedCheckoutResponseHandler
    ) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = PostHostedCheckoutOperation.createFactory(
            configuration: config,
            postData: .init(appUserID: appUserID,
                            packageID: packageID,
                            presentedOfferingIdentifier: presentedOfferingIdentifier),
            hostedCheckoutCallbackCache: self.hostedCheckoutCallbackCache
        )

        let callback = HostedCheckoutCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.hostedCheckoutCallbackCache.add(callback)

        // The customer is waiting on this request before checkout can open, so it is never delayed.
        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .none,
            cacheStatus: cacheStatus
        )
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension WebBillingAPI: @unchecked Sendable {}
