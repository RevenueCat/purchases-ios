//
// Created by RevenueCat on 2/28/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import Purchases

class MockBackend: Backend {

    var invokedPostReceiptData = false
    var invokedPostReceiptDataCount = 0
    var stubbedPostReceiptPurchaserInfo: PurchaserInfo? = nil
    var stubbedPostReceiptPurchaserError: Error? = nil
    var invokedPostReceiptDataParameters: (data: Data?,
                                           appUserID: String?,
                                           isRestore: Bool,
                                           productInfo: ProductInfo?,
                                           offeringIdentifier: String?,
                                           observerMode: Bool,
                                           subscriberAttributesByKey: [String: SubscriberAttribute]?,
                                           completion: BackendPurchaserInfoResponseHandler?)?
    var invokedPostReceiptDataParametersList = [(data: Data?,
        appUserID: String?,
        isRestore: Bool,
        productInfo: ProductInfo?,
        offeringIdentifier: String?,
        observerMode: Bool,
        subscriberAttributesByKey: [String: SubscriberAttribute]?,
        completion: BackendPurchaserInfoResponseHandler?)]()

    public convenience init() {
        self.init(httpClient: MockHTTPClient(systemInfo: try! MockSystemInfo(platformFlavor: nil,
                                                                             platformFlavorVersion: nil,
                                                                             finishTransactions: false),
                                             eTagManager: MockETagManager(),
                                             operationDispatcher: MockOperationDispatcher()),
                  apiKey: "mockAPIKey")
    }

    override func post(receiptData: Data,
                       appUserID: String,
                       isRestore: Bool,
                       productInfo: ProductInfo?,
                       presentedOfferingIdentifier offeringIdentifier: String?,
                       observerMode: Bool,
                       subscriberAttributes subscriberAttributesByKey: SubscriberAttributeDict?,
                       completion: @escaping BackendPurchaserInfoResponseHandler) {
        invokedPostReceiptData = true
        invokedPostReceiptDataCount += 1
        invokedPostReceiptDataParameters = (receiptData,
                                            appUserID,
                                            isRestore,
                                            productInfo,
                                            offeringIdentifier,
                                            observerMode,
                                            subscriberAttributesByKey,
                                            completion)
        invokedPostReceiptDataParametersList.append((receiptData,
                                                     appUserID,
                                                     isRestore,
                                                     productInfo,
                                                     offeringIdentifier,
                                                     observerMode,
                                                     subscriberAttributesByKey,
                                                     completion))
        completion(stubbedPostReceiptPurchaserInfo, stubbedPostReceiptPurchaserError)
    }

    var invokedGetSubscriberData = false
    var invokedGetSubscriberDataCount = 0
    var invokedGetSubscriberDataParameters: (appUserID: String?, completion: BackendPurchaserInfoResponseHandler?)?
    var invokedGetSubscriberDataParametersList = [(appUserID: String?,
        completion: BackendPurchaserInfoResponseHandler?)]()

    var stubbedGetSubscriberDataPurchaserInfo: PurchaserInfo? = nil
    var stubbedGetSubscriberDataError: Error? = nil

    override func getSubscriberData(appUserID: String, completion: @escaping BackendPurchaserInfoResponseHandler) {
        invokedGetSubscriberData = true
        invokedGetSubscriberDataCount += 1
        invokedGetSubscriberDataParameters = (appUserID, completion)
        invokedGetSubscriberDataParametersList.append((appUserID, completion))
        completion(stubbedGetSubscriberDataPurchaserInfo, stubbedGetSubscriberDataError)
    }

    var invokedGetIntroEligibility = false
    var invokedGetIntroEligibilityCount = 0
    var invokedGetIntroEligibilityParameters: (appUserID: String?, receiptData: Data?, productIdentifiers: [String]?, completion: IntroEligibilityResponseHandler?)?
    var invokedGetIntroEligibilityParametersList = [(appUserID: String?,
        receiptData: Data?,
        productIdentifiers: [String]?,
        completion: IntroEligibilityResponseHandler?)]()

