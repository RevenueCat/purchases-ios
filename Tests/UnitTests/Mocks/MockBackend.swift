//
// Created by RevenueCat on 2/28/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

// swiftlint:disable large_tuple force_try line_length
class MockBackend: Backend {

    var invokedPostReceiptData = false
    var invokedPostReceiptDataCount = 0
    var stubbedPostReceiptResult: Result<CustomerInfo, BackendError>?
    var invokedPostReceiptDataParameters: (data: Data?,
                                           appUserID: String?,
                                           isRestore: Bool,
                                           productData: ProductRequestData?,
                                           offeringIdentifier: String?,
                                           observerMode: Bool,
                                           subscriberAttributesByKey: [String: SubscriberAttribute]?,
                                           completion: CustomerAPI.CustomerInfoResponseHandler?)?
    var invokedPostReceiptDataParametersList = [(data: Data?,
        appUserID: String?,
        isRestore: Bool,
        productData: ProductRequestData?,
        offeringIdentifier: String?,
        observerMode: Bool,
        subscriberAttributesByKey: [String: SubscriberAttribute]?,
        completion: CustomerAPI.CustomerInfoResponseHandler?)]()

    public convenience init() {
        let systemInfo = try! MockSystemInfo(platformInfo: nil, finishTransactions: false, dangerousSettings: nil)
        let attributionFetcher = AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                    systemInfo: systemInfo)
        let mockAPIKey = "mockAPIKey"
        let httpClient = MockHTTPClient(apiKey: mockAPIKey,
                                        systemInfo: systemInfo,
                                        eTagManager: MockETagManager(),
                                        requestTimeout: 7)
        let backendConfig = BackendConfiguration(httpClient: httpClient,
                                                 operationDispatcher: MockOperationDispatcher(),
                                                 operationQueue: QueueProvider.createBackendQueue(),
                                                 dateProvider: MockDateProvider(stubbedNow: MockBackend.referenceDate))
        let identity = MockIdentityAPI(backendConfig: backendConfig)
        let offerings = MockOfferingsAPI(backendConfig: backendConfig)
        let customer = CustomerAPI(backendConfig: backendConfig, attributionFetcher: attributionFetcher)
        self.init(backendConfig: backendConfig, customerAPI: customer, identityAPI: identity, offeringsAPI: offerings)
    }

    override func post(receiptData: Data,
                       appUserID: String,
                       isRestore: Bool,
                       productData: ProductRequestData?,
                       presentedOfferingIdentifier offeringIdentifier: String?,
                       observerMode: Bool,
                       subscriberAttributes subscriberAttributesByKey: SubscriberAttribute.Dictionary?,
                       completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        invokedPostReceiptData = true
        invokedPostReceiptDataCount += 1
        invokedPostReceiptDataParameters = (receiptData,
                                            appUserID,
                                            isRestore,
                                            productData,
                                            offeringIdentifier,
                                            observerMode,
                                            subscriberAttributesByKey,
                                            completion)
        invokedPostReceiptDataParametersList.append((receiptData,
                                                     appUserID,
                                                     isRestore,
                                                     productData,
                                                     offeringIdentifier,
                                                     observerMode,
                                                     subscriberAttributesByKey,
                                                     completion))
        completion(stubbedPostReceiptResult ?? .failure(.missingAppUserID()))
    }

    var invokedGetSubscriberData = false
    var invokedGetSubscriberDataCount = 0
    var invokedGetSubscriberDataParameters: (appUserID: String?,
                                             randomDelay: Bool,
                                             completion: CustomerAPI.CustomerInfoResponseHandler?)?
    var invokedGetSubscriberDataParametersList = [(appUserID: String?,
                                                   randomDelay: Bool,
                                                   completion: CustomerAPI.CustomerInfoResponseHandler?)]()

    var stubbedGetCustomerInfoResult: Result<CustomerInfo, BackendError> = .failure(.missingAppUserID())

    override func getCustomerInfo(appUserID: String,
                                  withRandomDelay randomDelay: Bool,
                                  completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        invokedGetSubscriberData = true
        invokedGetSubscriberDataCount += 1
        invokedGetSubscriberDataParameters = (appUserID, randomDelay, completion)
        invokedGetSubscriberDataParametersList.append((appUserID, randomDelay, completion))

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

    struct InvokedPostSubscriberAttributesParams: Equatable {
        let subscriberAttributes: [String: SubscriberAttribute]?
        let appUserID: String?
    }

    static let referenceDate = Date(timeIntervalSinceReferenceDate: 700000000) // 2023-03-08 20:26:40

}
