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
typealias BackendCustomerInfoResponseHandler = (CustomerInfo?, Error?) -> Void
typealias IntroEligibilityResponseHandler = ([String: IntroEligibility], Error?) -> Void
typealias OfferingsResponseHandler = ([String: Any]?, Error?) -> Void
typealias OfferSigningResponseHandler = (String?, String?, UUID?, Int?, Error?) -> Void
typealias PostRequestResponseHandler = (Error?) -> Void
typealias LogInResponseHandler = (CustomerInfo?, Bool, Error?) -> Void

class Backend {

    static let RCSuccessfullySyncedKey: NSError.UserInfoKey = "rc_successfullySynced"
    static let RCAttributeErrorsKey = "attribute_errors"
    static let RCAttributeErrorsResponseKey = "attributes_error_response"

    private let apiKey: String
    private let authHeaders: [String: String]
    private let httpClient: HTTPClient
    private let subscribersAPI: SubscribersAPI
    private let operationQueue: OperationQueue

    private let logInCallbacksCache: CallbackCache<LogInCallback>
    private let offeringsCallbacksCache: CallbackCache<OfferingsCallback>
    private let callbackQueue = DispatchQueue(label: "Backend callbackQueue")

    convenience init(apiKey: String,
                     systemInfo: SystemInfo,
                     eTagManager: ETagManager) {
        let httpClient = HTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)
        self.init(httpClient: httpClient, apiKey: apiKey)
    }

    required init(httpClient: HTTPClient, apiKey: String) {
        self.operationQueue = OperationQueue()
        self.operationQueue.name = "Backend Queue"
        self.operationQueue.maxConcurrentOperationCount = 1

        self.httpClient = httpClient
        self.apiKey = apiKey
        self.offeringsCallbacksCache = CallbackCache<OfferingsCallback>(callbackQueue: self.callbackQueue)
        self.logInCallbacksCache = CallbackCache<LogInCallback>(callbackQueue: self.callbackQueue)
        self.authHeaders = ["Authorization": "Bearer \(apiKey)"]

        let aliasCallbackCache = CallbackCache<AliasCallback>(callbackQueue: callbackQueue)
        let customerInfoCallbackCache = CallbackCache<CustomerInfoCallback>(callbackQueue: callbackQueue)
        self.subscribersAPI = SubscribersAPI(httpClient: httpClient,
                                             authHeaders: self.authHeaders,
                                             operationQueue: self.operationQueue,
                                             aliasCallbackCache: aliasCallbackCache,
                                             customerInfoCallbackCache: customerInfoCallbackCache)
    }

    func createAlias(appUserID: String, newAppUserID: String, completion: PostRequestResponseHandler?) {
        self.subscribersAPI.createAlias(appUserID: appUserID, newAppUserID: newAppUserID, completion: completion)
    }

    func clearHTTPClientCaches() {
        self.httpClient.clearCaches()
    }

    func getSubscriberData(appUserID: String, completion: @escaping BackendCustomerInfoResponseHandler) {
        self.subscribersAPI.getSubscriberData(appUserID: appUserID, completion: completion)
    }

    // swiftlint:disable:next function_parameter_count
    func post(receiptData: Data,
              appUserID: String,
              isRestore: Bool,
              productData: ProductRequestData?,
              presentedOfferingIdentifier offeringIdentifier: String?,
              observerMode: Bool,
              subscriberAttributes subscriberAttributesByKey: SubscriberAttributeDict?,
              completion: @escaping BackendCustomerInfoResponseHandler) {
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
              completion: PostRequestResponseHandler?) {
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
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.httpClient,
                                                                authHeaders: self.authHeaders,
                                                                appUserID: appUserID)
        let postOfferForSigningOperation = PostOfferForSigningOperation(configuration: config,
                                                                        offerIdForSigning: offerIdentifier,
                                                                        productIdentifier: productIdentifier,
                                                                        subscriptionGroup: subscriptionGroup,
                                                                        receiptData: receiptData,
                                                                        completion: completion)
        self.operationQueue.addOperation(postOfferForSigningOperation)
    }

    func post(attributionData: [String: Any],
              network: AttributionNetwork,
              appUserID: String,
              completion: PostRequestResponseHandler?) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.httpClient,
                                                                authHeaders: self.authHeaders,
                                                                appUserID: appUserID)
        let postAttributionDataOperation = PostAttributionDataOperation(configuration: config,
                                                                        attributionData: attributionData,
                                                                        network: network,
                                                                        maybeCompletion: completion)
        self.operationQueue.addOperation(postAttributionDataOperation)
    }

    func logIn(currentAppUserID: String,
               newAppUserID: String,
               completion: @escaping LogInResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.httpClient,
                                                                authHeaders: self.authHeaders,
                                                                appUserID: currentAppUserID)
        let loginOperation = LogInOperation(configuration: config,
                                            newAppUserID: newAppUserID,
                                            completion: completion,
                                            loginCallbackCache: self.logInCallbacksCache)
        self.operationQueue.addOperation(loginOperation)
    }

    func getOfferings(appUserID: String, completion: @escaping OfferingsResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.httpClient,
                                                                authHeaders: self.authHeaders,
                                                                appUserID: appUserID)
        let getOfferingsOperation = GetOfferingsOperation(configuration: config,
                                                          completion: completion,
                                                          offeringsCallbackCache: self.offeringsCallbacksCache)
        self.operationQueue.addOperation(getOfferingsOperation)
    }

    func getIntroEligibility(appUserID: String,
                             receiptData: Data,
                             productIdentifiers: [String],
                             completion: @escaping IntroEligibilityResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.httpClient,
                                                                authHeaders: self.authHeaders,
                                                                appUserID: appUserID)
        let getIntroEligibilityOperation = GetIntroEligibilityOperation(configuration: config,
                                                                        receiptData: receiptData,
                                                                        productIdentifiers: productIdentifiers,
                                                                        completion: completion)
        self.operationQueue.addOperation(getIntroEligibilityOperation)
    }

}
