//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostOfferResponse.swift
//
//  Created by Nacho Soto on 5/12/22.

import Foundation

// swiftlint:disable nesting

struct PostOfferResponse {

    struct Offer {

        struct SignatureData {

            let nonce: UUID
            let signature: String
            let timestamp: Int

        }

        let keyIdentifier: String
        let offerIdentifier: String
        let productIdentifier: String
        let signatureData: SignatureData?
        let signatureError: ErrorResponse?

    }

    /// Keep identities even when a signing payload is malformed, so duplicate responses still fail closed.
    struct Entry {

        let offerIdentifier: String?
        let productIdentifier: String?
        let result: Result<Offer, Error>

    }

    let offers: [Entry]
}

extension PostOfferResponse.Entry: Decodable {

    init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: PostOfferResponse.Offer.CodingKeys.self)
        self.offerIdentifier = try? container?.decode(String.self, forKey: .offerIdentifier)
        self.productIdentifier = try? container?.decode(String.self, forKey: .productIdentifier)
        self.result = Result { try PostOfferResponse.Offer(from: decoder) }
    }

}

extension PostOfferResponse.Offer.SignatureData: Decodable {}
extension PostOfferResponse.Offer: Decodable {

    enum CodingKeys: String, CodingKey {

        case keyIdentifier = "keyId"
        case offerIdentifier = "offerId"
        case productIdentifier = "productId"
        case signatureError
        case signatureData

    }

}

extension PostOfferResponse: Decodable {}
extension PostOfferResponse: HTTPResponseBody {}
