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

    // Login call returned with no response.
    case loginMissingResponse = 0

    // Login call failed due to a problem with the response.
    case loginResponseDecoding

    // Received an empty response after posting an offer.
    case postOfferEmptyResponse

    // Received a bad response after posting an offer- "offers" couldn't be read from response.
    case postOfferIdBadResponse

    // Received a bad response after posting an offer- "offers" was totally missing.
    case postOfferIdMissingOffersInResponse

    // Received a bad response after posting an offer- there was an issue with the signature.
    case postOfferIdSignature

    // getOffer call failed with an invalid response.
    case getOfferUnexpectedResponse

    // A call that is supposed to retrieve a CustomerInfo failed and we're not sure why.
    case customerInfoResponse

    var description: String {
        switch self {
        case .loginMissingResponse:
            return "Login returned with a missing response."
        case .loginResponseDecoding:
            return "Unable to decode response returned from login."
        case .postOfferEmptyResponse:
            return "posting offer for signing failed, received an empty response."
        case .postOfferIdBadResponse:
            return "Unable to decode response returned from posting offer for signing."
        case .postOfferIdMissingOffersInResponse:
            return "Missing offers from response returned from posting offer for signing."
        case .postOfferIdSignature:
            return "Signature error encountered in response returned from posting offer for signing."
        case .getOfferUnexpectedResponse:
            return "Unknown error encountered while getting offerings."
        case .customerInfoResponse:
            return "Unable to instantiate a CustomerInfoResponse."
        }
    }

}
