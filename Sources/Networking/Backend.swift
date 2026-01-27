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
    let webBilling: WebBillingAPI
    let offlineEntitlements: OfflineEntitlementsAPI
    let customer: CustomerAPI
    let internalAPI: InternalAPI
    let customerCenterConfig: CustomerCenterConfigAPI
    let redeemWebPurchaseAPI: RedeemWebPurchaseAPI
    let virtualCurrenciesAPI: VirtualCurrenciesAPI
    let iam: IAMAPI?
    let iamManager: IAMManager?

    private let config: BackendConfiguration

    convenience init(
        apiKey: String,
        systemInfo: SystemInfo,
        httpClientTimeout: TimeInterval = Configuration.networkTimeoutDefault,
        eTagManager: ETagManager,
        operationDispatcher: OperationDispatcher,
        attributionFetcher: AttributionFetcher,
        offlineCustomerInfoCreator: OfflineCustomerInfoCreator?,
        diagnosticsTracker: DiagnosticsTrackerType?,
        deviceCache: DeviceCache?,
        dateProvider: DateProvider = DateProvider()
    ) {
        // Create IAM components if IAM is enabled
        let iamManager: IAMManager?
        let iamAPI: IAMAPI?

        if systemInfo.dangerousSettings.iamAuthenticationEnabled {
            // Create token store and IAM API first
            let tokenStore = IAMTokenStore()

            // Create a temporary BackendConfiguration for IAMAPI
            // We'll create the final one below with the IAMManager
            let tempHttpClient = HTTPClient(apiKey: apiKey,
                                           systemInfo: systemInfo,
                                           eTagManager: eTagManager,
                                           signing: Signing(apiKey: apiKey, clock: systemInfo.clock),
                                           diagnosticsTracker: diagnosticsTracker,
                                           requestTimeout: httpClientTimeout,
                                           operationDispatcher: OperationDispatcher.default,
                                           iamManager: nil)
            let tempConfig = BackendConfiguration(httpClient: tempHttpClient,
                                                 operationDispatcher: operationDispatcher,
                                                 operationQueue: QueueProvider.createBackendQueue(),
                                                 diagnosticsQueue: QueueProvider.createDiagnosticsQueue(),
                                                 systemInfo: systemInfo,
                                                 offlineCustomerInfoCreator: offlineCustomerInfoCreator,
                                                 dateProvider: dateProvider)

            iamAPI = IAMAPI(backendConfig: tempConfig)

            // Create IAM Manager
            iamManager = IAMManager(
                tokenStore: tokenStore,
                iamAPI: iamAPI!,
                deviceCache: deviceCache ?? DeviceCache(systemInfo: systemInfo,
                                                       userDefaults: UserDefaults.computeDefault())
            )
        } else {
            iamManager = nil
            iamAPI = nil
        }

        // Create HTTPClient with IAMManager
        let httpClient = HTTPClient(apiKey: apiKey,
                                    systemInfo: systemInfo,
                                    eTagManager: eTagManager,
                                    signing: Signing(apiKey: apiKey, clock: systemInfo.clock),
                                    diagnosticsTracker: diagnosticsTracker,
                                    requestTimeout: httpClientTimeout,
                                    operationDispatcher: OperationDispatcher.default,
                                    iamManager: iamManager)
        let config = BackendConfiguration(httpClient: httpClient,
                                          operationDispatcher: operationDispatcher,
                                          operationQueue: QueueProvider.createBackendQueue(),
                                          diagnosticsQueue: QueueProvider.createDiagnosticsQueue(),
                                          systemInfo: systemInfo,
                                          offlineCustomerInfoCreator: offlineCustomerInfoCreator,
                                          dateProvider: dateProvider)
        self.init(backendConfig: config, attributionFetcher: attributionFetcher, iamAPI: iamAPI, iamManager: iamManager)
    }

    convenience init(backendConfig: BackendConfiguration,
                     attributionFetcher: AttributionFetcher,
                     iamAPI: IAMAPI? = nil,
                     iamManager: IAMManager? = nil) {
        let customer = CustomerAPI(backendConfig: backendConfig, attributionFetcher: attributionFetcher)
        let identity = IdentityAPI(backendConfig: backendConfig)
        let offerings = OfferingsAPI(backendConfig: backendConfig)
        let webBilling = WebBillingAPI(backendConfig: backendConfig)
        let offlineEntitlements = OfflineEntitlementsAPI(backendConfig: backendConfig)
        let internalAPI = InternalAPI(backendConfig: backendConfig)
        let customerCenterConfig = CustomerCenterConfigAPI(backendConfig: backendConfig)
        let redeemWebPurchaseAPI = RedeemWebPurchaseAPI(backendConfig: backendConfig)
        let virtualCurrenciesAPI = VirtualCurrenciesAPI(backendConfig: backendConfig)

        self.init(backendConfig: backendConfig,
                  customerAPI: customer,
                  identityAPI: identity,
                  offeringsAPI: offerings,
                  webBillingAPI: webBilling,
                  offlineEntitlements: offlineEntitlements,
                  internalAPI: internalAPI,
                  customerCenterConfig: customerCenterConfig,
                  redeemWebPurchaseAPI: redeemWebPurchaseAPI,
                  virtualCurrenciesAPI: virtualCurrenciesAPI,
                  iamAPI: iamAPI,
                  iamManager: iamManager)
    }

    required init(backendConfig: BackendConfiguration,
                  customerAPI: CustomerAPI,
                  identityAPI: IdentityAPI,
                  offeringsAPI: OfferingsAPI,
                  webBillingAPI: WebBillingAPI,
                  offlineEntitlements: OfflineEntitlementsAPI,
                  internalAPI: InternalAPI,
                  customerCenterConfig: CustomerCenterConfigAPI,
                  redeemWebPurchaseAPI: RedeemWebPurchaseAPI,
                  virtualCurrenciesAPI: VirtualCurrenciesAPI,
                  iamAPI: IAMAPI? = nil,
                  iamManager: IAMManager? = nil) {
        self.config = backendConfig

        self.customer = customerAPI
        self.identity = identityAPI
        self.offerings = offeringsAPI
        self.webBilling = webBillingAPI
        self.offlineEntitlements = offlineEntitlements
        self.internalAPI = internalAPI
        self.customerCenterConfig = customerCenterConfig
        self.redeemWebPurchaseAPI = redeemWebPurchaseAPI
        self.virtualCurrenciesAPI = virtualCurrenciesAPI
        self.iam = iamAPI
        self.iamManager = iamManager
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
                         isAppBackgrounded: Bool,
                         allowComputingOffline: Bool = true,
                         completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        self.customer.getCustomerInfo(appUserID: appUserID,
                                      isAppBackgrounded: isAppBackgrounded,
                                      allowComputingOffline: allowComputingOffline,
                                      completion: completion)
    }

    // swiftlint:disable:next function_parameter_count
    func post(receipt: EncodedAppleReceipt,
              productData: ProductRequestData?,
              transactionData: PurchasedTransactionData,
              postReceiptSource: PostReceiptSource,
              observerMode: Bool,
              // Value at the time of the purchase (which might come from the `LocalTransactionMetadataStore`)
              originalPurchaseCompletedBy: PurchasesAreCompletedBy?,
              appTransaction: String? = nil,
              associatedTransactionId: String? = nil,
              sdkOriginated: Bool = false,
              appUserID: String,
              containsAttributionData: Bool = false,
              completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        self.customer.post(receipt: receipt,
                           productData: productData,
                           transactionData: transactionData,
                           postReceiptSource: postReceiptSource,
                           observerMode: observerMode,
                           originalPurchaseCompletedBy: originalPurchaseCompletedBy,
                           appTransaction: appTransaction,
                           associatedTransactionId: associatedTransactionId,
                           sdkOriginated: sdkOriginated,
                           appUserID: appUserID,
                           containsAttributionData: containsAttributionData,
                           completion: completion)
    }

    func post(subscriberAttributes: SubscriberAttribute.Dictionary,
              appUserID: String,
              completion: CustomerAPI.SimpleResponseHandler?) {
        self.customer.post(subscriberAttributes: subscriberAttributes, appUserID: appUserID, completion: completion)
    }

    #if DEBUG
    /// Checks if the SDK should log the status of the health report to the console.
    /// - Parameter appUserID: An `appUserID` that allows the Backend to check for health report availability
    /// - Returns: Whether the health report should be reported to the console for the given `appUserID`.
    func healthReportAvailabilityRequest(appUserID: String) async throws -> HealthReportAvailability {
        try await Async.call { (completion: @escaping (Result<HealthReportAvailability, BackendError>) -> Void) in
            self.internalAPI.healthReportAvailabilityRequest(
                appUserID: appUserID,
                completion: completion
            )
        }
    }

    /// Call the `/health_report` endpoint and perform a full validation of the SDK's configuration
    /// - Parameter appUserID: An `appUserID` that allows the Backend to fetch offerings
    /// - Returns: A report with all validation checks along with their status
    func healthReportRequest(appUserID: String) async throws -> HealthReport {
        try await Async.call { (completion: @escaping (Result<HealthReport, BackendError>) -> Void) in
            self.internalAPI.healthReportRequest(appUserID: appUserID, completion: completion)
        }
    }
    #endif
}

extension Backend {

    /// - Throws: `NetworkError`
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
            operationQueue.name = "RC Backend Queue"
            operationQueue.maxConcurrentOperationCount = 1
            return operationQueue
        }

        static func createDiagnosticsQueue() -> OperationQueue {
            let operationQueue = OperationQueue()
            operationQueue.name = "RC Diagnostics Queue"
            operationQueue.maxConcurrentOperationCount = 1
            operationQueue.qualityOfService = .background
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
