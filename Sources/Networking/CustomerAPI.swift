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

    // swiftlint:disable:next type_name
    typealias IsPurchaseAllowedByRestoreBehaviorResponseHandler =
    Backend.ResponseHandler<IsPurchaseAllowedByRestoreBehaviorResponse>

    private let backendLanes: BackendLanes
    private let customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>
    private let isPurchaseAllowedByRestoreBehaviorCallbacksCache:
    CallbackCache<IsPurchaseAllowedByRestoreBehaviorCallback>
    private let attributionFetcher: AttributionFetcher

    init(backendLanes: BackendLanes, attributionFetcher: AttributionFetcher) {
        self.backendLanes = backendLanes
        self.attributionFetcher = attributionFetcher
        self.customerInfoCallbackCache = CallbackCache<CustomerInfoCallback>()
        self.isPurchaseAllowedByRestoreBehaviorCallbacksCache =
        CallbackCache<IsPurchaseAllowedByRestoreBehaviorCallback>()
    }

    func getCustomerInfo(appUserID: String,
                         isAppBackgrounded: Bool,
                         allowComputingOffline: Bool,
                         completion: @escaping CustomerInfoResponseHandler) {
        let backendConfig = self.backendLanes[HTTPRequest.Path.getCustomerInfo(appUserID: appUserID)]
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: backendConfig.httpClient,
                                                                appUserID: appUserID)

        let factory = GetCustomerInfoOperation.createFactory(
            configuration: config,
            customerInfoCallbackCache: self.customerInfoCallbackCache,
            offlineCreator: allowComputingOffline
                ? backendConfig.offlineCustomerInfoCreator
                : nil
        )

        let callback = CustomerInfoCallback(cacheKey: factory.cacheKey,
                                            appUserID: appUserID,
                                            source: factory.operationType,
                                            completion: completion)
        let cacheStatus = self.customerInfoCallbackCache.addOrAppendToPostReceiptDataOperation(callback: callback)
        backendConfig.addCacheableOperation(with: factory,
                                            delay: .default(forBackgroundedApp: isAppBackgrounded),
                                            cacheStatus: cacheStatus)
    }

    func post(subscriberAttributes: SubscriberAttribute.Dictionary,
              appUserID: String,
              completion: SimpleResponseHandler?) {
        let backendConfig = self.backendLanes[HTTPRequest.Path.postSubscriberAttributes(appUserID: appUserID)]
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: backendConfig.httpClient,
                                                                appUserID: appUserID)
        let operation = PostSubscriberAttributesOperation(configuration: config,
                                                          subscriberAttributes: subscriberAttributes,
                                                          completion: completion)
        backendConfig.operationQueue.addOperation(operation)
    }

    func post(attributionData: [String: Any],
              network: AttributionNetwork,
              appUserID: String,
              completion: SimpleResponseHandler?) {
        let backendConfig = self.backendLanes[HTTPRequest.Path.postAttributionData(appUserID: appUserID)]
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: backendConfig.httpClient,
                                                                appUserID: appUserID)
        let postAttributionDataOperation = PostAttributionDataOperation(configuration: config,
                                                                        attributionData: attributionData,
                                                                        network: network,
                                                                        responseHandler: completion)
        backendConfig.operationQueue.addOperation(postAttributionDataOperation)
    }

    func post(adServicesToken: String,
              appUserID: String,
              completion: SimpleResponseHandler?) {
        let backendConfig = self.backendLanes[HTTPRequest.Path.postAdServicesToken(appUserID: appUserID)]
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: backendConfig.httpClient,
                                                                appUserID: appUserID)
        let postAttributionDataOperation = PostAdServicesTokenOperation(configuration: config,
                                                                        token: adServicesToken,
                                                                        responseHandler: completion)
        backendConfig.operationQueue.addOperation(postAttributionDataOperation)
    }

    func isPurchaseAllowedByRestoreBehavior(
        appUserID: String,
        transactionJWS: String,
        isAppBackgrounded: Bool,
        completion: @escaping IsPurchaseAllowedByRestoreBehaviorResponseHandler
    ) {
        let backendConfig = self.backendLanes[
            HTTPRequest.Path.isPurchaseAllowedByRestoreBehavior(appUserID: appUserID)
        ]
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: backendConfig.httpClient,
                                                                appUserID: appUserID)
        let postData = PostIsPurchaseAllowedByRestoreBehaviorOperation.PostData(
            transactionJWS: transactionJWS
        )
        let factory = PostIsPurchaseAllowedByRestoreBehaviorOperation.createFactory(
            configuration: config,
            postData: postData,
            isPurchaseAllowedByRestoreBehaviorCallbackCache: self.isPurchaseAllowedByRestoreBehaviorCallbacksCache
        )
        let callback = IsPurchaseAllowedByRestoreBehaviorCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.isPurchaseAllowedByRestoreBehaviorCallbacksCache.add(callback)

        backendConfig.addCacheableOperation(
            with: factory,
            delay: .default(forBackgroundedApp: isAppBackgrounded),
            cacheStatus: cacheStatus
        )
    }

    // swiftlint:disable function_parameter_count
    func post(receipt: EncodedAppleReceipt,
              productData: ProductRequestData?,
              transactionData: PurchasedTransactionData,
              postReceiptSource: PostReceiptSource,
              observerMode: Bool,
              originalPurchaseCompletedBy: PurchasesAreCompletedBy?,
              appTransaction: String?,
              associatedTransactionId: String?,
              sdkOriginated: Bool = false,
              appUserID: String,
              containsAttributionData: Bool,
              completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        let backendConfig = self.backendLanes[HTTPRequest.Path.postReceiptData]
        var subscriberAttributesToPost: SubscriberAttribute.Dictionary?

        if !backendConfig.systemInfo.dangerousSettings.customEntitlementComputation {
            subscriberAttributesToPost = transactionData.unsyncedAttributes ?? [:]
            let attributionStatus = self.attributionFetcher.authorizationStatus
            let consentStatus = SubscriberAttribute(attribute: ReservedSubscriberAttribute.consentStatus,
                                                    value: attributionStatus.description,
                                                    dateProvider: backendConfig.dateProvider,
                                                    ignoreTimeInCacheIdentity: true)
            subscriberAttributesToPost?[consentStatus.key] = consentStatus
        }

        let config = NetworkOperation.UserSpecificConfiguration(httpClient: backendConfig.httpClient,
                                                                appUserID: appUserID)

        let postData = PostReceiptDataOperation.PostData(
            transactionData: transactionData.withAttributesToPost(subscriberAttributesToPost),
            postReceiptSource: postReceiptSource,
            appUserID: appUserID,
            productData: productData,
            receipt: receipt,
            observerMode: observerMode,
            purchaseCompletedBy: originalPurchaseCompletedBy,
            testReceiptIdentifier: backendConfig.systemInfo.testReceiptIdentifier,
            appTransaction: appTransaction,
            transactionId: associatedTransactionId,
            containsAttributionData: containsAttributionData,
            sdkOriginated: sdkOriginated
        )
        let offlineCustomerInfoCreator: OfflineCustomerInfoCreator? =
            backendConfig.systemInfo.supportsOfflineEntitlements
            ? backendConfig.offlineCustomerInfoCreator
            : nil

        let factory = PostReceiptDataOperation.createFactory(
            configuration: config,
            postData: postData,
            customerInfoCallbackCache: self.customerInfoCallbackCache,
            offlineCustomerInfoCreator: offlineCustomerInfoCreator
        )

        let callbackObject = CustomerInfoCallback(cacheKey: factory.cacheKey,
                                                  appUserID: appUserID,
                                                  source: PostReceiptDataOperation.self,
                                                  completion: completion)

        let cacheStatus = customerInfoCallbackCache.add(callbackObject)

        backendConfig.operationQueue.addCacheableOperation(with: factory, cacheStatus: cacheStatus)
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
