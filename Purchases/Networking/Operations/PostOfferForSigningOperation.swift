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

    struct PostOfferForSigningData {

        let offerIdentifier: String
        let productIdentifier: String
        let subscriptionGroup: String
        let receiptData: Data

    }

    private let configuration: UserSpecificConfiguration
    private let postOfferData: PostOfferForSigningData
    private let completion: OfferSigningResponseHandler

    init(configuration: UserSpecificConfiguration,
         postOfferForSigningData: PostOfferForSigningData,
         completion: @escaping OfferSigningResponseHandler) {
        self.configuration = configuration
        self.postOfferData = postOfferForSigningData
        self.completion = completion

        super.init(configuration: configuration)
    }

    override func main() {
        if self.isCancelled {
            return
        }

        self.post(configuration: self.configuration, postOfferData: self.postOfferData, handler: self.completion)
    }

    func post(configuration: UserSpecificConfiguration,
              postOfferData: PostOfferForSigningData,
              handler: @escaping OfferSigningResponseHandler) {
        let requestBody: [String: Any] = ["app_user_id": configuration.appUserID,
                                          "fetch_token": postOfferData.receiptData.asFetchToken,
                                          "generate_offers": [
                                            ["offer_id": postOfferData.offerIdentifier,
                                             "product_id": postOfferData.productIdentifier,
                                             "subscription_group": postOfferData.subscriptionGroup
                                            ]
                                          ]]

        self.httpClient.performPOSTRequest(serially: true,
                                           path: "/offers",
                                           requestBody: requestBody,
                                           headers: authHeaders) { statusCode, maybeResponse, maybeError in
            if let error = maybeError {
                handler(nil, nil, nil, nil, ErrorUtils.networkError(withUnderlyingError: error))
                return
            }

            guard statusCode < HTTPStatusCodes.redirect.rawValue else {
                let backendCode = BackendErrorCode(maybeCode: maybeResponse?["code"])
                let backendMessage = maybeResponse?["message"] as? String
                let error = ErrorUtils.backendError(withBackendCode: backendCode, backendMessage: backendMessage)
                handler(nil, nil, nil, nil, error)
                return
            }

            guard let response = maybeResponse else {
                let subErrorCode = UnexpectedBackendResponseSubErrorCode.postOfferEmptyResponse
                let error = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode)
                Logger.debug(Strings.backendError.offerings_empty_response)
                handler(nil, nil, nil, nil, error)
                return
            }

            guard let offers = response["offers"] as? [[String: Any]] else {
                let subErrorCode = UnexpectedBackendResponseSubErrorCode.postOfferIdBadResponse
                let error = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode,
                                                                 extraContext: response.stringRepresentation)
                Logger.debug(Strings.backendError.offerings_response_json_error(response: response))
                handler(nil, nil, nil, nil, error)
                return
            }

            guard offers.count > 0 else {
                let subErrorCode = UnexpectedBackendResponseSubErrorCode.postOfferIdMissingOffersInResponse
                let error = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode)
                Logger.debug(Strings.backendError.no_offerings_response_json(response: response))
                handler(nil, nil, nil, nil, error)
                return
            }

            let offer = offers[0]
            self.handleOffer(offer, handler: handler)
        }
    }

    func handleOffer(_ offer: [String: Any], handler: OfferSigningResponseHandler) {
        if let signatureError = offer["signature_error"] as? [String: Any] {
            let backendCode = BackendErrorCode(maybeCode: signatureError["code"])
            let backendMessage = signatureError["message"] as? String
            let error = ErrorUtils.backendError(withBackendCode: backendCode, backendMessage: backendMessage)
            handler(nil, nil, nil, nil, error)
            return

        } else if let signatureData = offer["signature_data"] as? [String: Any] {
            let signature = signatureData["signature"] as? String
            let keyIdentifier = offer["key_id"] as? String
            let nonceString = signatureData["nonce"] as? String
            let maybeNonce = nonceString.flatMap { UUID(uuidString: $0) }
            let timestamp = signatureData["timestamp"] as? Int

            handler(signature, keyIdentifier, maybeNonce, timestamp, nil)
            return
        } else {
            Logger.error(Strings.backendError.signature_error(maybeSignatureDataString: offer["signature_data"]))
            let subErrorCode = UnexpectedBackendResponseSubErrorCode.postOfferIdSignature
            let signatureError = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode)
            handler(nil, nil, nil, nil, signatureError)
            return
        }
    }

}
