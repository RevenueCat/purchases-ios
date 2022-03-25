//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UnexpectedBackendResponseSubErrorCode.swift
//
//  Created by Joshua Liebowitz on 10/25/21.

import Foundation

enum UnexpectedBackendResponseSubErrorCode: Int, Error {

    /// Login call failed due to a problem with the response.
    case loginResponseDecoding = 1

    /// Received a bad response after posting an offer- "offers" couldn't be read from response.
    case postOfferIdBadResponse = 3

    /// Received a bad response after posting an offer- "offers" was totally missing.
    case postOfferIdMissingOffersInResponse

    /// Received a bad response after posting an offer- there was an issue with the signature.
    case postOfferIdSignature

    /// getOffer call failed with an invalid response.
    case getOfferUnexpectedResponse

    /// A call that is supposed to retrieve a CustomerInfo failed because the CustomerInfo in the response was nil.
    case customerInfoNil

    /// A call that is supposed to retrieve a CustomerInfo failed because the json object couldn't be parsed.
    case customerInfoResponseParsing

}

extension UnexpectedBackendResponseSubErrorCode: DescribableError {

    var description: String {
        switch self {
        case .loginResponseDecoding:
            return "Unable to decode response returned from login."
        case .postOfferIdBadResponse:
            return "Unable to decode response returned from posting offer for signing."
        case .postOfferIdMissingOffersInResponse:
            return "Missing offers from response returned from posting offer for signing."
        case .postOfferIdSignature:
            return "Signature error encountered in response returned from posting offer for signing."
        case .getOfferUnexpectedResponse:
            return "Unknown error encountered while getting offerings."
        case .customerInfoNil:
            return "Unable to instantiate a CustomerInfoResponse, CustomerInfo in response was nil."
        case .customerInfoResponseParsing:
            return "Unable to instantiate a CustomerInfoResponse due to malformed json."
        }
    }

}
