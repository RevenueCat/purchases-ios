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
    typealias HostedCheckoutStatusResponseHandler = Backend.ResponseHandler<HostedCheckoutStatusResponse>
    typealias CheckoutPaymentStatusResponseHandler = Backend.ResponseHandler<HostedCheckoutPaymentStatusResponse>

    private let webBillingProductsCallbackCache: CallbackCache<WebBillingProductsCallback>
    private let hostedCheckoutCallbackCache: CallbackCache<HostedCheckoutCallback>
    private let hostedCheckoutStatusCallbackCache: CallbackCache<HostedCheckoutStatusCallback>
    private let hostedCheckoutPaymentStatusCallbackCache: CallbackCache<HostedCheckoutPaymentStatusCallback>
    private let backendLanes: BackendLanes

    init(lanes: BackendLanes) {
        self.backendLanes = lanes
        self.webBillingProductsCallbackCache = .init()
        self.hostedCheckoutCallbackCache = .init()
        self.hostedCheckoutStatusCallbackCache = .init()
        self.hostedCheckoutPaymentStatusCallbackCache = .init()
    }

    func getWebBillingProducts(
        appUserID: String, productIds: Set<String>, completion: @escaping WebBillingProductsResponseHandler
    ) {
        let backendConfig = self.backendLanes[.default]
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = GetWebBillingProductsOperation.createFactory(
            configuration: config,
            webBillingProductsCallbackCache: self.webBillingProductsCallbackCache,
            productIds: productIds
        )

        let webProductsCallback = WebBillingProductsCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.webBillingProductsCallbackCache.add(webProductsCallback)

        backendConfig.addCacheableOperation(
            with: factory,
            delay: .none,
            cacheStatus: cacheStatus
        )
    }

    /// Creates a checkout session with the payment provider and returns the page to present for it.
    ///
    /// - Parameter paywall: The paywall the checkout was started from, where it was started from one.
    /// - Parameter externalPurchaseTokenID: Identifies the Apple external purchase token registered for
    /// this purchase. Pass `nil` where no token applies.
    // swiftlint:disable:next function_parameter_count
    func postHostedCheckout(
        appUserID: String,
        packageID: String,
        presentedOfferingContext: PresentedOfferingContext,
        paywall: PostHostedCheckoutOperation.Paywall?,
        externalPurchaseTokenID: String?,
        completion: @escaping HostedCheckoutResponseHandler
    ) {
        // Runs on the checkout lane so hosted checkout is not delayed by unrelated backend work.
        let backendConfig = self.backendLanes[.checkout]
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = PostHostedCheckoutOperation.createFactory(
            configuration: config,
            postData: .init(appUserID: appUserID,
                            packageID: packageID,
                            presentedOfferingIdentifier: presentedOfferingContext.offeringIdentifier,
                            presentedPlacementIdentifier: presentedOfferingContext.placementIdentifier,
                            appliedTargetingRule: presentedOfferingContext.targetingContext.map {
                                .init(revision: $0.revision, ruleID: $0.ruleId)
                            },
                            paywall: paywall,
                            externalPurchaseTokenID: externalPurchaseTokenID),
            hostedCheckoutCallbackCache: self.hostedCheckoutCallbackCache
        )

        let callback = HostedCheckoutCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.hostedCheckoutCallbackCache.add(callback)

        // The customer is waiting on this request before checkout can open, so it is never delayed.
        backendConfig.addCacheableOperation(
            with: factory,
            delay: .none,
            cacheStatus: cacheStatus
        )
    }

    /// Asks what became of a checkout session.
    ///
    /// - Parameter operationSessionID: The session to ask about, as returned by ``postHostedCheckout``.
    /// Answered with a 404 where this customer does not own it.
    func getHostedCheckoutStatus(
        appUserID: String,
        operationSessionID: String,
        completion: @escaping HostedCheckoutStatusResponseHandler
    ) {
        let backendConfig = self.backendLanes[.checkout]
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = GetHostedCheckoutStatusOperation.createFactory(
            configuration: config,
            operationSessionID: operationSessionID,
            callbackCache: self.hostedCheckoutStatusCallbackCache
        )

        let callback = HostedCheckoutStatusCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.hostedCheckoutStatusCallbackCache.add(callback)

        backendConfig.addCacheableOperation(
            with: factory,
            delay: .none,
            cacheStatus: cacheStatus
        )
    }

    /// Asks whether the customer paid for a checkout session, which the backend reads from the payment
    /// provider. Meant for a checkout the customer dismissed, where nothing says whether they paid.
    ///
    /// - Parameter operationSessionID: The session to ask about, as returned by ``postHostedCheckout``.
    /// Answered with a 404 where this customer does not own it.
    func getHostedCheckoutPaymentStatus(
        appUserID: String,
        operationSessionID: String,
        completion: @escaping CheckoutPaymentStatusResponseHandler
    ) {
        let backendConfig = self.backendLanes[.checkout]
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = GetHostedCheckoutPaymentStatusOperation.createFactory(
            configuration: config,
            operationSessionID: operationSessionID,
            callbackCache: self.hostedCheckoutPaymentStatusCallbackCache
        )

        let callback = HostedCheckoutPaymentStatusCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.hostedCheckoutPaymentStatusCallbackCache.add(callback)

        // The customer is waiting on the answer to leave the checkout.
        backendConfig.addCacheableOperation(
            with: factory,
            delay: .none,
            cacheStatus: cacheStatus
        )
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension WebBillingAPI: @unchecked Sendable {}
