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

import Foundation

/// A request to be made by ``HTTPClient``
struct HTTPRequest {

    let method: Method
    let path: Path
    /// If present, this will be used by the server to compute a checksum of the response signed with a private key.
    let nonce: Data?

    init(method: Method, path: Path) {
        self.init(method: method, path: path, nonce: nil)
    }

    init(method: Method, path: Path, nonce: Data?) {
        assert(nonce == nil || nonce?.count == Data.nonceLength,
               "Invalid nonce: \(nonce?.description ?? "")")

        self.method = method
        self.path = path
        self.nonce = nonce
    }

    /// Creates an `HTTPRequest` with a `nonce`.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    static func createIntegrityEnforcedRequestRequest(method: Method, path: Path) -> Self {
        return .init(method: method, path: path, nonce: Data.randomNonce())
    }

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
        case health

    }

}

extension HTTPRequest.Path {

    /// Whether requests to this path are authenticated.
    var authenticated: Bool {
        switch self {
        case .getCustomerInfo,
                .getOfferings,
                .getIntroEligibility,
                .logIn,
                .postAttributionData,
                .postOfferForSigning,
                .postReceiptData,
                .postSubscriberAttributes,
                .postAdServicesToken:
            return true

        case .health:
            return false
        }
    }

    /// Whether requests to this path can be cached using `ETagManager`
    var shouldSendEtag: Bool {
        switch self {
        case .getCustomerInfo,
                .getOfferings,
                .getIntroEligibility,
                .logIn,
                .postAttributionData,
                .postOfferForSigning,
                .postReceiptData,
                .postSubscriberAttributes,
                .postAdServicesToken:
            return true
        case .health:
            return false
        }
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

        case .health:
            return "health"
        }
    }

}