    override func getIntroEligibility(appUserID: String,
                                      receiptData: Data,
                                      productIdentifiers: [String],
                                      completion: @escaping IntroEligibilityResponseHandler) {
        invokedGetIntroEligibility = true
        invokedGetIntroEligibilityCount += 1
        invokedGetIntroEligibilityParameters = (appUserID, receiptData, productIdentifiers, completion)
        invokedGetIntroEligibilityParametersList.append((appUserID, receiptData, productIdentifiers, completion))
    }

    var invokedGetOfferingsForAppUserID = false
    var invokedGetOfferingsForAppUserIDCount = 0
    var invokedGetOfferingsForAppUserIDParameters: (appUserID: String?, completion: OfferingsResponseHandler?)?
    var invokedGetOfferingsForAppUserIDParametersList = [(appUserID: String?, completion: OfferingsResponseHandler?)]()
    var stubbedGetOfferingsCompletionResult: (data: [String: Any]?, error: Error?)?

    override func getOfferings(appUserID: String, completion: @escaping OfferingsResponseHandler) {
        invokedGetOfferingsForAppUserID = true
        invokedGetOfferingsForAppUserIDCount += 1
        invokedGetOfferingsForAppUserIDParameters = (appUserID, completion)
        invokedGetOfferingsForAppUserIDParametersList.append((appUserID, completion))

        completion(stubbedGetOfferingsCompletionResult?.data, stubbedGetOfferingsCompletionResult?.error)
    }

    var invokedPostAttributionData = false
    var invokedPostAttributionDataCount = 0
    var invokedPostAttributionDataParameters: (data: [String: Any]?, network: AttributionNetwork, appUserID: String?)?
    var invokedPostAttributionDataParametersList = [(data: [String: Any]?,
                                                     network: AttributionNetwork,
        appUserID: String?)]()
    var stubbedPostAttributionDataCompletionResult: (Error?, Void)?

    override func post(attributionData: [String : Any],
                       network: AttributionNetwork,
                       appUserID: String,
                       completion: ((Error?) -> Void)?) {
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
    var stubbedCreateAliasCompletionResult: (Error?, Void)?

    override func createAlias(appUserID: String, newAppUserID: String, completion: ((Error?) -> Void)?) {
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
    }

    var invokedPostSubscriberAttributes = false
    var invokedPostSubscriberAttributesCount = 0
    var invokedPostSubscriberAttributesParameters: (subscriberAttributes: [String: SubscriberAttribute]?, appUserID: String?)?
    var invokedPostSubscriberAttributesParametersList: [InvokedPostSubscriberAttributesParameters] = []
    var stubbedPostSubscriberAttributesCompletionResult: (Error?, Void)?

    override func post(subscriberAttributes: SubscriberAttributeDict,
                       appUserID: String,
                       completion: ((Error?) -> Void)?) {
        invokedPostSubscriberAttributes = true
        invokedPostSubscriberAttributesCount += 1
        invokedPostSubscriberAttributesParameters = (subscriberAttributes, appUserID)
        invokedPostSubscriberAttributesParametersList.append(
            InvokedPostSubscriberAttributesParameters(subscriberAttributes: subscriberAttributes, appUserID: appUserID)
        )
        if let result = stubbedPostSubscriberAttributesCompletionResult {
            completion?(result.0)
        } else {
            completion?(nil)
        }
    }

    struct InvokedPostSubscriberAttributesParameters: Equatable {
        let subscriberAttributes: [String: SubscriberAttribute]?
        let appUserID: String?
    }


    var invokedLogIn = false
    var invokedLogInCount = 0
    var invokedLogInParameters: (currentAppUserID: String, newAppUserID: String)?
    var invokedLogInParametersList = [(currentAppUserID: String, newAppUserID: String)]()
    var stubbedLogInCompletionResult: (PurchaserInfo?, Bool, Error?)?

    override func logIn(currentAppUserID: String,
                        newAppUserID: String,
                        completion: @escaping (PurchaserInfo?, Bool, Error?) -> Void) {
        invokedLogIn = true
        invokedLogInCount += 1
        invokedLogInParameters = (currentAppUserID, newAppUserID)
        invokedLogInParametersList.append((currentAppUserID, newAppUserID))
        if let result = stubbedLogInCompletionResult {
            completion(result.0, result.1, result.2)
        }
    }
}
