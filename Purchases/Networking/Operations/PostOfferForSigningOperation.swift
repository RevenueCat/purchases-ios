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
    private let responseHandler: OfferSigningResponseHandler

    init(configuration: UserSpecificConfiguration,
         postOfferForSigningData: PostOfferForSigningData,
         responseHandler: @escaping OfferSigningResponseHandler) {
        self.configuration = configuration
        self.postOfferData = postOfferForSigningData
        self.responseHandler = responseHandler

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        self.post(completion: completion)
    }

    private func post(completion: @escaping () -> Void) {
        let request = HTTPRequest(
            method: .post(body: ["app_user_id": self.configuration.appUserID,
                                 "fetch_token": self.postOfferData.receiptData.asFetchToken,
                                 "generate_offers": [
                                    ["offer_id": self.postOfferData.offerIdentifier,
                                     "product_id": self.postOfferData.productIdentifier,
                                     "subscription_group": self.postOfferData.subscriptionGroup
                                    ]
                                 ]]),
            path: .postOfferForSigning
        )

        self.httpClient.perform(request, authHeaders: self.authHeaders) { statusCode, response, error in
            let result: (String?, String?, UUID?, Int?, Error?) = {
                if let error = error {
                    return (nil, nil, nil, nil, ErrorUtils.networkError(withUnderlyingError: error))
                }

                guard statusCode < HTTPStatusCodes.redirect.rawValue else {
                    let backendCode = BackendErrorCode(code: response?["code"])
                    let backendMessage = response?["message"] as? String
                    let error = ErrorUtils.backendError(withBackendCode: backendCode, backendMessage: backendMessage)
                    return (nil, nil, nil, nil, error)
                }

                guard let response = response else {
                    let subErrorCode = UnexpectedBackendResponseSubErrorCode.postOfferEmptyResponse
                    let error = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode)
                    Logger.debug(Strings.backendError.offerings_empty_response)
                    return (nil, nil, nil, nil, error)
                }

                guard let offers = response["offers"] as? [[String: Any]] else {
                    let subErrorCode = UnexpectedBackendResponseSubErrorCode.postOfferIdBadResponse
                    let error = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode,
                                                                     extraContext: response.stringRepresentation)
                    Logger.debug(Strings.backendError.offerings_response_json_error(response: response))
                    return (nil, nil, nil, nil, error)
                }

                guard offers.count > 0 else {
                    let subErrorCode = UnexpectedBackendResponseSubErrorCode.postOfferIdMissingOffersInResponse
                    let error = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode)
                    Logger.debug(Strings.backendError.no_offerings_response_json(response: response))
                    return (nil, nil, nil, nil, error)
                }

                return Self.handleOffer(offers[0])
            }()

            self.responseHandler(result.0, result.1, result.2, result.3, result.4)
            completion()
        }
    }

    // swiftlint:disable:next large_tuple
    private static func handleOffer(_ offer: [String: Any]) -> (String?, String?, UUID?, Int?, Error?) {
        if let signatureError = offer["signature_error"] as? [String: Any] {
            let backendCode = BackendErrorCode(code: signatureError["code"])
            let backendMessage = signatureError["message"] as? String
            let error = ErrorUtils.backendError(withBackendCode: backendCode, backendMessage: backendMessage)
            return (nil, nil, nil, nil, error)

        } else if let signatureData = offer["signature_data"] as? [String: Any] {
            let signature = signatureData["signature"] as? String
            let keyIdentifier = offer["key_id"] as? String
            let nonceString = signatureData["nonce"] as? String
            let nonce = nonceString.flatMap { UUID(uuidString: $0) }
            let timestamp = signatureData["timestamp"] as? Int

            return (signature, keyIdentifier, nonce, timestamp, nil)
        } else {
            Logger.error(Strings.backendError.signature_error(signatureDataString: offer["signature_data"]))
            let subErrorCode = UnexpectedBackendResponseSubErrorCode.postOfferIdSignature
            let signatureError = ErrorUtils.unexpectedBackendResponse(withSubError: subErrorCode)
            return (nil, nil, nil, nil, signatureError)
        }
    }

}
