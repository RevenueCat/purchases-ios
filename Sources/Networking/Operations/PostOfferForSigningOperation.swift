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

    typealias SigningData = (signature: String, keyIdentifier: String, nonce: UUID, timestamp: Int)

    struct PostOfferForSigningData {

        let offerIdentifier: String
        let productIdentifier: String
        let subscriptionGroup: String
        let receiptData: Data

    }

    private let configuration: UserSpecificConfiguration
    private let postOfferData: PostOfferForSigningData
    private let responseHandler: Backend.OfferSigningResponseHandler

    init(configuration: UserSpecificConfiguration,
         postOfferForSigningData: PostOfferForSigningData,
         responseHandler: @escaping Backend.OfferSigningResponseHandler) {
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
            method: .post(Body(appUserID: self.configuration.appUserID, data: self.postOfferData)),
            path: .postOfferForSigning
        )

        self.httpClient.perform(request,
                                authHeaders: self.authHeaders) { (response: HTTPResponse<[String: Any]>.Result) in
            let result: Result<PostOfferForSigningOperation.SigningData, BackendError> = response
                .mapError(BackendError.networkError)
                .flatMap { response in
                    let (statusCode, response) = (response.statusCode, response.body)

                    guard let offers = response["offers"] as? [[String: Any]] else {
                        Logger.debug(Strings.backendError.offerings_response_json_error(response: response))

                        return .failure(.unexpectedBackendResponse(.postOfferIdBadResponse,
                                                                   extraContext: response.stringRepresentation))
                    }

                    guard offers.count > 0 else {
                        Logger.debug(Strings.backendError.no_offerings_response_json(response: response))

                        return .failure(.unexpectedBackendResponse(.postOfferIdMissingOffersInResponse))
                    }

                    return Self.handleOffer(offers[0], statusCode: statusCode)
                }

            self.responseHandler(result)
            completion()
        }
    }

    private static func handleOffer(
        _ offer: [String: Any],
        statusCode: HTTPStatusCode
    ) -> Result<PostOfferForSigningOperation.SigningData, BackendError> {
        if let signatureError = offer["signature_error"] as? [String: Any] {
            return .failure(
                .networkError(.errorResponse(ErrorResponse.from(signatureError), statusCode))
            )
        } else if let signatureData = offer["signature_data"] as? [String: Any],
                  let signature = signatureData["signature"] as? String,
                  let keyIdentifier = offer["key_id"] as? String,
                  let nonce = (signatureData["nonce"] as? String).flatMap({ UUID(uuidString: $0) }),
                  let timestamp = signatureData["timestamp"] as? Int {
            return .success((signature, keyIdentifier, nonce, timestamp))
        } else {
            return .failure(.unexpectedBackendResponse(.postOfferIdSignature, extraContext: offer.stringRepresentation))
        }
    }

}

private extension PostOfferForSigningOperation {

    struct Body: Encodable {

        // swiftlint:disable:next nesting
        struct Offer: Encodable {

            let offerID: String
            let productID: String
            let subscriptionGroup: String

        }

        let appUserID: String
        let fetchToken: String
        let generateOffers: [Offer]

        init(appUserID: String, data: PostOfferForSigningData) {
            self.appUserID = appUserID
            self.fetchToken = data.receiptData.asFetchToken
            self.generateOffers = [
                .init(
                    offerID: data.offerIdentifier,
                    productID: data.productIdentifier,
                    subscriptionGroup: data.subscriptionGroup
                )
            ]
        }

    }

}
