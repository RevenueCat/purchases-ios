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

    private let config: BackendConfiguration
    private let identityAPI: IdentityAPI
    private let offeringsAPI: OfferingsAPI
    private let customerAPI: CustomerAPI

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
                                          operationQueue: QueueProvider.createBackendQueue(),
                                          dateProvider: dateProvider)
        self.init(backendConfig: config, attributionFetcher: attributionFetcher)
    }

    required init(backendConfig: BackendConfiguration, attributionFetcher: AttributionFetcher) {
        self.config = backendConfig

        self.customerAPI = CustomerAPI(backendConfig: self.config, attributionFetcher: attributionFetcher)
        self.identityAPI = IdentityAPI(backendConfig: self.config)
        self.offeringsAPI = OfferingsAPI(backendConfig: self.config)
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
              completion: @escaping OfferingsAPI.OfferSigningResponseHandler) {
        self.offeringsAPI.post(offerIdForSigning: offerIdentifier,
                               productIdentifier: productIdentifier,
                               subscriptionGroup: subscriptionGroup,
                               receiptData: receiptData,
                               appUserID: appUserID,
                               completion: completion)
    }

    func post(attributionData: [String: Any],
              network: AttributionNetwork,
              appUserID: String,
              completion: CustomerAPI.SimpleResponseHandler?) {
        self.customerAPI.post(attributionData: attributionData,
                              network: network,
                              appUserID: appUserID,
                              completion: completion)
    }

    func getOfferings(appUserID: String, completion: @escaping OfferingsAPI.OfferingsResponseHandler) {
        self.offeringsAPI.getOfferings(appUserID: appUserID, completion: completion)
    }

    func getIntroEligibility(appUserID: String,
                             receiptData: Data,
                             productIdentifiers: [String],
                             completion: @escaping OfferingsAPI.IntroEligibilityResponseHandler) {
        self.offeringsAPI.getIntroEligibility(appUserID: appUserID,
                                              receiptData: receiptData,
                                              productIdentifiers: productIdentifiers,
                                              completion: completion)
    }

    func logIn(currentAppUserID: String,
               newAppUserID: String,
               completion: @escaping IdentityAPI.LogInResponseHandler) {
        self.identityAPI.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID, completion: completion)
    }

    func getCustomerInfo(appUserID: String, completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        self.customerAPI.getCustomerInfo(appUserID: appUserID, completion: completion)
    }

    // swiftlint:disable:next function_parameter_count
    func post(receiptData: Data,
              appUserID: String,
              isRestore: Bool,
              productData: ProductRequestData?,
              presentedOfferingIdentifier offeringIdentifier: String?,
              observerMode: Bool,
              subscriberAttributes subscriberAttributesByKey: SubscriberAttributeDict?,
              completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        self.customerAPI.post(receiptData: receiptData,
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
              completion: CustomerAPI.SimpleResponseHandler?) {
        self.customerAPI.post(subscriberAttributes: subscriberAttributes, appUserID: appUserID, completion: completion)
    }

}

extension Backend {

    enum QueueProvider {

        static func createBackendQueue() -> OperationQueue {
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
