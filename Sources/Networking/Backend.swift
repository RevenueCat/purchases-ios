//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Backend.swift
//
//  Created by Joshua Liebowitz on 8/2/21.

import Foundation

typealias SubscriberAttributeDict = [String: SubscriberAttribute]

class Backend {

    typealias CustomerInfoResponseHandler = (Result<CustomerInfo, BackendError>) -> Void
    typealias IntroEligibilityResponseHandler = ([String: IntroEligibility], BackendError?) -> Void
    typealias OfferingsResponseHandler = (Result<OfferingsResponse, BackendError>) -> Void
    typealias OfferSigningResponseHandler = (Result<PostOfferForSigningOperation.SigningData, BackendError>) -> Void
    typealias SimpleResponseHandler = (BackendError?) -> Void

    private let config: BackendConfiguration
    private let identityAPI: IdentityAPI
    private let subscribersAPI: SubscribersAPI
    private let offeringsCallbacksCache: CallbackCache<OfferingsCallback>

    convenience init(apiKey: String,
                     systemInfo: SystemInfo,
                     httpClientTimeout: TimeInterval = Configuration.networkTimeoutDefault,
                     eTagManager: ETagManager,
                     attributionFetcher: AttributionFetcher,
                     dateProvider: DateProvider = DateProvider()) {
        let httpClient = HTTPClient(apiKey: apiKey,
                                    systemInfo: systemInfo,
                                    eTagManager: eTagManager,
                                    requestTimeout: httpClientTimeout)
        let config = BackendConfiguration(httpClient: httpClient,
                                          operationQueue: QueueProvider.queue,
                                          dateProvider: dateProvider)
        self.init(backendConfig: config, attributionFetcher: attributionFetcher)
    }

    required init(backendConfig: BackendConfiguration,
                  attributionFetcher: AttributionFetcher) {
        self.config = backendConfig
        self.offeringsCallbacksCache = CallbackCache<OfferingsCallback>(callbackQueue: self.config.callbackQueue)
        let customerInfoCallbackCache = CallbackCache<CustomerInfoCallback>(callbackQueue: self.config.callbackQueue)
        self.subscribersAPI = SubscribersAPI(backendConfig: self.config,
                                             attributionFetcher: attributionFetcher,
                                             customerInfoCallbackCache: customerInfoCallbackCache)
        self.identityAPI = IdentityAPI(backendConfig: self.config)
    }

    func clearHTTPClientCaches() {
        self.config.clearCache()
    }

    // swiftlint:disable:next function_parameter_count
    func post(offerIdForSigning offerIdentifier: String,
              productIdentifier: String,
              subscriptionGroup: String,
              receiptData: Data,
              appUserID: String,
              completion: @escaping OfferSigningResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.config.httpClient,
                                                                appUserID: appUserID)

        let postOfferData = PostOfferForSigningOperation.PostOfferForSigningData(offerIdentifier: offerIdentifier,
                                                                                 productIdentifier: productIdentifier,
                                                                                 subscriptionGroup: subscriptionGroup,
                                                                                 receiptData: receiptData)
        let postOfferForSigningOperation = PostOfferForSigningOperation(configuration: config,
                                                                        postOfferForSigningData: postOfferData,
                                                                        responseHandler: completion)
        self.config.operationQueue.addOperation(postOfferForSigningOperation)
    }

    func post(attributionData: [String: Any],
              network: AttributionNetwork,
              appUserID: String,
              completion: SimpleResponseHandler?) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.config.httpClient,
                                                                appUserID: appUserID)
        let postAttributionDataOperation = PostAttributionDataOperation(configuration: config,
                                                                        attributionData: attributionData,
                                                                        network: network,
                                                                        responseHandler: completion)
        self.config.operationQueue.addOperation(postAttributionDataOperation)
    }

    func getOfferings(appUserID: String, completion: @escaping OfferingsResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.config.httpClient,
                                                                appUserID: appUserID)
        let getOfferingsOperation = GetOfferingsOperation(configuration: config,
                                                          offeringsCallbackCache: self.offeringsCallbacksCache)

        let offeringsCallback = OfferingsCallback(cacheKey: getOfferingsOperation.cacheKey, completion: completion)
        let cacheStatus = self.offeringsCallbacksCache.add(callback: offeringsCallback)

        self.config.operationQueue.addCacheableOperation(getOfferingsOperation, cacheStatus: cacheStatus)
    }

    func getIntroEligibility(appUserID: String,
                             receiptData: Data,
                             productIdentifiers: [String],
                             completion: @escaping IntroEligibilityResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.config.httpClient,
                                                                appUserID: appUserID)
        let getIntroEligibilityOperation = GetIntroEligibilityOperation(configuration: config,
                                                                        receiptData: receiptData,
                                                                        productIdentifiers: productIdentifiers,
                                                                        responseHandler: completion)
        self.config.operationQueue.addOperation(getIntroEligibilityOperation)
    }

    // - MARK: Proxied methods awaiting cleanup.

    func logIn(currentAppUserID: String,
               newAppUserID: String,
               completion: @escaping IdentityAPI.LogInResponseHandler) {
        self.identityAPI.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID, completion: completion)
    }

    func getCustomerInfo(appUserID: String, completion: @escaping CustomerInfoResponseHandler) {
        self.subscribersAPI.getCustomerInfo(appUserID: appUserID, completion: completion)
    }

    // swiftlint:disable:next function_parameter_count
    func post(receiptData: Data,
              appUserID: String,
              isRestore: Bool,
              productData: ProductRequestData?,
              presentedOfferingIdentifier offeringIdentifier: String?,
              observerMode: Bool,
              subscriberAttributes subscriberAttributesByKey: SubscriberAttributeDict?,
              completion: @escaping CustomerInfoResponseHandler) {
        self.subscribersAPI.post(receiptData: receiptData,
                                 appUserID: appUserID,
                                 isRestore: isRestore,
                                 productData: productData,
                                 presentedOfferingIdentifier: offeringIdentifier,
                                 observerMode: observerMode,
                                 subscriberAttributes: subscriberAttributesByKey,
                                 completion: completion)
    }

    func post(subscriberAttributes: SubscriberAttributeDict,
              appUserID: String,
              completion: SimpleResponseHandler?) {
        self.subscribersAPI.post(subscriberAttributes: subscriberAttributes,
                                 appUserID: appUserID,
                                 completion: completion)
    }

}

extension Backend {

    enum QueueProvider {

        static var queue: OperationQueue {
            let operationQueue = OperationQueue()
            operationQueue.name = "Backend Queue"
            operationQueue.maxConcurrentOperationCount = 1
            return operationQueue
        }

    }

}

// Testing extension
extension Backend {

    var networkTimeout: TimeInterval {
        return self.config.httpClient.timeout
    }

}
