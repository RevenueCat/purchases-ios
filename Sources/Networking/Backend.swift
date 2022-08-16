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

class Backend {

    let identity: IdentityAPI
    let offerings: OfferingsAPI

    private let config: BackendConfiguration
    private let customer: CustomerAPI

    convenience init(apiKey: String,
                     systemInfo: SystemInfo,
                     httpClientTimeout: TimeInterval = Configuration.networkTimeoutDefault,
                     eTagManager: ETagManager,
                     operationDispatcher: OperationDispatcher,
                     attributionFetcher: AttributionFetcher,
                     dateProvider: DateProvider = DateProvider()) {
        let httpClient = HTTPClient(apiKey: apiKey,
                                    systemInfo: systemInfo,
                                    eTagManager: eTagManager,
                                    requestTimeout: httpClientTimeout)
        let config = BackendConfiguration(httpClient: httpClient,
                                          operationDispatcher: operationDispatcher,
                                          operationQueue: QueueProvider.createBackendQueue(),
                                          dateProvider: dateProvider)
        self.init(backendConfig: config, attributionFetcher: attributionFetcher)
    }

    convenience init(backendConfig: BackendConfiguration, attributionFetcher: AttributionFetcher) {
        let customer = CustomerAPI(backendConfig: backendConfig, attributionFetcher: attributionFetcher)
        let identity = IdentityAPI(backendConfig: backendConfig)
        let offerings = OfferingsAPI(backendConfig: backendConfig)
        self.init(backendConfig: backendConfig, customerAPI: customer, identityAPI: identity, offeringsAPI: offerings)
    }

    required init(backendConfig: BackendConfiguration,
                  customerAPI: CustomerAPI,
                  identityAPI: IdentityAPI,
                  offeringsAPI: OfferingsAPI) {
        self.config = backendConfig
        self.customer = customerAPI
        self.identity = identityAPI
        self.offerings = offeringsAPI
    }

    func clearHTTPClientCaches() {
        self.config.clearCache()
    }

    func post(attributionData: [String: Any],
              network: AttributionNetwork,
              appUserID: String,
              completion: CustomerAPI.SimpleResponseHandler?) {
        self.customer.post(attributionData: attributionData,
                           network: network,
                           appUserID: appUserID,
                           completion: completion)
    }

    func post(adServicesToken: String,
              appUserID: String,
              completion: CustomerAPI.SimpleResponseHandler?) {
        self.customer.post(adServicesToken: adServicesToken,
                           appUserID: appUserID,
                           completion: completion)
    }

    func getCustomerInfo(appUserID: String,
                         withRandomDelay randomDelay: Bool,
                         completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        self.customer.getCustomerInfo(appUserID: appUserID,
                                      withRandomDelay: randomDelay,
                                      completion: completion)
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
        self.customer.post(receiptData: receiptData,
                           appUserID: appUserID,
                           isRestore: isRestore,
                           productData: productData,
                           presentedOfferingIdentifier: offeringIdentifier,
                           observerMode: observerMode,
                           subscriberAttributes: subscriberAttributesByKey,
                           completion: completion)
    }

    func post(subscriberAttributes: SubscriberAttribute.Dictionary,
              appUserID: String,
              completion: CustomerAPI.SimpleResponseHandler?) {
        self.customer.post(subscriberAttributes: subscriberAttributes, appUserID: appUserID, completion: completion)
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
