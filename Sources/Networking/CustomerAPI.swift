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

        let factory = GetCustomerInfoOperation.createFactory(configuration: config,
                                                             customerInfoCallbackCache: self.customerInfoCallbackCache)

        let callback = CustomerInfoCallback(cacheKey: factory.cacheKey,
                                            source: factory.operationType,
                                            completion: completion)
        let cacheStatus = self.customerInfoCallbackCache.addOrAppendToPostReceiptDataOperation(callback: callback)
        self.backendConfig.addCacheableOperation(with: factory,
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
              initiationSource: ProductRequestData.InitiationSource,
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
                                                         initiationSource: initiationSource,
                                                         subscriberAttributesByKey: subscriberAttributesByKey)
        let factory = PostReceiptDataOperation.createFactory(configuration: config,
                                                             postData: postData,
                                                             customerInfoCallbackCache: self.customerInfoCallbackCache)

        let callbackObject = CustomerInfoCallback(cacheKey: factory.cacheKey,
                                                  source: PostReceiptDataOperation.self,
                                                  completion: completion)

        let cacheStatus = customerInfoCallbackCache.add(callbackObject)

        self.backendConfig.operationQueue.addCacheableOperation(with: factory, cacheStatus: cacheStatus)
    }

}
