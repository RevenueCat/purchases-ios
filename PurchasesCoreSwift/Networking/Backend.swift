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

public class PurchaserInfo: NSObject {
    init(data: NSDictionary) { }
    init?(data: [String: Any]?) { }
}

public typealias SubscriberAttributeDict = [String: SubscriberAttribute]
public typealias BackendPurchaserInfoResponseHandler = (PurchaserInfo?, Error?) -> Void
public typealias IntroEligibilityResponseHandler = ([String: IntroEligibility]) -> Void
public typealias OfferingsResponseHandler = ([String: Any]?, Error?) -> Void
public typealias OfferSigningResponseHandler = (String?, String?, UUID?, NSNumber?, Error?) -> Void

// swiftlint:disable type_body_length file_length
// TODO(post-migration): Make this internal again, and all the other things too
@objc(RCBackend) public class Backend: NSObject {

    @objc public static let RCSuccessfullySyncedKey: NSError.UserInfoKey = "rc_successfullySynced"
    @objc static let RCAttributeErrorsKey = "attribute_errors"
    static let RCAttributeErrorsResponseKey = "attributes_error_response"

    private let httpClient: HTTPClient
    private let apiKey: String

    // callbackQueue controls access to both offeringsCallbacksCache and purchaserInfoCallbacksCache
    private let callbackQueue = DispatchQueue(label: "Backend callbackQueue")
    private var offeringsCallbacksCache: [String: [OfferingsResponseHandler]]
    private var purchaserInfoCallbacksCache: [String: [BackendPurchaserInfoResponseHandler]]

    private var authHeaders: [String: String] { return ["Authorization": "Bearer \(self.apiKey)"] }

    @objc public convenience init(apiKey: String,
                                  systemInfo: SystemInfo,
                                  eTagManager: ETagManager,
                                  operationDispatcher: OperationDispatcher) {
        let httpClient = HTTPClient(systemInfo: systemInfo,
                                    eTagManager: eTagManager,
                                    operationDispatcher: operationDispatcher)
        self.init(httpClient: httpClient, apiKey: apiKey)
    }

    @objc public required init(httpClient: HTTPClient, apiKey: String) {
        self.httpClient = httpClient
        self.apiKey = apiKey
        self.offeringsCallbacksCache = [:]
        self.purchaserInfoCallbacksCache = [:]
    }

    @objc(createAliasForAppUserID:newAppUserID:completion:)
    public func createAlias(appUserID: String, newAppUserID: String, completion: ((Error?) -> Void)?) {
        let escapedAppUserID = escapedAppUserID(appUserID: appUserID)
        let path = "/subscribers/\(escapedAppUserID)/alias"
        httpClient.performPOSTRequest(serially: true,
                                      path: path,
                                      requestBody: ["new_app_user_id": newAppUserID],
                                      headers: authHeaders) { statusCode, response, error in
            self.handle(response: response, statusCode: statusCode, error: error, completion: completion)
        }
    }

    @objc public func clearCaches() {
        httpClient.clearCaches()
    }

    // swiftlint:disable function_parameter_count
    @objc (postReceiptData:appUserID:isRestore:productInfo:presentedOfferingIdentifier:observerMode:subscriberAttributes:completion:)
    public func postReceiptData(data: Data,
                                appUserID: String,
                                isRestore: Bool,
                                productInfo: ProductInfo?,
                                presentedOfferingIdentifier offeringIdentifier: String?,
                                observerMode: Bool,
                                subscriberAttributes subscriberAttributesByKey: SubscriberAttributeDict?,
                                completion: @escaping BackendPurchaserInfoResponseHandler) {
    // swiftlint:enable function_parameter_count
        let fetchToken = data.base64EncodedString(options: .lineLength64Characters)
        var body: [String: AnyObject] = [
            "fetch_token": fetchToken as NSString,
            "app_user_id": appUserID as NSString,
            "is_restore": NSNumber(value: isRestore),
            "observer_mode": NSNumber(value: observerMode),
        ]

        let cacheKey =
        """
        \(appUserID)-\(isRestore)-\(fetchToken)-\(productInfo?.cacheKey ?? "")
        -\(offeringIdentifier ?? "")-\(observerMode)-\(subscriberAttributesByKey?.debugDescription ?? "")"
        """

        if add(callback: completion, key: cacheKey) {
            return
        }

        if let productInfo = productInfo {
            body.merge(productInfo.asDictionary()) { _, new in new }
        }

        if let subscriberAttributesByKey = subscriberAttributesByKey {

            let attributesInBackendFormat = subscriberAttributesToDict(subscriberAttributes: subscriberAttributesByKey)
            body["attributes"] = attributesInBackendFormat as AnyObject
        }

        if let offeringIdentifier = offeringIdentifier {
            body["presented_offering_identifier"] = offeringIdentifier as NSString
        }

        httpClient.performPOSTRequest(serially: true,
                                      path: "/receipts",
                                      requestBody: body,
                                      headers: authHeaders) { statusCode, response, error in
            let callbacks = self.getPurchaserInfoCallbacksAndClearCache(forKey: cacheKey)
            for callback in callbacks {
                self.handle(purchaserInfoResponse: response, statusCode: statusCode, error: error, completion: callback)
            }
        }
    }

