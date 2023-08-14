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
    let offlineEntitlements: OfflineEntitlementsAPI
    let customer: CustomerAPI
    let internalAPI: InternalAPI

    private let config: BackendConfiguration

    convenience init(
        apiKey: String,
        systemInfo: SystemInfo,
        httpClientTimeout: TimeInterval = Configuration.networkTimeoutDefault,
        eTagManager: ETagManager,
        operationDispatcher: OperationDispatcher,
        attributionFetcher: AttributionFetcher,
        offlineCustomerInfoCreator: OfflineCustomerInfoCreator?,
        dateProvider: DateProvider = DateProvider()
    ) {
        let httpClient = HTTPClient(apiKey: apiKey,
                                    systemInfo: systemInfo,
                                    eTagManager: eTagManager,
                                    signing: Signing(apiKey: apiKey, clock: systemInfo.clock),
                                    requestTimeout: httpClientTimeout)
        let config = BackendConfiguration(httpClient: httpClient,
                                          operationDispatcher: operationDispatcher,
                                          operationQueue: QueueProvider.createBackendQueue(),
                                          systemInfo: systemInfo,
                                          offlineCustomerInfoCreator: offlineCustomerInfoCreator,
                                          dateProvider: dateProvider)
        self.init(backendConfig: config, attributionFetcher: attributionFetcher)
    }

    convenience init(backendConfig: BackendConfiguration, attributionFetcher: AttributionFetcher) {
        let customer = CustomerAPI(backendConfig: backendConfig, attributionFetcher: attributionFetcher)
        let identity = IdentityAPI(backendConfig: backendConfig)
        let offerings = OfferingsAPI(backendConfig: backendConfig)
        let offlineEntitlements = OfflineEntitlementsAPI(backendConfig: backendConfig)
        let internalAPI = InternalAPI(backendConfig: backendConfig)

        self.init(backendConfig: backendConfig,
                  customerAPI: customer,
                  identityAPI: identity,
                  offeringsAPI: offerings,
                  offlineEntitlements: offlineEntitlements,
                  internalAPI: internalAPI)
    }

    required init(backendConfig: BackendConfiguration,
                  customerAPI: CustomerAPI,
                  identityAPI: IdentityAPI,
                  offeringsAPI: OfferingsAPI,
                  offlineEntitlements: OfflineEntitlementsAPI,
                  internalAPI: InternalAPI) {
        self.config = backendConfig

        self.customer = customerAPI
        self.identity = identityAPI
        self.offerings = offeringsAPI
        self.offlineEntitlements = offlineEntitlements
        self.internalAPI = internalAPI
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
                         allowComputingOffline: Bool = true,
                         completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        self.customer.getCustomerInfo(appUserID: appUserID,
                                      withRandomDelay: randomDelay,
                                      allowComputingOffline: allowComputingOffline,
                                      completion: completion)
    }

    func post(receiptData: Data,
              productData: ProductRequestData?,
              transactionData: PurchasedTransactionData,
              observerMode: Bool,
              completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        self.customer.post(receiptData: receiptData,
                           productData: productData,
                           transactionData: transactionData,
                           observerMode: observerMode,
                           completion: completion)
    }

    func post(subscriberAttributes: SubscriberAttribute.Dictionary,
              appUserID: String,
              completion: CustomerAPI.SimpleResponseHandler?) {
        self.customer.post(subscriberAttributes: subscriberAttributes, appUserID: appUserID, completion: completion)
    }

}

extension Backend {

    /// - Throws: `NetworkError`
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func healthRequest(signatureVerification: Bool) async throws {
        try await Async.call { completion in
            self.internalAPI.healthRequest(signatureVerification: signatureVerification) { error in
                completion(.init(error))
            }
        }
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension Backend: @unchecked Sendable {}

// MARK: - Internal

extension Backend {

    typealias ResponseHandler<Response> = @Sendable (Swift.Result<Response, BackendError>) -> Void

}

extension Backend {

    @objc var signatureVerificationEnabled: Bool {
        return self.config.httpClient.signatureVerificationEnabled
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

// MARK: - Testing extensions

extension Backend {

    var networkTimeout: TimeInterval {
        return self.config.httpClient.timeout
    }

    var offlineCustomerInfoEnabled: Bool {
        return self.config.offlineCustomerInfoCreator != nil
    }

}
