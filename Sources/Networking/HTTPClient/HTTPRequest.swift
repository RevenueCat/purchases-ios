//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPRequest.swift
//
//  Created by Nacho Soto on 2/27/22.

/// A request to be made by ``HTTPClient``
struct HTTPRequest {

    let method: Method
    let path: Path

}

// MARK: - Method

extension HTTPRequest {

    enum Method {

        case get
        case post(Encodable)

    }

}

extension HTTPRequest {

    var requestBody: Encodable? {
        switch self.method {
        case let .post(body): return body
        case .get: return nil
        }
    }

}

extension HTTPRequest.Method {

    var httpMethod: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        }
    }

}

// MARK: - Path

extension HTTPRequest {

    enum Path: Equatable {

        case getCustomerInfo(appUserID: String)
        case getOfferings(appUserID: String)
        case getIntroEligibility(appUserID: String)
        case logIn
        case postAttributionData(appUserID: String)
        case postOfferForSigning
        case postReceiptData
        case postSubscriberAttributes(appUserID: String)
        case postAdServicesToken(appUserID: String)

    }

}

extension HTTPRequest.Path: Hashable {}

extension HTTPRequest.Path: CustomStringConvertible {

    var description: String {
        switch self {
        case let .getCustomerInfo(appUserID):
            return "subscribers/\(appUserID)"

        case let .getOfferings(appUserID):
            return "subscribers/\(appUserID)/offerings"

        case let .getIntroEligibility(appUserID):
            return "subscribers/\(appUserID)/intro_eligibility"

        case .logIn:
            return "subscribers/identify"

        case let .postAttributionData(appUserID):
            return "subscribers/\(appUserID)/attribution"

        case let .postAdServicesToken(appUserID):
            return "subscribers/\(appUserID)/adservices_attribution"

        case .postOfferForSigning:
            return "offers"

        case .postReceiptData:
            return "receipts"

        case let .postSubscriberAttributes(appUserID):
            return "subscribers/\(appUserID)/attributes"
        }
    }

}
