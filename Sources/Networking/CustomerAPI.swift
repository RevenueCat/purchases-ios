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

    typealias CustomerInfoResponseHandler = Backend.ResponseHandler<CustomerInfo>
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
                         isAppBackgrounded: Bool,
                         allowComputingOffline: Bool,
                         completion: @escaping CustomerInfoResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)

        let factory = GetCustomerInfoOperation.createFactory(
            configuration: config,
            customerInfoCallbackCache: self.customerInfoCallbackCache,
            offlineCreator: allowComputingOffline
                ? self.backendConfig.offlineCustomerInfoCreator
                : nil
        )

        let callback = CustomerInfoCallback(cacheKey: factory.cacheKey,
                                            source: factory.operationType,
                                            completion: completion)
        let cacheStatus = self.customerInfoCallbackCache.addOrAppendToPostReceiptDataOperation(callback: callback)
        self.backendConfig.addCacheableOperation(with: factory,
                                                 delay: .default(forBackgroundedApp: isAppBackgrounded),
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

    // swiftlint:disable function_parameter_count
    func post(receipt: EncodedAppleReceipt,
              productData: ProductRequestData?,
              transactionData: PurchasedTransactionData,
              observerMode: Bool,
              appTransaction: String?,
              completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        var subscriberAttributesToPost: SubscriberAttribute.Dictionary?

        if !self.backendConfig.systemInfo.dangerousSettings.customEntitlementComputation {
            subscriberAttributesToPost = transactionData.unsyncedAttributes ?? [:]
            let attributionStatus = self.attributionFetcher.authorizationStatus
            let consentStatus = SubscriberAttribute(attribute: ReservedSubscriberAttribute.consentStatus,
                                                    value: attributionStatus.description,
                                                    dateProvider: self.backendConfig.dateProvider)
            subscriberAttributesToPost?[consentStatus.key] = consentStatus
        }

        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: transactionData.appUserID)

        let postData = PostReceiptDataOperation.PostData(
            transactionData: transactionData.withAttributesToPost(subscriberAttributesToPost),
            productData: productData,
            receipt: receipt,
            observerMode: observerMode,
            testReceiptIdentifier: self.backendConfig.systemInfo.testReceiptIdentifier,
            appTransaction: appTransaction
        )
        let factory = PostReceiptDataOperation.createFactory(
            configuration: config,
            postData: postData,
            customerInfoCallbackCache: self.customerInfoCallbackCache,
            offlineCustomerInfoCreator: self.backendConfig.offlineCustomerInfoCreator
        )

        let callbackObject = CustomerInfoCallback(cacheKey: factory.cacheKey,
                                                  source: PostReceiptDataOperation.self,
                                                  completion: completion)

        let cacheStatus = customerInfoCallbackCache.add(callbackObject)

        self.backendConfig.operationQueue.addCacheableOperation(with: factory, cacheStatus: cacheStatus)
    }

}

private extension PurchasedTransactionData {

    func withAttributesToPost(_ newAttributes: SubscriberAttribute.Dictionary?) -> Self {
        var copy = self
        copy.unsyncedAttributes = newAttributes

        return copy
    }

}

// MARK: -

private extension SystemInfo {

    /// This allows the backend to disambiguate between receipts created across
    /// separate test invocations when in the sandbox.
    var testReceiptIdentifier: String? {
        #if DEBUG
        return self.dangerousSettings.internalSettings.testReceiptIdentifier
        #else
        return nil
        #endif
    }

}
