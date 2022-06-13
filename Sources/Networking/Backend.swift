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
    typealias LogInResponseHandler = (Result<(info: CustomerInfo, created: Bool), BackendError>) -> Void

    private let config: BackendConfiguration
    private let subscribersAPI: SubscribersAPI
    private let logInCallbacksCache: CallbackCache<LogInCallback>
    private let offeringsCallbacksCache: CallbackCache<OfferingsCallback>

    convenience init(apiKey: String,
                     systemInfo: SystemInfo,
                     httpClientTimeout: TimeInterval = Configuration.networkTimeoutDefault,
                     eTagManager: ETagManager,
                     attributionFetcher: AttributionFetcher,
                     dateProvider: DateProvider = DateProvider()) {
        let httpClient = HTTPClient(systemInfo: systemInfo,
                                    eTagManager: eTagManager,
                                    requestTimeout: httpClientTimeout)
        let config = BackendConfiguration(apiKey: apiKey,
                                          authHeaders: HTTPClient.authorizationHeader(withAPIKey: apiKey),
                                          httpClient: httpClient,
                                          operationQueue: QueueProvider.queue,
                                          dateProvider: dateProvider)
        self.init(backendConfig: config, attributionFetcher: attributionFetcher)
    }

    required init(backendConfig: BackendConfiguration,
                  attributionFetcher: AttributionFetcher) {
        self.config = backendConfig
        self.offeringsCallbacksCache = CallbackCache<OfferingsCallback>(callbackQueue: self.config.callbackQueue)
        self.logInCallbacksCache = CallbackCache<LogInCallback>(callbackQueue: self.config.callbackQueue)

        let customerInfoCallbackCache = CallbackCache<CustomerInfoCallback>(callbackQueue: self.config.callbackQueue)
        self.subscribersAPI = SubscribersAPI(backendConfig: self.config,
                                             attributionFetcher: attributionFetcher,
                                             customerInfoCallbackCache: customerInfoCallbackCache)
    }

    func clearHTTPClientCaches() {
        self.config.clearCache()
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

    // swiftlint:disable:next function_parameter_count
    func post(offerIdForSigning offerIdentifier: String,
              productIdentifier: String,
              subscriptionGroup: String,
              receiptData: Data,
              appUserID: String,
              completion: @escaping OfferSigningResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.config.httpClient,
                                                                authHeaders: self.config.authHeaders,
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
                                                                authHeaders: self.config.authHeaders,
                                                                appUserID: appUserID)
        let postAttributionDataOperation = PostAttributionDataOperation(configuration: config,
                                                                        attributionData: attributionData,
                                                                        network: network,
                                                                        responseHandler: completion)
        self.config.operationQueue.addOperation(postAttributionDataOperation)
    }

    func logIn(currentAppUserID: String,
               newAppUserID: String,
               completion: @escaping LogInResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.config.httpClient,
                                                                authHeaders: self.config.authHeaders,
                                                                appUserID: currentAppUserID)
        let loginOperation = LogInOperation(configuration: config,
                                            newAppUserID: newAppUserID,
                                            loginCallbackCache: self.logInCallbacksCache)

        let loginCallback = LogInCallback(cacheKey: loginOperation.cacheKey, completion: completion)
        let cacheStatus = self.logInCallbacksCache.add(callback: loginCallback)

        self.config.operationQueue.addCacheableOperation(loginOperation, cacheStatus: cacheStatus)
    }

    func getOfferings(appUserID: String, completion: @escaping OfferingsResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.config.httpClient,
                                                                authHeaders: self.config.authHeaders,
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
                                                                authHeaders: self.config.authHeaders,
                                                                appUserID: appUserID)
        let getIntroEligibilityOperation = GetIntroEligibilityOperation(configuration: config,
                                                                        receiptData: receiptData,
                                                                        productIdentifiers: productIdentifiers,
                                                                        responseHandler: completion)
        self.config.operationQueue.addOperation(getIntroEligibilityOperation)
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