    @objc
    public func getSubscriberData(appUserID: String, completion: @escaping BackendPurchaserInfoResponseHandler) {
        let escapedAppUserID = escapedAppUserID(appUserID: appUserID)
        let path = "/subscribers/\(escapedAppUserID)"

        if add(callback: completion, key: path) {
            return
        }

        httpClient.performGETRequest(serially: true, path: path, headers: authHeaders) { statusCode, response, error in
            for completion in self.getPurchaserInfoCallbacksAndClearCache(forKey: path) {
                self.handle(purchaserInfoResponse: response,
                            statusCode: statusCode,
                            error: error,
                            completion: completion)
            }
        }
    }

    // swiftlint:disable function_parameter_count
    @objc(postOfferForSigning:withProductIdentifier:subscriptionGroup:receiptData:appUserID:completion:)
    public func postOfferForSigning(_ offerIdentifier: String,
                                    productIdentifier: String,
                                    subscriptionGroup: String,
                                    receiptData: Data,
                                    appUserID: String,
                                    completion: @escaping OfferSigningResponseHandler) {
    // swiftlint:enable function_parameter_count
        let fetchToken = receiptData.base64EncodedString(options: .lineLength64Characters)

        let requestBody: [String: Any] = ["app_user_id": appUserID,
                                          "fetch_token": fetchToken,
                                          "generate_offers": [
                                            ["offer_id": offerIdentifier,
                                             "product_id": productIdentifier,
                                             "subscription_group": subscriptionGroup
                                            ]
                                          ]]

        self.httpClient.performPOSTRequest(serially: true, path: "/offers",
                                           requestBody: requestBody,
                                           headers: authHeaders) { statusCode, response, error in
            if let error = error {
                completion(nil, nil, nil, nil, ErrorUtils.networkError(withUnderlyingError: error))
                return
            }

            guard statusCode < HTTPStatusCodes.redirect.rawValue else {
                let code = response?["code"] as? NSNumber
                let backendMessage = response?["message"] as? String
                let error = ErrorUtils.backendError(withBackendCode: code, backendMessage: backendMessage)
                completion(nil, nil, nil, nil, error)
                return
            }

            guard let offers = response?["offers"] as? [[String: AnyObject]], offers.count > 0 else {
                completion(nil, nil, nil, nil, ErrorUtils.unexpectedBackendResponseError())
                return
            }

            let offer = offers[0]
            if let signatureError = offer["signature_error"] as? [String: AnyObject] {
                let code = signatureError["code"] as? NSNumber
                let backendMessage = signatureError["message"] as? String
                let error = ErrorUtils.backendError(withBackendCode: code, backendMessage: backendMessage)
                completion(nil, nil, nil, nil, error)

            } else if let signatureData = offer["signature_data"] as? [String: AnyObject] {
                let signature = signatureData["signature"] as? String
                let keyIdentifier = offer["key_id"] as? String
                let nonceString = signatureData["nonce"] as? String
                let nonce: UUID?
                if let nonceString = nonceString {
                    nonce = UUID(uuidString: nonceString)
                } else {
                    nonce = nil
                }

                let timestamp = signatureData["timestamp"] as? NSNumber

                completion(signature, keyIdentifier, nonce, timestamp, nil)
                return
            } else {
                completion(nil, nil, nil, nil, ErrorUtils.unexpectedBackendResponseError())
                return
            }
        }
    }

    @objc public func post(attributionData: [String: AnyObject],
                           network: AttributionNetwork,
                           appUserID: String,
                           completion: ((Error?) -> Void)?) {
        let escapedAppUserID =  escapedAppUserID(appUserID: appUserID)
        let path = "/subscribers/\(escapedAppUserID)/attribution"
        let body: [String: Any] = ["network": NSNumber(value: network.rawValue), "data": attributionData]
        httpClient.performPOSTRequest(serially: true,
                                      path: path,
                                      requestBody: body,
                                      headers: authHeaders) { statusCode, response, error in
            self.handle(response: response, statusCode: statusCode, error: error, completion: completion)
        }
    }

