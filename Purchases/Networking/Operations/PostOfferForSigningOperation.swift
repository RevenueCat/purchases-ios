//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostOfferForSigningOperation.swift
//
//  Created by Joshua Liebowitz on 11/19/21.

import Foundation

class PostOfferForSigningOperation: NetworkOperation {

    private let configuration: UserSpecificConfiguration
    private let offerIdentifier: String
    private let productIdentifier: String
    private let subscriptionGroup: String
    private let receiptData: Data
    private let completion: OfferSigningResponseHandler

    init(configuration: UserSpecificConfiguration,
         offerIdForSigning offerIdentifier: String,
         productIdentifier: String,
         subscriptionGroup: String,
         receiptData: Data,
         completion: @escaping OfferSigningResponseHandler) {
        self.configuration = configuration
        self.offerIdentifier = offerIdentifier
        self.productIdentifier = productIdentifier
        self.subscriptionGroup = subscriptionGroup
        self.receiptData = receiptData
        self.completion = completion

        super.init(configuration: configuration)
    }

    override func main() {
        if self.isCancelled {
            return
        }

        self.post(offerIdForSigning: self.offerIdentifier,
                  productIdentifier: self.productIdentifier,
                  subscriptionGroup: self.subscriptionGroup,
                  receiptData: self.receiptData,
                  appUserID: self.configuration.appUserID,
                  completion: self.completion)
    }

    // swiftlint:disable:next function_parameter_count function_body_length
    func post(offerIdForSigning offerIdentifier: String,
              productIdentifier: String,
              subscriptionGroup: String,
              receiptData: Data,
              appUserID: String,
              completion: @escaping OfferSigningResponseHandler) {
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
                                           headers: authHeaders) { statusCode, maybeResponse, maybeError in
            if let error = maybeError {
                completion(nil, nil, nil, nil, ErrorUtils.networkError(withUnderlyingError: error))
                return
            }

            guard statusCode < HTTPStatusCodes.redirect.rawValue else {
                let backendCode = BackendErrorCode(maybeCode: maybeResponse?["code"])
                let backendMessage = maybeResponse?["message"] as? String
                let error = ErrorUtils.backendError(withBackendCode: backendCode, backendMessage: backendMessage)
                completion(nil, nil, nil, nil, error)
                return
            }

            guard let response = maybeResponse else {
                let subErrorCode = UnexpectedBackendResponseSubErrorCode.postOfferEmptyResponse
                let error = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode)
                Logger.debug(Strings.backendError.offerings_empty_response)
                completion(nil, nil, nil, nil, error)
                return
            }

            guard let offers = response["offers"] as? [[String: Any]] else {
                let subErrorCode = UnexpectedBackendResponseSubErrorCode.postOfferIdBadResponse
                let error = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode,
                                                                 extraContext: response.stringRepresentation)
                Logger.debug(Strings.backendError.offerings_response_json_error(response: response))
                completion(nil, nil, nil, nil, error)
                return
            }

            guard offers.count > 0 else {
                let subErrorCode = UnexpectedBackendResponseSubErrorCode.postOfferIdMissingOffersInResponse
                let error = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode)
                Logger.debug(Strings.backendError.no_offerings_response_json(response: response))
                completion(nil, nil, nil, nil, error)
                return
            }

            let offer = offers[0]
            if let signatureError = offer["signature_error"] as? [String: Any] {
                let backendCode = BackendErrorCode(maybeCode: signatureError["code"])
                let backendMessage = signatureError["message"] as? String
                let error = ErrorUtils.backendError(withBackendCode: backendCode, backendMessage: backendMessage)
                completion(nil, nil, nil, nil, error)
                return

            } else if let signatureData = offer["signature_data"] as? [String: Any] {
                let signature = signatureData["signature"] as? String
                let keyIdentifier = offer["key_id"] as? String
                let nonceString = signatureData["nonce"] as? String
                let maybeNonce = nonceString.flatMap { UUID(uuidString: $0) }
                let timestamp = signatureData["timestamp"] as? Int

                completion(signature, keyIdentifier, maybeNonce, timestamp, nil)
                return
            } else {
                Logger.error(Strings.backendError.signature_error(maybeSignatureDataString: offer["signature_data"]))
                let subErrorCode = UnexpectedBackendResponseSubErrorCode.postOfferIdSignature
                let signatureError = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode)
                completion(nil, nil, nil, nil, signatureError)
                return
            }
        }
    }

}
