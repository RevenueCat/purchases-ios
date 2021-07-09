//
// Created by RevenueCat on 2/28/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockBackend: RCBackend {

    var invokedPostReceiptData = false
    var invokedPostReceiptDataCount = 0
    var stubbedPostReceiptPurchaserInfo: Purchases.PurchaserInfo? = nil
    var stubbedPostReceiptPurchaserError: Error? = nil
    var invokedPostReceiptDataParameters: (data: Data?,
                                           appUserID: String?,
                                           isRestore: Bool,
                                           productInfo: ProductInfo?,
                                           offeringIdentifier: String?,
                                           observerMode: Bool,
                                           subscriberAttributesByKey: [String: SubscriberAttribute]?,
                                           completion: RCBackendPurchaserInfoResponseHandler?)?
    var invokedPostReceiptDataParametersList = [(data: Data?,
        appUserID: String?,
        isRestore: Bool,
        productInfo: ProductInfo?,
        offeringIdentifier: String?,
        observerMode: Bool,
        subscriberAttributesByKey: [String: SubscriberAttribute]?,
        completion: RCBackendPurchaserInfoResponseHandler?)]()

    override func postReceiptData(_ data: Data,
                                  appUserID: String,
                                  isRestore: Bool,
                                  productInfo: ProductInfo?,
                                  presentedOfferingIdentifier offeringIdentifier: String?,
                                  observerMode: Bool,
                                  subscriberAttributes subscriberAttributesByKey: [String: SubscriberAttribute]?,
                                  completion: @escaping RCBackendPurchaserInfoResponseHandler) {
        invokedPostReceiptData = true
        invokedPostReceiptDataCount += 1
        invokedPostReceiptDataParameters = (data,
            appUserID,
            isRestore,
            productInfo,
            offeringIdentifier,
            observerMode,
            subscriberAttributesByKey,
            completion)
        invokedPostReceiptDataParametersList.append((data,
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
    var invokedGetSubscriberDataParameters: (appUserID: String?, completion: RCBackendPurchaserInfoResponseHandler?)?
    var invokedGetSubscriberDataParametersList = [(appUserID: String?,
        completion: RCBackendPurchaserInfoResponseHandler?)]()

    var stubbedGetSubscriberDataPurchaserInfo: Purchases.PurchaserInfo? = nil
    var stubbedGetSubscriberDataError: Error? = nil


    override func getSubscriberData(withAppUserID appUserID: String,
                                    completion: @escaping RCBackendPurchaserInfoResponseHandler) {
        invokedGetSubscriberData = true
        invokedGetSubscriberDataCount += 1
        invokedGetSubscriberDataParameters = (appUserID, completion)
        invokedGetSubscriberDataParametersList.append((appUserID, completion))
        completion(stubbedGetSubscriberDataPurchaserInfo, stubbedGetSubscriberDataError)
    }

    var invokedGetIntroEligibility = false
    var invokedGetIntroEligibilityCount = 0
    var invokedGetIntroEligibilityParameters: (appUserID: String?, receiptData: Data?, productIdentifiers: [String]?, completion: RCIntroEligibilityResponseHandler?)?
    var invokedGetIntroEligibilityParametersList = [(appUserID: String?,
        receiptData: Data?,
        productIdentifiers: [String]?,
        completion: RCIntroEligibilityResponseHandler?)]()

    override func getIntroEligibility(forAppUserID appUserID: String,
                                      receiptData: Data,
                                      productIdentifiers: [String],
                                      completion: @escaping RCIntroEligibilityResponseHandler) {
        invokedGetIntroEligibility = true
        invokedGetIntroEligibilityCount += 1
        invokedGetIntroEligibilityParameters = (appUserID, receiptData, productIdentifiers, completion)
        invokedGetIntroEligibilityParametersList.append((appUserID, receiptData, productIdentifiers, completion))
    }

    var invokedGetOfferingsForAppUserID = false
    var invokedGetOfferingsForAppUserIDCount = 0
    var invokedGetOfferingsForAppUserIDParameters: (appUserID: String?, completion: RCOfferingsResponseHandler?)?
    var invokedGetOfferingsForAppUserIDParametersList = [(appUserID: String?,
        completion: RCOfferingsResponseHandler?)]()

    override func getOfferingsForAppUserID(_ appUserID: String,
                                           completion: @escaping RCOfferingsResponseHandler) {
        invokedGetOfferingsForAppUserID = true
        invokedGetOfferingsForAppUserIDCount += 1
        invokedGetOfferingsForAppUserIDParameters = (appUserID, completion)
        invokedGetOfferingsForAppUserIDParametersList.append((appUserID, completion))
    }

    var invokedPostAttributionData = false
    var invokedPostAttributionDataCount = 0
    var invokedPostAttributionDataParameters: (data: [AnyHashable: Any]?, network: AttributionNetwork, appUserID: String?)?
    var invokedPostAttributionDataParametersList = [(data: [AnyHashable: Any]?,
                                                     network: AttributionNetwork,
        appUserID: String?)]()
    var stubbedPostAttributionDataCompletionResult: (Error?, Void)?

    override func postAttributionData(_ data: [AnyHashable: Any],
                                      from network: AttributionNetwork,
                                      forAppUserID appUserID: String,
                                      completion: ((Error?) -> ())?) {
        invokedPostAttributionData = true
        invokedPostAttributionDataCount += 1
        invokedPostAttributionDataParameters = (data, network, appUserID)
        invokedPostAttributionDataParametersList.append((data, network, appUserID))
        if let result = stubbedPostAttributionDataCompletionResult {
            completion?(result.0)
        }
    }

    var invokedCreateAlias = false
    var invokedCreateAliasCount = 0
    var invokedCreateAliasParameters: (appUserID: String?, newAppUserID: String?)?
    var invokedCreateAliasParametersList = [(appUserID: String?, newAppUserID: String?)]()
    var stubbedCreateAliasCompletionResult: (Error?, Void)?

    override func createAlias(forAppUserID appUserID: String,
                              withNewAppUserID newAppUserID: String,
                              completion: ((Error?) -> ())?) {
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
    var invokedPostOfferParameters: (offerIdentifier: String?, productIdentifier: String?, subscriptionGroup: String?, data: Data?, applicationUsername: String?, completion: RCOfferSigningResponseHandler?)?
    var invokedPostOfferParametersList = [(offerIdentifier: String?,
        productIdentifier: String?,
        subscriptionGroup: String?,
        data: Data?,
        applicationUsername: String?,
        completion: RCOfferSigningResponseHandler?)]()

    override func postOffer(forSigning offerIdentifier: String,
                            withProductIdentifier productIdentifier: String,
                            subscriptionGroup: String,
                            receiptData data: Data,
                            appUserID applicationUsername: String,
                            completion: @escaping RCOfferSigningResponseHandler) {
        invokedPostOffer = true
        invokedPostOfferCount += 1
        invokedPostOfferParameters = (offerIdentifier,
            productIdentifier,
            subscriptionGroup,
            data,
            applicationUsername,
            completion)
        invokedPostOfferParametersList.append((offerIdentifier,
                                                  productIdentifier,
                                                  subscriptionGroup,
                                                  data,
                                                  applicationUsername,
                                                  completion))
    }

    var invokedPostSubscriberAttributes = false
    var invokedPostSubscriberAttributesCount = 0
    var invokedPostSubscriberAttributesParameters: (subscriberAttributes: [String: SubscriberAttribute]?, appUserID: String?)?
    var invokedPostSubscriberAttributesParametersList: [InvokedPostSubscriberAttributesParameters] = []
    var stubbedPostSubscriberAttributesCompletionResult: (Error?, Void)?

    override func postSubscriberAttributes(_ subscriberAttributes: [String: SubscriberAttribute],
                                           appUserID: String,
                                           completion: ((Error?) -> ())?) {
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
    var stubbedLogInCompletionResult: (Purchases.PurchaserInfo?, Bool, Error?)?

    override func logIn(withCurrentAppUserID currentAppUserID: String,
                        newAppUserID: String,
                        completion: @escaping (Purchases.PurchaserInfo?, Bool, Error?) -> ()) {
        invokedLogIn = true
        invokedLogInCount += 1
        invokedLogInParameters = (currentAppUserID, newAppUserID)
        invokedLogInParametersList.append((currentAppUserID, newAppUserID))
        if let result = stubbedLogInCompletionResult {
            completion(result.0, result.1, result.2)
        }
    }
}