    @objc public func post(subscriberAttributes: SubscriberAttributeDict,
                           appUserID: String,
                           completion: ((Error?) -> Void)?) {
        guard subscriberAttributes.count > 0 else {
            Logger.warn(Strings.attribution.empty_subscriber_attributes)
            return
        }

        let escapedAppUserID = escapedAppUserID(appUserID: appUserID)
        let path = "/subscribers/\(escapedAppUserID)/attributes"

        let attributesInBackendFormat = subscriberAttributesToDict(subscriberAttributes: subscriberAttributes)
        httpClient.performPOSTRequest(serially: true,
                                      path: path,
                                      requestBody: ["attributes": attributesInBackendFormat],
                                      headers: authHeaders) { statusCode, response, error in
            self.handle(response: response, statusCode: statusCode, error: error, completion: completion)
        }
    }

    @objc public func logIn(currentAppUserID: String,
                            newAppUserID: String,
                            completion: @escaping (PurchaserInfo?, Bool, Error?) -> Void) {

        let requestBody = ["app_user_id": currentAppUserID, "new_app_user_id": newAppUserID]
        httpClient.performPOSTRequest(serially: true,
                                      path: "/subscribers/identify",
                                      requestBody: requestBody,
                                      headers: authHeaders) { statusCode, response, error in

            self.handleLogin(response: response, statusCode: statusCode, error: error, completion: completion)
        }
    }

    @objc(getOfferingsForAppUserID:completion:)
    public func getOfferings(appUserID: String, completion: @escaping OfferingsResponseHandler) {
        let trimmedAppUserID = appUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedAppUserID.count > 0 else {
            Logger.warn("called getOfferings with an empty appUserID!")
            completion(nil, ErrorUtils.missingAppUserIDError())
            return
        }

        let escapedAppUserID = escapedAppUserID(appUserID: trimmedAppUserID)
        let path = "/subscribers/\(escapedAppUserID)/offerings"
        if add(callback: completion, key: path) {
            return
        }

        httpClient.performGETRequest(serially: false, path: path, headers: authHeaders) { statusCode, response, error in
            if error == nil && statusCode < HTTPStatusCodes.redirect.rawValue {
                for callback in self.getOfferingsCallbacksAndClearCache(forKey: path) {
                    callback(response, nil)
                }
                return
            }

            let errorForCallbacks: Error
            if let error = error {
                errorForCallbacks = ErrorUtils.networkError(withUnderlyingError: error)
            } else if statusCode > HTTPStatusCodes.redirect.rawValue {
                let backendCode = response?["code"] as? NSNumber
                let backendMessage = response?["message"] as? String
                errorForCallbacks = ErrorUtils.backendError(withBackendCode: backendCode,
                                                            backendMessage: backendMessage)
            } else {
                errorForCallbacks = ErrorUtils.unexpectedBackendResponseError()
            }

            for callback in self.getOfferingsCallbacksAndClearCache(forKey: path) {
                callback(nil, errorForCallbacks)
            }
        }
    }

    @objc(getIntroEligibilityForAppUserID:receiptData:productIdentifiers:completion:)
    public func getIntroEligibility(appUserID: String,
                                    receiptData: Data,
                                    productIdentifiers: [String],
                                    completion: @escaping IntroEligibilityResponseHandler) {
        guard productIdentifiers.count > 0 else {
            completion([:])
            return
        }

        if receiptData.count == 0 {
            if SystemInfo.isSandbox {
                Logger.appleWarning(Strings.receipt.no_sandbox_receipt_intro_eligibility)
            }

            var eligibilities: [String: IntroEligibility] = [:]

            for productID in productIdentifiers {
                eligibilities[productID] = IntroEligibility(eligibilityStatus: .unknown)
            }

            completion(eligibilities)
            return
        }

        let fetchToken = receiptData.base64EncodedString(options: .lineLength64Characters)
        let escapedAppUserID = escapedAppUserID(appUserID: appUserID)
        let path = "/subscribers/\(escapedAppUserID)/intro_eligibility"
        let body: [String: Any] = ["product_identifiers": productIdentifiers,
                                   "fetch_token": fetchToken]

        httpClient.performPOSTRequest(serially: true,
                                      path: path,
                                      requestBody: body,
                                      headers: authHeaders) { statusCode, theResponse, error in
            var response = theResponse
            if statusCode >= HTTPStatusCodes.redirect.rawValue || error != nil {
                response = [:]
            }

            guard let response = response else {
                // missing response, we don't know eligibility for any of the identifiers.
                let unknownEligibilities = [IntroEligibility](repeating: IntroEligibility(eligibilityStatus: .unknown),
                                                              count: productIdentifiers.count)
                let productIdentifiersToEligibility = zip(productIdentifiers, unknownEligibilities)
                completion(Dictionary(uniqueKeysWithValues: productIdentifiersToEligibility))
                return
            }

            var eligibilities: [String: IntroEligibility] = [:]
            for productID in productIdentifiers {
                let status: IntroEligibilityStatus

                if let e = response[productID] as? NSNumber {
                    status = e.boolValue ? .eligible : .ineligible
                } else {
                    status = .unknown
                }

                eligibilities[productID] = IntroEligibility(eligibilityStatus: status)

            }
            completion(eligibilities)
        }
    }

