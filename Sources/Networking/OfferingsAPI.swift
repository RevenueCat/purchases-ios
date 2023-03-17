//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingsAPI.swift
//
//  Created by Joshua Liebowitz on 6/15/22.

import Foundation

class OfferingsAPI {

    typealias ResponseHandler<Response> = (Result<Response, BackendError>) -> Void

    typealias IntroEligibilityResponseHandler = ([String: IntroEligibility], BackendError?) -> Void
    typealias OfferSigningResponseHandler = ResponseHandler<PostOfferForSigningOperation.SigningData>
    typealias OfferingsResponseHandler = ResponseHandler<OfferingsResponse>
    typealias ProductEntitlementMappingResponseHandler = ResponseHandler<ProductEntitlementMappingResponse>

    private let offeringsCallbacksCache: CallbackCache<OfferingsCallback>
    private let productEntitlementMappingCallbacksCache: CallbackCache<ProductEntitlementMappingCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.offeringsCallbacksCache = .init()
        self.productEntitlementMappingCallbacksCache = .init()
    }

    func getOfferings(appUserID: String,
                      withRandomDelay randomDelay: Bool,
                      completion: @escaping OfferingsResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = GetOfferingsOperation.createFactory(
            configuration: config,
            offeringsCallbackCache: self.offeringsCallbacksCache
        )

        let offeringsCallback = OfferingsCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.offeringsCallbacksCache.add(offeringsCallback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            withRandomDelay: randomDelay,
            cacheStatus: cacheStatus
        )
    }

    func getIntroEligibility(appUserID: String,
                             receiptData: Data,
                             productIdentifiers: [String],
                             completion: @escaping IntroEligibilityResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let getIntroEligibilityOperation = GetIntroEligibilityOperation(configuration: config,
                                                                        receiptData: receiptData,
                                                                        productIdentifiers: productIdentifiers,
                                                                        responseHandler: completion)
        self.backendConfig.operationQueue.addOperation(getIntroEligibilityOperation)
    }

    // swiftlint:disable:next function_parameter_count
    func post(offerIdForSigning offerIdentifier: String,
              productIdentifier: String,
              subscriptionGroup: String,
              receiptData: Data,
              appUserID: String,
              completion: @escaping OfferSigningResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)

        let postOfferData = PostOfferForSigningOperation.PostOfferForSigningData(offerIdentifier: offerIdentifier,
                                                                                 productIdentifier: productIdentifier,
                                                                                 subscriptionGroup: subscriptionGroup,
                                                                                 receiptData: receiptData)
        let postOfferForSigningOperation = PostOfferForSigningOperation(configuration: config,
                                                                        postOfferForSigningData: postOfferData,
                                                                        responseHandler: completion)
        self.backendConfig.operationQueue.addOperation(postOfferForSigningOperation)
    }

    func getProductEntitlementMapping(withRandomDelay randomDelay: Bool,
                                      completion: @escaping ProductEntitlementMappingResponseHandler) {
        let factory = GetProductEntitlementMappingOperation.createFactory(
            configuration: self.backendConfig,
            callbackCache: self.productEntitlementMappingCallbacksCache
        )

        let callback = ProductEntitlementMappingCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.productEntitlementMappingCallbacksCache.add(callback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            withRandomDelay: randomDelay,
            cacheStatus: cacheStatus
        )
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension OfferingsAPI: @unchecked Sendable {}
