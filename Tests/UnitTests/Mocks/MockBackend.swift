//
// Created by RevenueCat on 2/28/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

// swiftlint:disable large_tuple
// swiftlint:disable force_try
// swiftlint:disable line_length
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
                                           completion: Backend.CustomerInfoResponseHandler?)?
    var invokedPostReceiptDataParametersList = [(data: Data?,
        appUserID: String?,
        isRestore: Bool,
        productData: ProductRequestData?,
        offeringIdentifier: String?,
        observerMode: Bool,
        subscriberAttributesByKey: [String: SubscriberAttribute]?,
        completion: Backend.CustomerInfoResponseHandler?)]()

    public convenience init() {
        let systemInfo = try! MockSystemInfo(platformInfo: nil, finishTransactions: false, dangerousSettings: nil)
        let attributionFetcher = AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                    systemInfo: systemInfo)
        self.init(httpClient: MockHTTPClient(systemInfo: systemInfo, eTagManager: MockETagManager()),
                  apiKey: "mockAPIKey",
                  attributionFetcher: attributionFetcher,
                  dateProvider: MockDateProvider(stubbedNow: MockBackend.referenceDate))
    }

    override func post(receiptData: Data,
                       appUserID: String,
                       isRestore: Bool,
                       productData: ProductRequestData?,
                       presentedOfferingIdentifier offeringIdentifier: String?,
                       observerMode: Bool,
                       subscriberAttributes subscriberAttributesByKey: SubscriberAttributeDict?,
                       completion: @escaping Backend.CustomerInfoResponseHandler) {
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
    var invokedGetSubscriberDataParameters: (appUserID: String?, completion: Backend.CustomerInfoResponseHandler?)?
    var invokedGetSubscriberDataParametersList = [(appUserID: String?,
                                                   completion: Backend.CustomerInfoResponseHandler?)]()

    var stubbedGetCustomerInfoResult: Result<CustomerInfo, BackendError> = .failure(.missingAppUserID())

    override func getCustomerInfo(appUserID: String, completion: @escaping Backend.CustomerInfoResponseHandler) {
        invokedGetSubscriberData = true
        invokedGetSubscriberDataCount += 1
        invokedGetSubscriberDataParameters = (appUserID, completion)
        invokedGetSubscriberDataParametersList.append((appUserID, completion))

        completion(self.stubbedGetCustomerInfoResult)
    }

    var invokedGetIntroEligibility = false
    var invokedGetIntroEligibilityCount = 0
    var invokedGetIntroEligibilityParameters: (appUserID: String?, receiptData: Data?, productIdentifiers: [String]?, completion: IntroEligibilityResponseHandler?)?
    var invokedGetIntroEligibilityParametersList = [(appUserID: String?,
        receiptData: Data?,
        productIdentifiers: [String]?,
        completion: IntroEligibilityResponseHandler?)]()
    var stubbedGetIntroEligibilityCompletionResult: (eligibilities: [String: IntroEligibility], error: BackendError?)?

    override func getIntroEligibility(appUserID: String,
                                      receiptData: Data,
                                      productIdentifiers: [String],
                                      completion: @escaping IntroEligibilityResponseHandler) {
        invokedGetIntroEligibility = true
        invokedGetIntroEligibilityCount += 1
        invokedGetIntroEligibilityParameters = (appUserID, receiptData, productIdentifiers, completion)
        invokedGetIntroEligibilityParametersList.append((appUserID, receiptData, productIdentifiers, completion))
        completion(stubbedGetIntroEligibilityCompletionResult?.eligibilities ?? [:], stubbedGetIntroEligibilityCompletionResult?.error)
    }

    var invokedGetOfferingsForAppUserID = false
    var invokedGetOfferingsForAppUserIDCount = 0
    var invokedGetOfferingsForAppUserIDParameters: (appUserID: String?, completion: OfferingsResponseHandler?)?
    var invokedGetOfferingsForAppUserIDParametersList = [(appUserID: String?, completion: OfferingsResponseHandler?)]()
    var stubbedGetOfferingsCompletionResult: Result<[String: Any], BackendError>?

    override func getOfferings(appUserID: String, completion: @escaping OfferingsResponseHandler) {
        invokedGetOfferingsForAppUserID = true
        invokedGetOfferingsForAppUserIDCount += 1
        invokedGetOfferingsForAppUserIDParameters = (appUserID, completion)
        invokedGetOfferingsForAppUserIDParametersList.append((appUserID, completion))

        completion(stubbedGetOfferingsCompletionResult!)
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

    var invokedCreateAlias = false
    var invokedCreateAliasCount = 0
    var invokedCreateAliasParameters: (appUserID: String?, newAppUserID: String?)?
    var invokedCreateAliasParametersList = [(appUserID: String?, newAppUserID: String?)]()
    var stubbedCreateAliasCompletionResult: (BackendError?, Void)?

    override func createAlias(appUserID: String, newAppUserID: String, completion: ((BackendError?) -> Void)?) {
        invokedCreateAlias = true
        invokedCreateAliasCount += 1
        invokedCreateAliasParameters = (appUserID, newAppUserID)
        invokedCreateAliasParametersList.append((appUserID, newAppUserID))
        if let result = stubbedCreateAliasCompletionResult {
            completion?(result.0)
        }
    }

    var invokedPostOffer = false
    var invokedPostOfferCount = 0
    var invokedPostOfferParameters: (offerIdentifier: String?, productIdentifier: String?, subscriptionGroup: String?, data: Data?, applicationUsername: String?, completion: OfferSigningResponseHandler?)?
    var invokedPostOfferParametersList = [(offerIdentifier: String?,
        productIdentifier: String?,
        subscriptionGroup: String?,
        data: Data?,
        applicationUsername: String?,
        completion: OfferSigningResponseHandler?)]()
    var stubbedPostOfferCompletionResult: Result<PostOfferForSigningOperation.SigningData, BackendError>?

    override func post(offerIdForSigning offerIdentifier: String,
                       productIdentifier: String,
                       subscriptionGroup: String?,
                       receiptData: Data,
                       appUserID: String,
                       completion: @escaping OfferSigningResponseHandler) {
        invokedPostOffer = true
        invokedPostOfferCount += 1
        invokedPostOfferParameters = (offerIdentifier,
            productIdentifier,
            subscriptionGroup,
            receiptData,
            appUserID,
            completion)
        invokedPostOfferParametersList.append((offerIdentifier,
                                                  productIdentifier,
                                                  subscriptionGroup,
                                                  receiptData,
                                                  appUserID,
                                                  completion))

        completion(stubbedPostOfferCompletionResult ?? .failure(.missingAppUserID()))
    }

    var invokedPostSubscriberAttributes = false
    var invokedPostSubscriberAttributesCount = 0
    var invokedPostSubscriberAttributesParameters: (subscriberAttributes: [String: SubscriberAttribute]?, appUserID: String?)?
    var invokedPostSubscriberAttributesParametersList: [InvokedPostSubscriberAttributesParams] = []
    var stubbedPostSubscriberAttributesCompletionResult: (BackendError?, Void)?

    override func post(subscriberAttributes: SubscriberAttributeDict,
                       appUserID: String,
                       completion: ((BackendError?) -> Void)?) {
        invokedPostSubscriberAttributes = true
        invokedPostSubscriberAttributesCount += 1
        invokedPostSubscriberAttributesParameters = (subscriberAttributes, appUserID)
        invokedPostSubscriberAttributesParametersList.append(
            InvokedPostSubscriberAttributesParams(subscriberAttributes: subscriberAttributes, appUserID: appUserID)
        )
        if let result = stubbedPostSubscriberAttributesCompletionResult {
            completion?(result.0)
        } else {
            completion?(nil)
        }
    }

    struct InvokedPostSubscriberAttributesParams: Equatable {
        let subscriberAttributes: [String: SubscriberAttribute]?
        let appUserID: String?
    }

    var invokedLogIn = false
    var invokedLogInCount = 0
    var invokedLogInParameters: (currentAppUserID: String, newAppUserID: String)?
    var invokedLogInParametersList = [(currentAppUserID: String, newAppUserID: String)]()
    var stubbedLogInCompletionResult: Result<(info: CustomerInfo, created: Bool), BackendError>?

    override func logIn(currentAppUserID: String,
                        newAppUserID: String,
                        completion: @escaping LogInResponseHandler) {
        invokedLogIn = true
        invokedLogInCount += 1
        invokedLogInParameters = (currentAppUserID, newAppUserID)
        invokedLogInParametersList.append((currentAppUserID, newAppUserID))
        if let result = stubbedLogInCompletionResult {
            completion(result)
        }
    }

    static let referenceDate = Date(timeIntervalSinceReferenceDate: 700000000) // 2023-03-08 20:26:40

}