    private func handleLogin(response: [String: Any]?,
                             statusCode: Int,
                             error: Error?,
                             completion: (PurchaserInfo?, Bool, Error?) -> Void ) {
        if let error = error {
            completion(nil, false, ErrorUtils.networkError(withUnderlyingError: error))
            return
        }

        if statusCode > HTTPStatusCodes.redirect.rawValue {
            let backendCode = response?["code"] as? NSNumber
            let backendMessage = response?["message"] as? String
            let responsError = ErrorUtils.backendError(withBackendCode: backendCode, backendMessage: backendMessage)
            completion(nil, false, ErrorUtils.networkError(withUnderlyingError: responsError))
            return
        }

        guard let purchaserInfo = PurchaserInfo(data: (response as [String: AnyObject]?)) else {
            let responseError = ErrorUtils.unexpectedBackendResponseError()
            completion(nil, false, responseError)
            return
        }

        let created = statusCode == 201
        completion(purchaserInfo, created, nil)
    }

    private func attributesUserInfoFromResponse(response: [String: Any], statusCode: Int) -> [String: AnyObject] {
        var resultDict: [String: AnyObject] = [:]
        let isInternalServerError = statusCode >= HTTPStatusCodes.internalServerError.rawValue
        let isNotFoundError = statusCode == HTTPStatusCodes.notFoundError.rawValue

        let successfullySynced = !(isInternalServerError || isNotFoundError)
        resultDict[Backend.RCSuccessfullySyncedKey as String] = NSNumber(value: successfullySynced)

        let hasAttributesResponseContainerKey = (response[Backend.RCAttributeErrorsResponseKey] != nil)
        let attributesResponseDict = hasAttributesResponseContainerKey
            ? response[Backend.RCAttributeErrorsResponseKey]
            : response

        if let attributesResponseDict = attributesResponseDict as? [String: Any] {
            let hasAttributeErrors = (attributesResponseDict[Backend.RCAttributeErrorsKey] != nil)
            if hasAttributeErrors {
                resultDict[Backend.RCAttributeErrorsKey] = attributesResponseDict[Backend.RCAttributeErrorsKey] as AnyObject
            }
        }
        return resultDict
    }

    private func handle(response: [String: Any]?, statusCode: Int, error: Error?, completion: ((Error?) -> Void)?) {
        if let error = error {
            completion?(ErrorUtils.networkError(withUnderlyingError: error))
            return
        }

        if statusCode > HTTPStatusCodes.redirect.rawValue {
            let code = response?["code"] as? NSNumber
            let message = response?["message"] as? String
            let responseError = ErrorUtils.backendError(withBackendCode: code, backendMessage: message)
            completion?(responseError)
            return
        } else {
            completion?(nil)
        }
    }

    private func handle(purchaserInfoResponse response: [String: Any]?,
                        statusCode: Int,
                        error: Error?,
                        completion: BackendPurchaserInfoResponseHandler) {
        if let error = error {
            completion(nil, ErrorUtils.networkError(withUnderlyingError: error))
            return
        }

        let isErrorStatusCode = statusCode >= HTTPStatusCodes.redirect.rawValue

        let maybePurchaserInfo: PurchaserInfo? = PurchaserInfo(data: response)
        if !isErrorStatusCode && maybePurchaserInfo == nil {
            completion(nil, ErrorUtils.unexpectedBackendResponseError())
            return
        }

        let subscriberAttributesErrorInfo = attributesUserInfoFromResponse(response: response ?? [:],
                                                                           statusCode: statusCode)

        let hasError = (isErrorStatusCode || subscriberAttributesErrorInfo[Backend.RCAttributeErrorsKey] != nil)

        if hasError {
            let finishable = statusCode < HTTPStatusCodes.internalServerError.rawValue
            var extraUserInfo = [ErrorDetails.finishableKey: NSNumber(value: finishable)] as [String: AnyObject]
            extraUserInfo.merge(subscriberAttributesErrorInfo) { _, new in new }
            let code = response?["code"] as? NSNumber
            let message = response?["message"] as? String
            let responseError = ErrorUtils.backendError(withBackendCode: code,
                                                        backendMessage: message,
                                                        extraUserInfo: extraUserInfo as [NSError.UserInfoKey: Any])
            completion(maybePurchaserInfo, responseError)
            return
        } else {
            completion(maybePurchaserInfo, nil)
            return
        }
    }

