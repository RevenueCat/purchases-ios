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
typealias BackendPurchaserInfoResponseHandler = (PurchaserInfo?, Error?) -> Void
typealias IntroEligibilityResponseHandler = ([String: IntroEligibility], Error?) -> Void
typealias OfferingsResponseHandler = ([String: Any]?, Error?) -> Void
typealias OfferSigningResponseHandler = (String?, String?, UUID?, NSNumber?, Error?) -> Void

// swiftlint:disable type_body_length file_length
class Backend {

    static let RCSuccessfullySyncedKey: NSError.UserInfoKey = "rc_successfullySynced"
    static let RCAttributeErrorsKey = "attribute_errors"
    static let RCAttributeErrorsResponseKey = "attributes_error_response"

    private let httpClient: HTTPClient
    private let apiKey: String

    // callbackQueue controls access to both offeringsCallbacksCache and purchaserInfoCallbacksCache
    private let callbackQueue = DispatchQueue(label: "Backend callbackQueue")
    private var offeringsCallbacksCache: [String: [OfferingsResponseHandler]]
    private var purchaserInfoCallbacksCache: [String: [BackendPurchaserInfoResponseHandler]]

    private var authHeaders: [String: String] { return ["Authorization": "Bearer \(self.apiKey)"] }

    convenience init(apiKey: String,
                     systemInfo: SystemInfo,
                     eTagManager: ETagManager,
                     operationDispatcher: OperationDispatcher) {
        let httpClient = HTTPClient(systemInfo: systemInfo, eTagManager: eTagManager)
        self.init(httpClient: httpClient, apiKey: apiKey)
    }

    required init(httpClient: HTTPClient, apiKey: String) {
        self.httpClient = httpClient
        self.apiKey = apiKey
        self.offeringsCallbacksCache = [:]
        self.purchaserInfoCallbacksCache = [:]
    }

    func createAlias(appUserID: String, newAppUserID: String, completion: ((Error?) -> Void)?) {
        guard let appUserID = try? escapedAppUserID(appUserID: appUserID) else {
            completion?(ErrorUtils.missingAppUserIDError())
            return
        }

        let path = "/subscribers/\(appUserID)/alias"
        Logger.user(Strings.identity.creating_alias(userA: appUserID, userB: newAppUserID))
        httpClient.performPOSTRequest(serially: true,
                                      path: path,
                                      requestBody: ["new_app_user_id": newAppUserID],
                                      headers: authHeaders) { statusCode, response, error in
            self.handle(response: response, statusCode: statusCode, error: error, completion: completion)
        }
    }

    func clearCaches() {
        httpClient.clearCaches()
    }

