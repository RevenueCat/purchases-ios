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

    struct PostOfferForSigningData: Hashable {

        let offerIdentifier: String
        let productIdentifier: String
        let subscriptionGroup: String

    }

    private let configuration: UserSpecificConfiguration
    private let offers: [PostOfferForSigningData]
    private let receipt: EncodedAppleReceipt
    private let responseHandler: OfferingsAPI.OffersSigningResponseHandler

    init(configuration: UserSpecificConfiguration,
         offers: [PostOfferForSigningData],
         receipt: EncodedAppleReceipt,
         responseHandler: @escaping OfferingsAPI.OffersSigningResponseHandler) {
        self.configuration = configuration
        self.offers = offers
        self.receipt = receipt
        self.responseHandler = responseHandler

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        self.post(completion: completion)
    }

    private func post(completion: @escaping () -> Void) {
        let request = HTTPRequest(
            method: .post(Body(appUserID: self.configuration.appUserID, offers: self.offers, receipt: self.receipt)),
            path: .postOfferForSigning
        )

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<PostOfferResponse>.Result) in
            let result = response
                .mapError { error -> BackendError in
                    if case .decoding = error {
                        return .unexpectedBackendResponse(.postOfferIdSignature,
                                                          extraContext: error.localizedDescription)
                    } else {
                        return .networkError(error)
                    }
                }
            let results = self.offers.map { requestedOffer in
                result.flatMap { response -> Result<SigningData, BackendError> in
                    let matches = response.body.offers.filter {
                        $0.offerIdentifier == requestedOffer.offerIdentifier &&
                        $0.productIdentifier == requestedOffer.productIdentifier
                    }
                    guard let offer = matches.onlyElement else {
                        return .failure(.unexpectedBackendResponse(.postOfferIdMissingOffersInResponse))
                    }
                    return offer.result
                        .mapError {
                            BackendError.unexpectedBackendResponse(.postOfferIdSignature,
                                                                   extraContext: $0.localizedDescription)
                        }
                        .flatMap { Self.handleOffer($0, statusCode: response.httpStatusCode) }
                }
            }

            self.responseHandler(results)
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

        init(appUserID: String, offers: [PostOfferForSigningData], receipt: EncodedAppleReceipt) {
            self.appUserID = appUserID
            self.fetchToken = receipt.serialized()
            var seen: Set<PostOfferForSigningData> = []
            self.generateOffers = offers.filter { seen.insert($0).inserted }.map {
                .init(offerID: $0.offerIdentifier,
                      productID: $0.productIdentifier,
                      subscriptionGroup: $0.subscriptionGroup)
            }
        }

    }

}