    private func escapedAppUserID(appUserID: String) -> String {
        return appUserID.addingPercentEncoding(withAllowedCharacters: NSMutableCharacterSet.urlHostAllowed)!
    }

    private func subscriberAttributesToDict(subscriberAttributes: SubscriberAttributeDict) -> [String: AnyObject] {
        var attributesByKey: [String: AnyObject] = [:]
        for (key, value) in subscriberAttributes {
            attributesByKey[key] = value.asBackendDictionary() as AnyObject
        }
        return attributesByKey
    }

    private func userInfoAttributes(response: [String: AnyObject], statusCode: Int) -> [String: AnyObject] {
        var resultDict: [String: AnyObject] = [:]

        let isInternalServerError = statusCode >= HTTPStatusCodes.internalServerError.rawValue
        let isNotFoundError = statusCode == HTTPStatusCodes.notFoundError.rawValue
        let successfullySynced = !(isInternalServerError || isNotFoundError)
        resultDict[Backend.RCSuccessfullySyncedKey as String] = NSNumber(value: successfullySynced)

        let hasAttributesResponseContainerKey = (response[Backend.RCAttributeErrorsResponseKey] != nil)
        let maybeAttributesResponseDict = hasAttributesResponseContainerKey
            ? response[Backend.RCAttributeErrorsResponseKey] as? [String: AnyObject]
            : response

        if let attributesResponseDict = maybeAttributesResponseDict {
            resultDict[Backend.RCAttributeErrorsKey] = attributesResponseDict[Backend.RCAttributeErrorsKey]
        }

        return resultDict
    }

    // MARK: Callback cache management

    private func add(callback: @escaping BackendPurchaserInfoResponseHandler, key: String) -> Bool {
        return callbackQueue.sync { [self] in
            let maybeCallbacks = purchaserInfoCallbacksCache[key]
            var callbacks: [BackendPurchaserInfoResponseHandler]
            let requestAlreadyInFlight: Bool
            if maybeCallbacks == nil {
                requestAlreadyInFlight = false
                callbacks = []
                purchaserInfoCallbacksCache[key] = callbacks
            } else {
                requestAlreadyInFlight = true
                callbacks = maybeCallbacks!
            }
            callbacks.append(callback)
            return requestAlreadyInFlight
        }
    }

    private func add(callback: @escaping OfferingsResponseHandler, key: String) -> Bool {
        return callbackQueue.sync { [self] in
            let maybeCallbacks = offeringsCallbacksCache[key]
            var callbacks: [OfferingsResponseHandler]
            let requestAlreadyInFlight: Bool
            if maybeCallbacks == nil {
                requestAlreadyInFlight = false
                callbacks = []
                offeringsCallbacksCache[key] = callbacks
            } else {
                requestAlreadyInFlight = true
                callbacks = maybeCallbacks!
            }
            callbacks.append(callback)
            return requestAlreadyInFlight
        }
    }

    private func getOfferingsCallbacksAndClearCache(forKey key: String) -> [OfferingsResponseHandler] {
        return callbackQueue.sync { [self] in
            let callbacks = offeringsCallbacksCache.removeValue(forKey: key)
            // TODO: Should we throw instead of NSParameterAssert?
            assert(callbacks != nil)
            return callbacks ?? []
        }
    }

    private func getPurchaserInfoCallbacksAndClearCache(forKey key: String) -> [BackendPurchaserInfoResponseHandler] {
        return callbackQueue.sync { [self] in
            let callbacks = purchaserInfoCallbacksCache.removeValue(forKey: key)
            // TODO: Should we throw instead of NSParameterAssert?
            assert(callbacks != nil)
            return callbacks ?? []
        }
    }

}
// swiftlint:enable type_body_length file_length
