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

@objc(RCUnexpectedBackendResponseSubErrorCode) public enum UnexpectedBackendResponseSubErrorCode: Int, Error {

    case unknown = 0
    case loginMissingResponse
    case loginResponseDecoding
    case postOfferEmptyResponse
    case postOfferIdBadResponse
    case postOfferIdMissingOffersInResponse
    case postOfferIdSignature
    case getOfferUnexpectedResponse
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
            return "Unable to instantiate a CustomerInfoResponse"
        case .unknown:
            return "Encountered an unknown sub-error code."
        }
    }

}
