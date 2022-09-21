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

final class CustomerAPI {

    typealias CustomerInfoResponseHandler = (Result<CustomerInfo, BackendError>) -> Void
    typealias SimpleResponseHandler = (BackendError?) -> Void

    private let backendConfig: BackendConfiguration
    private let customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>
    private let attributionFetcher: AttributionFetcher

    init(backendConfig: BackendConfiguration, attributionFetcher: AttributionFetcher) {
        self.backendConfig = backendConfig
        self.attributionFetcher = attributionFetcher
        self.customerInfoCallbackCache = CallbackCache<CustomerInfoCallback>()
    }

    func getCustomerInfo(appUserID: String,
                         withRandomDelay randomDelay: Bool,
                         completion: @escaping CustomerInfoResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)

        let operation = GetCustomerInfoOperation(configuration: config,
                                                 customerInfoCallbackCache: self.customerInfoCallbackCache)

        let callback = CustomerInfoCallback(operation: operation, completion: completion)
        let cacheStatus = self.customerInfoCallbackCache.addOrAppendToPostReceiptDataOperation(callback: callback)
        self.backendConfig.addCacheableOperation(operation,
                                                 withRandomDelay: randomDelay,
                                                 cacheStatus: cacheStatus)
    }

    func post(subscriberAttributes: SubscriberAttribute.Dictionary,
              appUserID: String,
              completion: SimpleResponseHandler?) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let operation = PostSubscriberAttributesOperation(configuration: config,
                                                          subscriberAttributes: subscriberAttributes,
                                                          completion: completion)
        self.backendConfig.operationQueue.addOperation(operation)
    }

    func post(attributionData: [String: Any],
              network: AttributionNetwork,
              appUserID: String,
              completion: SimpleResponseHandler?) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let postAttributionDataOperation = PostAttributionDataOperation(configuration: config,
                                                                        attributionData: attributionData,
                                                                        network: network,
                                                                        responseHandler: completion)
        self.backendConfig.operationQueue.addOperation(postAttributionDataOperation)
    }

    func post(adServicesToken: String,
              appUserID: String,
              completion: SimpleResponseHandler?) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let postAttributionDataOperation = PostAdServicesTokenOperation(configuration: config,
                                                                        token: adServicesToken,
                                                                        responseHandler: completion)
        self.backendConfig.operationQueue.addOperation(postAttributionDataOperation)
    }

    // swiftlint:disable:next function_parameter_count
    func post(receiptData: Data,
              appUserID: String,
              isRestore: Bool,
              productData: ProductRequestData?,
              presentedOfferingIdentifier offeringIdentifier: String?,
              observerMode: Bool,
              subscriberAttributes subscriberAttributesByKey: SubscriberAttribute.Dictionary?,
              completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        let attributionStatus = self.attributionFetcher.authorizationStatus
        var subscriberAttributesByKey = subscriberAttributesByKey ?? [:]
        let consentStatus = SubscriberAttribute(withKey: ReservedSubscriberAttribute.consentStatus.rawValue,
                                                value: attributionStatus.description,
                                                dateProvider: self.backendConfig.dateProvider)
        subscriberAttributesByKey[ReservedSubscriberAttribute.consentStatus.key] = consentStatus

        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
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

        self.backendConfig.operationQueue.addCacheableOperation(postReceiptOperation, cacheStatus: cacheStatus)
    }

}

extension CustomerAPI: Sendable {}