    // swiftlint:disable function_parameter_count
    func post(receiptData: Data,
              appUserID: String,
              isRestore: Bool,
              productInfo: ProductInfo?,
              presentedOfferingIdentifier offeringIdentifier: String?,
              observerMode: Bool,
              subscriberAttributes subscriberAttributesByKey: SubscriberAttributeDict?,
              completion: @escaping BackendPurchaserInfoResponseHandler) {
        // swiftlint:enable function_parameter_count
        let fetchToken = receiptData.asFetchToken
        var body: [String: Any] = [
            "fetch_token": fetchToken,
            "app_user_id": appUserID,
            "is_restore": isRestore,
            "observer_mode": observerMode
        ]

        let cacheKey =
        """
        \(appUserID)-\(isRestore)-\(fetchToken)-\(productInfo?.cacheKey ?? "")
        -\(offeringIdentifier ?? "")-\(observerMode)-\(subscriberAttributesByKey?.debugDescription ?? "")"
        """

        if add(callback: completion, key: cacheKey) == .addedToExistingInFlightList {
            return
        }

        if let productInfo = productInfo {
            body.merge(productInfo.asDictionary()) { _, new in new }
        }

        if let subscriberAttributesByKey = subscriberAttributesByKey {
            let attributesInBackendFormat = subscriberAttributesToDict(subscriberAttributes: subscriberAttributesByKey)
            body["attributes"] = attributesInBackendFormat
        }

        if let offeringIdentifier = offeringIdentifier {
            body["presented_offering_identifier"] = offeringIdentifier
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

    func getSubscriberData(appUserID: String, completion: @escaping BackendPurchaserInfoResponseHandler) {
        guard let appUserID = try? escapedAppUserID(appUserID: appUserID) else {
            completion(nil, ErrorUtils.missingAppUserIDError())
            return
        }

        let path = "/subscribers/\(appUserID)"

        if add(callback: completion, key: path) == .addedToExistingInFlightList {
            return
        }

        httpClient.performGETRequest(serially: true,
                                     path: path,
                                     headers: authHeaders) {  [weak self] (statusCode, response, error) in
            guard let self = self else {
                return
            }

            for completion in self.getPurchaserInfoCallbacksAndClearCache(forKey: path) {
                self.handle(purchaserInfoResponse: response,
                            statusCode: statusCode,
                            error: error,
                            completion: completion)
            }
        }
    }

    // swiftlint:disable function_parameter_count function_body_length
    func post(offerIdForSigning offerIdentifier: String,
              productIdentifier: String,
              subscriptionGroup: String,
              receiptData: Data,
              appUserID: String,
              completion: @escaping OfferSigningResponseHandler) {
    // swiftlint:enable function_parameter_count function_body_length
        let fetchToken = receiptData.asFetchToken

        let requestBody: [String: Any] = ["app_user_id": appUserID,
                                          "fetch_token": fetchToken,
                                          "generate_offers": [
                                            ["offer_id": offerIdentifier,
                                             "product_id": productIdentifier,
                                             "subscription_group": subscriptionGroup
                                            ]
                                          ]]

        self.httpClient.performPOSTRequest(serially: true,
                                           path: "/offers",
                                           requestBody: requestBody,
                                           headers: authHeaders) { statusCode, response, error in
            if let error = error {
                completion(nil, nil, nil, nil, ErrorUtils.networkError(withUnderlyingError: error))
                return
            }

            guard statusCode < HTTPStatusCodes.redirect.rawValue else {
                let code = self.maybeNumberFromError(code: response?["code"])
                let backendMessage = response?["message"] as? String
                let error = ErrorUtils.backendError(withBackendCode: code as NSNumber?, backendMessage: backendMessage)
                completion(nil, nil, nil, nil, error)
                return
            }

            guard let offers = response?["offers"] as? [[String: Any]], offers.count > 0 else {
                completion(nil, nil, nil, nil, ErrorUtils.unexpectedBackendResponseError())
                return
            }

            let offer = offers[0]
            if let signatureError = offer["signature_error"] as? [String: Any] {
                let code = self.maybeNumberFromError(code: signatureError["code"])
                let backendMessage = signatureError["message"] as? String
                let error = ErrorUtils.backendError(withBackendCode: code as NSNumber?, backendMessage: backendMessage)
                completion(nil, nil, nil, nil, error)

            } else if let signatureData = offer["signature_data"] as? [String: Any] {
                let signature = signatureData["signature"] as? String
                let keyIdentifier = offer["key_id"] as? String
                let nonceString = signatureData["nonce"] as? String
                let maybeNonce: UUID?
                if let nonceString = nonceString {
                    maybeNonce = UUID(uuidString: nonceString)
                } else {
                    maybeNonce = nil
                }

                let timestamp = signatureData["timestamp"] as? Int

                completion(signature, keyIdentifier, maybeNonce, timestamp as NSNumber?, nil)
                return
            } else {
                completion(nil, nil, nil, nil, ErrorUtils.unexpectedBackendResponseError())
                return
            }
        }
    }

    func post(attributionData: [String: Any],
              network: AttributionNetwork,
              appUserID: String,
              completion: ((Error?) -> Void)?) {
        guard let appUserID = try? escapedAppUserID(appUserID: appUserID) else {
            completion?(ErrorUtils.missingAppUserIDError())
            return
        }

        let path = "/subscribers/\(appUserID)/attribution"
        let body: [String: Any] = ["network": network.rawValue, "data": attributionData]
        httpClient.performPOSTRequest(serially: true,
                                      path: path,
                                      requestBody: body,
                                      headers: authHeaders) { statusCode, response, error in
            self.handle(response: response, statusCode: statusCode, error: error, completion: completion)
        }
    }

    func post(subscriberAttributes: SubscriberAttributeDict,
              appUserID: String,
              completion: ((Error?) -> Void)?) {
        guard subscriberAttributes.count > 0 else {
            Logger.warn(Strings.attribution.empty_subscriber_attributes)
            completion?(ErrorCode.emptySubscriberAttributes)
            return
        }

        guard let appUserID = try? escapedAppUserID(appUserID: appUserID) else {
            completion?(ErrorUtils.missingAppUserIDError())
            return
        }

        let path = "/subscribers/\(appUserID)/attributes"

        let attributesInBackendFormat = subscriberAttributesToDict(subscriberAttributes: subscriberAttributes)
        httpClient.performPOSTRequest(serially: true,
                                      path: path,
                                      requestBody: ["attributes": attributesInBackendFormat],
                                      headers: authHeaders) { statusCode, response, error in
            self.handleSubscribedAttributesResult(statusCode: statusCode,
                                                  response: response,
                                                  error: error,
                                                  completion: completion)
        }
    }

    func logIn(currentAppUserID: String,
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

    func getOfferings(appUserID: String, completion: @escaping OfferingsResponseHandler) {
        guard let appUserID = try? escapedAppUserID(appUserID: appUserID) else {
            completion(nil, ErrorUtils.missingAppUserIDError())
            return
        }

        let path = "/subscribers/\(appUserID)/offerings"
        if add(callback: completion, key: path) == .addedToExistingInFlightList {
            return
        }

        httpClient.performGETRequest(serially: true,
                                     path: path,
                                     headers: authHeaders) { [weak self] (statusCode, response, error) in
            guard let self = self else {
                return
            }

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
                let backendCode = self.maybeNumberFromError(code: response?["code"])
                let backendMessage = response?["message"] as? String
                errorForCallbacks = ErrorUtils.backendError(withBackendCode: backendCode as NSNumber?,
                                                            backendMessage: backendMessage)
            } else {
                errorForCallbacks = ErrorUtils.unexpectedBackendResponseError()
            }

            for callback in self.getOfferingsCallbacksAndClearCache(forKey: path) {
                callback(nil, errorForCallbacks)
            }
        }
    }

    func getIntroEligibility(appUserID: String,
                             receiptData: Data,
                             productIdentifiers: [String],
                             completion: @escaping IntroEligibilityResponseHandler) {
        guard productIdentifiers.count > 0 else {
            completion([:], nil)
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

            completion(eligibilities, nil)
            return
        }

        // Closure we can use for both missing appUserID as well as server error where we have an unknown
        // eligibility status.
        let unknownEligibilityClosure: () -> [String: IntroEligibility] = {
            let unknownEligibilities = [IntroEligibility](repeating: IntroEligibility(eligibilityStatus: .unknown),
                                                          count: productIdentifiers.count)
            let productIdentifiersToEligibility = zip(productIdentifiers, unknownEligibilities)
            return Dictionary(uniqueKeysWithValues: productIdentifiersToEligibility)
        }

        guard let appUserID = try? escapedAppUserID(appUserID: appUserID) else {
            completion(unknownEligibilityClosure(), ErrorUtils.missingAppUserIDError())
            return
        }

        let fetchToken = receiptData.asFetchToken
        let path = "/subscribers/\(appUserID)/intro_eligibility"
        let body: [String: Any] = ["product_identifiers": productIdentifiers,
                                   "fetch_token": fetchToken]

        httpClient.performPOSTRequest(serially: true,
                                      path: path,
                                      requestBody: body,
                                      headers: authHeaders) { statusCode, maybeResponse, error in
            let eligibilityResponse = IntroEligibilityResponse(maybeResponse: maybeResponse,
                                                               statusCode: statusCode,
                                                               error: error,
                                                               productIdentifiers: productIdentifiers,
                                                               unknownEligibilityClosure: unknownEligibilityClosure,
                                                               completion: completion)
            self.handleIntroEligibility(response: eligibilityResponse)
        }
    }

}

private extension Backend {

    enum CallbackCacheStatus {

        // When an array exists in the cache for a particular path, we add to it and return this value.
        case addedToExistingInFlightList

        // When an array doesn't yet exist in the cache for a particular path, we create one, add to it
        // and return this value.
        case firstCallbackAddedToList

    }

    func handleIntroEligibility(response: IntroEligibilityResponse) {
        var eligibilitiesByProductIdentifier = response.maybeResponse
        if response.statusCode >= HTTPStatusCodes.redirect.rawValue || response.error != nil {
            eligibilitiesByProductIdentifier = [:]
        }

        guard let eligibilitiesByProductIdentifier = eligibilitiesByProductIdentifier else {
            response.completion(response.unknownEligibilityClosure(), nil)
            return
        }

        var eligibilities: [String: IntroEligibility] = [:]
        for productID in response.productIdentifiers {
            let status: IntroEligibilityStatus

            if let eligibility = eligibilitiesByProductIdentifier[productID] as? Bool {
                status = eligibility ? .eligible : .ineligible
            } else {
                status = .unknown
            }

            eligibilities[productID] = IntroEligibility(eligibilityStatus: status)
        }
        response.completion(eligibilities, nil)
    }

    func handleLogin(response: [String: Any]?,
                     statusCode: Int,
                     error: Error?,
                     completion: (PurchaserInfo?, Bool, Error?) -> Void ) {
        if let error = error {
            completion(nil, false, ErrorUtils.networkError(withUnderlyingError: error))
            return
        }

        if statusCode > HTTPStatusCodes.redirect.rawValue {
            let backendCode = maybeNumberFromError(code: response?["code"])
            let backendMessage = response?["message"] as? String
            let responsError = ErrorUtils.backendError(withBackendCode: backendCode as NSNumber?,
                                                       backendMessage: backendMessage)
            completion(nil, false, ErrorUtils.networkError(withUnderlyingError: responsError))
            return
        }

        guard let response = response, let purchaserInfo = PurchaserInfo(data: response) else {
            let responseError = ErrorUtils.unexpectedBackendResponseError()
            completion(nil, false, responseError)
            return
        }

        let created = statusCode == HTTPStatusCodes.createdSuccess.rawValue
        Logger.user(Strings.identity.login_success)
        completion(purchaserInfo, created, nil)
    }

    func attributesUserInfoFromResponse(response: [String: Any], statusCode: Int) -> [String: Any] {
        var resultDict: [String: Any] = [:]
        let isInternalServerError = statusCode >= HTTPStatusCodes.internalServerError.rawValue
        let isNotFoundError = statusCode == HTTPStatusCodes.notFoundError.rawValue

        let successfullySynced = !(isInternalServerError || isNotFoundError)
        resultDict[Backend.RCSuccessfullySyncedKey as String] = successfullySynced

        let hasAttributesResponseContainerKey = (response[Backend.RCAttributeErrorsResponseKey] != nil)
        let attributesResponseDict = hasAttributesResponseContainerKey
            ? response[Backend.RCAttributeErrorsResponseKey]
            : response

        if let attributesResponseDict = attributesResponseDict as? [String: Any],
           let attributesErrors = attributesResponseDict[Backend.RCAttributeErrorsKey] {
            resultDict[Backend.RCAttributeErrorsKey] = attributesErrors
        }

        return resultDict
    }

    func handleSubscribedAttributesResult(statusCode: Int,
                                          response: [String: Any]?,
                                          error: Error?,
                                          completion: ((Error?) -> Void)?) {
        guard let completion = completion else {
            return
        }

        if let error = error {
            completion(ErrorUtils.networkError(withUnderlyingError: error))
            return
        }

        let responseError: Error?

        if let response = response, statusCode > HTTPStatusCodes.redirect.rawValue {
            let extraUserInfo = attributesUserInfoFromResponse(response: response, statusCode: statusCode)
            responseError = ErrorUtils.backendError(withBackendCode: maybeNumberFromError(code: response["code"]),
                                                    backendMessage: response["message"] as? String,
                                                    extraUserInfo: extraUserInfo as [NSError.UserInfoKey: Any])
        } else {
            responseError = nil
        }

        completion(responseError)

    }

    func handle(response: [String: Any]?, statusCode: Int, error: Error?, completion: ((Error?) -> Void)?) {
        if let error = error {
            completion?(ErrorUtils.networkError(withUnderlyingError: error))
            return
        }

        guard statusCode <= HTTPStatusCodes.redirect.rawValue else {
            let code = maybeNumberFromError(code: response?["code"])
            let message = response?["message"] as? String
            let responseError = ErrorUtils.backendError(withBackendCode: code, backendMessage: message)
            completion?(responseError)
            return
        }

        completion?(nil)
    }

    func handle(purchaserInfoResponse response: [String: Any]?,
                statusCode: Int,
                error: Error?,
                completion: BackendPurchaserInfoResponseHandler) {
        if let error = error {
            completion(nil, ErrorUtils.networkError(withUnderlyingError: error))
            return
        }

        let isErrorStatusCode = statusCode >= HTTPStatusCodes.redirect.rawValue

        let maybePurchaserInfo: PurchaserInfo? = response == nil ? nil : PurchaserInfo(data: response!)
        if !isErrorStatusCode && maybePurchaserInfo == nil {
            completion(nil, ErrorUtils.unexpectedBackendResponseError())
            return
        }

        let subscriberAttributesErrorInfo = attributesUserInfoFromResponse(response: response ?? [:],
                                                                           statusCode: statusCode)

        let hasError = (isErrorStatusCode || subscriberAttributesErrorInfo[Backend.RCAttributeErrorsKey] != nil)

        guard !hasError else {
            let finishable = statusCode < HTTPStatusCodes.internalServerError.rawValue
            var extraUserInfo = [ErrorDetails.finishableKey: finishable] as [String: Any]
            extraUserInfo.merge(subscriberAttributesErrorInfo) { _, new in new }
            let code = maybeNumberFromError(code: response?["code"])
            let message = response?["message"] as? String
            let responseError = ErrorUtils.backendError(withBackendCode: code,
                                                        backendMessage: message,
                                                        extraUserInfo: extraUserInfo as [NSError.UserInfoKey: Any])
            completion(maybePurchaserInfo, responseError)
            return
        }

        completion(maybePurchaserInfo, nil)
    }

    func escapedAppUserID(appUserID: String) throws -> String {
        let trimmedAndEscapedAppUserID = appUserID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!

        guard trimmedAndEscapedAppUserID.count > 0 else {
            Logger.warn("appUserID is empty")
            throw ErrorUtils.missingAppUserIDError()
        }

        return trimmedAndEscapedAppUserID
    }

    func subscriberAttributesToDict(subscriberAttributes: SubscriberAttributeDict) -> [String: Any] {
        var attributesByKey: [String: Any] = [:]
        for (key, value) in subscriberAttributes {
            attributesByKey[key] = value.asBackendDictionary()
        }
        return attributesByKey
    }

    func userInfoAttributes(response: [String: Any], statusCode: Int) -> [String: Any] {
        var resultDict: [String: Any] = [:]

        let isInternalServerError = statusCode >= HTTPStatusCodes.internalServerError.rawValue
        let isNotFoundError = statusCode == HTTPStatusCodes.notFoundError.rawValue
        let successfullySynced = !(isInternalServerError || isNotFoundError)
        resultDict[Backend.RCSuccessfullySyncedKey as String] = successfullySynced

        let attributesResponse = (response[Backend.RCAttributeErrorsResponseKey] as? [String: Any]) ?? response
        resultDict[Backend.RCAttributeErrorsKey] = attributesResponse[Backend.RCAttributeErrorsKey]

        return resultDict
    }

    func maybeNumberFromError(code: Any?) -> NSNumber? {
        // The code can be a String or NSNumber
        if let codeString = code as? String {
            if let codeInt = Int(codeString) {
                return codeInt as NSNumber
            } else {
                return nil
            }
        }

        return code as? NSNumber
    }

    // MARK: Callback cache management

    func add(callback: @escaping BackendPurchaserInfoResponseHandler, key: String) -> CallbackCacheStatus {
        return callbackQueue.sync { [self] in
            var callbacksForKey = purchaserInfoCallbacksCache[key] ?? []
            let cacheStatus: CallbackCacheStatus = !callbacksForKey.isEmpty
                ? .addedToExistingInFlightList
                : .firstCallbackAddedToList

            callbacksForKey.append(callback)
            purchaserInfoCallbacksCache[key] = callbacksForKey
            return cacheStatus
        }
    }

    func add(callback: @escaping OfferingsResponseHandler, key: String) -> CallbackCacheStatus {
        return callbackQueue.sync { [self] in
            var callbacksForKey = offeringsCallbacksCache[key] ?? []
            let cacheStatus: CallbackCacheStatus = !callbacksForKey.isEmpty
                ? .addedToExistingInFlightList
                : .firstCallbackAddedToList

            callbacksForKey.append(callback)
            offeringsCallbacksCache[key] = callbacksForKey
            return cacheStatus
        }
    }

    func getOfferingsCallbacksAndClearCache(forKey key: String) -> [OfferingsResponseHandler] {
        return callbackQueue.sync { [self] in
            let callbacks = offeringsCallbacksCache.removeValue(forKey: key)
            assert(callbacks != nil)
            return callbacks ?? []
        }
    }

    func getPurchaserInfoCallbacksAndClearCache(forKey key: String) -> [BackendPurchaserInfoResponseHandler] {
        return callbackQueue.sync { [self] in
            let callbacks = purchaserInfoCallbacksCache.removeValue(forKey: key)
            assert(callbacks != nil)
            return callbacks ?? []
        }
    }

}

// swiftlint:enable type_body_length file_length
