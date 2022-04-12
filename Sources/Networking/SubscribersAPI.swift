//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscribersAPI.swift
//
//  Created by Joshua Liebowitz on 11/17/21.

import Foundation

class SubscribersAPI {

    private let httpClient: HTTPClient
    private let operationQueue: OperationQueue
    private let authHeaders: [String: String]
    private let aliasCallbackCache: CallbackCache<AliasCallback>
    private let customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>
    private let attributionFetcher: AttributionFetcher
    private let dateProvider: DateProvider

    init(httpClient: HTTPClient,
         attributionFetcher: AttributionFetcher,
         authHeaders: [String: String],
         operationQueue: OperationQueue,
         aliasCallbackCache: CallbackCache<AliasCallback>,
         customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>,
         dateProvider: DateProvider) {
        self.httpClient = httpClient
        self.attributionFetcher = attributionFetcher
        self.authHeaders = authHeaders
        self.operationQueue = operationQueue
        self.aliasCallbackCache = aliasCallbackCache
        self.customerInfoCallbackCache = customerInfoCallbackCache
        self.dateProvider = dateProvider
    }

    func createAlias(appUserID: String, newAppUserID: String, completion: Backend.SimpleResponseHandler?) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.httpClient,
                                                                authHeaders: self.authHeaders,
                                                                appUserID: appUserID)
        let operation = CreateAliasOperation(configuration: config,
                                             newAppUserID: newAppUserID,
                                             aliasCallbackCache: self.aliasCallbackCache)

        let aliasCallback = AliasCallback(cacheKey: operation.cacheKey, completion: completion)
        let cacheStatus = self.aliasCallbackCache.add(callback: aliasCallback)
        operationQueue.addCacheableOperation(operation, cacheStatus: cacheStatus)
    }

    func getCustomerInfo(appUserID: String, completion: @escaping Backend.CustomerInfoResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.httpClient,
                                                                authHeaders: self.authHeaders,
                                                                appUserID: appUserID)

        let operation = GetCustomerInfoOperation(configuration: config,
                                                 customerInfoCallbackCache: self.customerInfoCallbackCache)

        let callback = CustomerInfoCallback(operation: operation, completion: completion)
        let cacheStatus = self.customerInfoCallbackCache.add(callback: callback)
        operationQueue.addCacheableOperation(operation, cacheStatus: cacheStatus)
    }

    func post(subscriberAttributes: SubscriberAttributeDict,
              appUserID: String,
              completion: Backend.SimpleResponseHandler?) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.httpClient,
                                                                authHeaders: self.authHeaders,
                                                                appUserID: appUserID)
        let operation = PostSubscriberAttributesOperation(configuration: config,
                                                          subscriberAttributes: subscriberAttributes,
                                                          completion: completion)
        operationQueue.addOperation(operation)
    }

    // swiftlint:disable:next function_parameter_count
    func post(receiptData: Data,
              appUserID: String,
              isRestore: Bool,
              productData: ProductRequestData?,
              presentedOfferingIdentifier offeringIdentifier: String?,
              observerMode: Bool,
              subscriberAttributes subscriberAttributesByKey: SubscriberAttributeDict?,
              completion: @escaping Backend.CustomerInfoResponseHandler) {
        let attributionStatus = self.attributionFetcher.authorizationStatus
        var subscriberAttributesByKey = subscriberAttributesByKey ?? [:]
        let consentStatus = SubscriberAttribute(withKey: ReservedSubscriberAttribute.consentStatus.rawValue,
                                                value: attributionStatus.description,
                                                dateProvider: self.dateProvider)
        subscriberAttributesByKey[ReservedSubscriberAttribute.consentStatus.key] = consentStatus

        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.httpClient,
                                                                authHeaders: self.authHeaders,
                                                                appUserID: appUserID)

        let postData = PostReceiptDataOperation.PostData(appUserID: appUserID,
                                                         receiptData: receiptData,
                                                         isRestore: isRestore,
                                                         productData: productData,
                                                         presentedOfferingIdentifier: offeringIdentifier,
                                                         observerMode: observerMode,
                                                         subscriberAttributesByKey: subscriberAttributesByKey)
        let postReceiptOperation = PostReceiptDataOperation(configuration: config,
                                                            postData: postData,
                                                            customerInfoCallbackCache: self.customerInfoCallbackCache)

        let callbackObject = CustomerInfoCallback(operation: postReceiptOperation, completion: completion)

        let cacheStatus = customerInfoCallbackCache.add(callback: callbackObject)

        operationQueue.addCacheableOperation(postReceiptOperation, cacheStatus: cacheStatus)
    }

}
