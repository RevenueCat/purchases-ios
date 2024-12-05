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
        let receipt: EncodedAppleReceipt

    }

    private let configuration: UserSpecificConfiguration
    private let postOfferData: PostOfferForSigningData
    private let responseHandler: OfferingsAPI.OfferSigningResponseHandler

    init(configuration: UserSpecificConfiguration,
         postOfferForSigningData: PostOfferForSigningData,
         responseHandler: @escaping OfferingsAPI.OfferSigningResponseHandler) {
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

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<PostOfferResponse>.Result) in
            let result: Result<PostOfferForSigningOperation.SigningData, BackendError> = response
                .mapError { error -> BackendError in
                    if case .decoding = error {
                        return .unexpectedBackendResponse(.postOfferIdSignature,
                                                          extraContext: error.localizedDescription)
                    } else {
                        return .networkError(error)
                    }
                }
                .flatMap { response in
                    let (statusCode, response) = (response.httpStatusCode, response.body)

                    let offers = response.offers

                    guard let firstOffer = offers.first else {
                        Logger.debug(Strings.backendError.offerings_response_no_offerings)

                        return .failure(.unexpectedBackendResponse(.postOfferIdMissingOffersInResponse))
                    }

                    return Self.handleOffer(firstOffer, statusCode: statusCode)
                }

            self.responseHandler(result)
            completion()
        }
    }

    private static func handleOffer(
        _ offer: PostOfferResponse.Offer,
        statusCode: HTTPStatusCode
    ) -> Result<PostOfferForSigningOperation.SigningData, BackendError> {
        if let signatureError = offer.signatureError {
            return .failure(
                .networkError(.errorResponse(signatureError, statusCode))
            )
        } else if let signingData = offer.asSigningData {
            return .success(signingData)
        } else {
            return .failure(
                .unexpectedBackendResponse(.postOfferIdSignature, extraContext: "\(offer)")
            )
        }
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension PostOfferForSigningOperation: @unchecked Sendable {}

private extension PostOfferResponse.Offer {

    var asSigningData: PostOfferForSigningOperation.SigningData? {
        guard let data = self.signatureData else { return nil }

        return (data.signature, self.keyIdentifier, data.nonce, data.timestamp)
    }

}

private extension PostOfferForSigningOperation {

    struct Body: HTTPRequestBody {

        // swiftlint:disable:next nesting
        struct Offer: Encodable {

            let offerID: String
            let productID: String
            let subscriptionGroup: String

        }

        let appUserID: String
        let fetchToken: String?
        let generateOffers: [Offer]

        init(appUserID: String, data: PostOfferForSigningData) {
            self.appUserID = appUserID
            self.fetchToken = data.receipt.serialized()
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
