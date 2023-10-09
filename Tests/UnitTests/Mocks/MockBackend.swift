//
// Created by RevenueCat on 2/28/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

// swiftlint:disable large_tuple line_length
class MockBackend: Backend {

    typealias PostReceiptParameters = (data: EncodedAppleReceipt?,
                                       productData: ProductRequestData?,
                                       transactionData: PurchasedTransactionData,
                                       observerMode: Bool,
                                       completion: CustomerAPI.CustomerInfoResponseHandler?)

    var invokedPostReceiptData = false
    var invokedPostReceiptDataCount = 0
    var stubbedPostReceiptResult: Result<CustomerInfo, BackendError>?
    var invokedPostReceiptDataParameters: PostReceiptParameters?
    var invokedPostReceiptDataParametersList: [PostReceiptParameters] = []
    var onPostReceipt: (() -> Void)?

    public convenience init() {
        let systemInfo = MockSystemInfo(platformInfo: nil, finishTransactions: false, dangerousSettings: nil)
        let attributionFetcher = AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                    systemInfo: systemInfo)

        let backendConfig = MockBackendConfiguration()
        let identity = MockIdentityAPI(backendConfig: backendConfig)
        let offerings = MockOfferingsAPI(backendConfig: backendConfig)
        let offlineEntitlements = MockOfflineEntitlementsAPI()
        let customer = CustomerAPI(backendConfig: backendConfig, attributionFetcher: attributionFetcher)
        let internalAPI = InternalAPI(backendConfig: backendConfig)

        self.init(backendConfig: backendConfig,
                  customerAPI: customer,
                  identityAPI: identity,
                  offeringsAPI: offerings,
                  offlineEntitlements: offlineEntitlements,
                  internalAPI: internalAPI)
    }

    override func post(receiptData: EncodedAppleReceipt,
                       productData: ProductRequestData?,
                       transactionData: PurchasedTransactionData,
                       observerMode: Bool,
                       completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        invokedPostReceiptData = true
        invokedPostReceiptDataCount += 1
        invokedPostReceiptDataParameters = (receiptData,
                                            productData,
                                            transactionData,
                                            observerMode,
                                            completion)
        invokedPostReceiptDataParametersList.append((receiptData,
                                                     productData,
                                                     transactionData,
                                                     observerMode,
                                                     completion))

        self.onPostReceipt?()

        completion(stubbedPostReceiptResult ?? .failure(.missingAppUserID()))
    }

    var invokedGetSubscriberData = false
    var invokedGetSubscriberDataCount = 0
    var invokedGetSubscriberDataParameters: (appUserID: String?,
                                             isAppBackgrounded: Bool,
                                             allowComputingOffline: Bool,
                                             completion: CustomerAPI.CustomerInfoResponseHandler?)?
    var invokedGetSubscriberDataParametersList = [(appUserID: String?,
                                                   isAppBackgrounded: Bool,
                                                   allowComputingOffline: Bool,
                                                   completion: CustomerAPI.CustomerInfoResponseHandler?)]()

    var stubbedGetCustomerInfoResult: Result<CustomerInfo, BackendError> = .failure(.missingAppUserID())

    override func getCustomerInfo(appUserID: String,
                                  isAppBackgrounded: Bool,
                                  allowComputingOffline: Bool,
                                  completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        invokedGetSubscriberData = true
        invokedGetSubscriberDataCount += 1
        invokedGetSubscriberDataParameters = (appUserID, isAppBackgrounded, allowComputingOffline, completion)
        invokedGetSubscriberDataParametersList.append((appUserID, isAppBackgrounded, allowComputingOffline, completion))

        completion(self.stubbedGetCustomerInfoResult)
    }

    var invokedPostAttributionData = false
    var invokedPostAttributionDataCount = 0
    var invokedPostAttributionDataParameters: (data: [String: Any]?, network: AttributionNetwork, appUserID: String?)?
    var invokedPostAttributionDataParametersList = [(data: [String: Any]?,
                                                     network: AttributionNetwork,
        appUserID: String?)]()
    var stubbedPostAttributionDataCompletionResult: (BackendError?, Void)?

    override func post(attributionData: [String: Any],
                       network: AttributionNetwork,
                       appUserID: String,
                       completion: ((BackendError?) -> Void)?) {
        invokedPostAttributionData = true
        invokedPostAttributionDataCount += 1
        invokedPostAttributionDataParameters = (attributionData, network, appUserID)
        invokedPostAttributionDataParametersList.append((attributionData, network, appUserID))
        if let result = stubbedPostAttributionDataCompletionResult {
            completion?(result.0)
        }
    }

    var invokedPostAdServicesToken = false
    var invokedPostAdServicesTokenCount = 0
    var invokedPostAdServicesTokenParameters: (token: String, appUserID: String?)?
    var invokedPostAdServicesTokenParametersList = [(token: String, appUserID: String?)]()
    var stubbedPostAdServicesTokenCompletionResult: Result<Void, BackendError>?

    override func post(adServicesToken: String,
                       appUserID: String,
                       completion: CustomerAPI.SimpleResponseHandler?) {
        invokedPostAdServicesToken = true
        invokedPostAdServicesTokenCount += 1
        invokedPostAdServicesTokenParameters = (adServicesToken, appUserID)
        invokedPostAdServicesTokenParametersList.append((adServicesToken, appUserID))
        if let result = stubbedPostAdServicesTokenCompletionResult {
            completion?(result.error)
        }
    }

    var invokedPostSubscriberAttributes = false
    var invokedPostSubscriberAttributesCount = 0
    var invokedPostSubscriberAttributesParameters: (subscriberAttributes: [String: SubscriberAttribute]?, appUserID: String?)?
    var invokedPostSubscriberAttributesParametersList: [InvokedPostSubscriberAttributesParams] = []
    var stubbedPostSubscriberAttributesCompletionResult: Result<Void, BackendError>?

    override func post(subscriberAttributes: SubscriberAttribute.Dictionary,
                       appUserID: String,
                       completion: ((BackendError?) -> Void)?) {
        invokedPostSubscriberAttributes = true
        invokedPostSubscriberAttributesCount += 1
        invokedPostSubscriberAttributesParameters = (subscriberAttributes, appUserID)
        invokedPostSubscriberAttributesParametersList.append(
            InvokedPostSubscriberAttributesParams(subscriberAttributes: subscriberAttributes, appUserID: appUserID)
        )
        if let result = stubbedPostSubscriberAttributesCompletionResult {
            completion?(result.error)
        } else {
            completion?(nil)
        }
    }

    var invokedClearHTTPClientCaches = false
    var invokedClearHTTPClientCachesCount = 0
    override func clearHTTPClientCaches() {
        self.invokedClearHTTPClientCaches = true
        self.invokedClearHTTPClientCachesCount += 1
    }

    struct InvokedPostSubscriberAttributesParams: Equatable {
        let subscriberAttributes: [String: SubscriberAttribute]?
        let appUserID: String?
    }

    var stubbedSignatureVerificationEnabled: Bool?

    override var signatureVerificationEnabled: Bool {
        return self.stubbedSignatureVerificationEnabled ?? super.signatureVerificationEnabled
    }

    static let referenceDate = Date(timeIntervalSinceReferenceDate: 700000000) // 2023-03-08 20:26:40

}
