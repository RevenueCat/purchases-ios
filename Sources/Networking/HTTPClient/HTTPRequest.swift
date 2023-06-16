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

    typealias Headers = [String: String]

    var method: Method
    var path: Path
    /// If present, this will be used by the server to compute a checksum of the response signed with a private key.
    var nonce: Data?

    init(method: Method, path: Path, nonce: Data? = nil) {
        assert(nonce == nil || nonce?.count == Data.nonceLength,
               "Invalid nonce: \(nonce?.description ?? "")")

        self.method = method
        self.path = path
        self.nonce = nonce
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension HTTPRequest {

    /// Creates an `HTTPRequest` with a `nonce`.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    static func createWithResponseVerification(method: Method, path: Path) -> Self {
        return .init(method: method, path: path, nonce: Data.randomNonce())
    }

    /// Add a nonce to the request
    mutating func addRandomNonce() {
        self.nonce = Data.randomNonce()
    }

}

// MARK: - Method

extension HTTPRequest {

    enum Method {

        case get
        case post(HTTPRequestBody)

    }

}

extension HTTPRequest {

    var requestBody: HTTPRequestBody? {
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
        case getProductEntitlementMapping
        case postDiagnostics

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
                .postAdServicesToken,
                .getProductEntitlementMapping,
                .postDiagnostics:
            return true

        case .health:
            return false
        }
    }

    /// Whether requests to this path can be cached using `ETagManager`.
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
                .postAdServicesToken,
                .getProductEntitlementMapping:
            return true
        case .health,
                .postDiagnostics:
            return false
        }
    }

    /// Whether the endpoint will perform signature verification.
    var supportsSignatureVerification: Bool {
        switch self {
        case .getCustomerInfo,
                .logIn,
                .postReceiptData,
                .health,
                .getOfferings,
                .getProductEntitlementMapping:
            return true
        case .getIntroEligibility,
                .postSubscriberAttributes,
                .postAttributionData,
                .postAdServicesToken,
                .postOfferForSigning:
            return false
        }
    }

    /// Whether endpoint requires a nonce for signature verification.
    var needsNonceForSigning: Bool {
        switch self {
        case .getCustomerInfo,
                .logIn,
                .postReceiptData,
                .health:
            return true
        case .getOfferings,
                .getIntroEligibility,
                .postSubscriberAttributes,
                .postAttributionData,
                .postAdServicesToken,
                .postOfferForSigning,
                .getProductEntitlementMapping,
                .postDiagnostics:
            return false
        }
    }

}

extension HTTPRequest.Path: Hashable {}

extension HTTPRequest.Path: CustomStringConvertible {

    var description: String {
        switch self {
        case let .getCustomerInfo(appUserID):
            return "subscribers/\(Self.escape(appUserID))"

        case let .getOfferings(appUserID):
            return "subscribers/\(Self.escape(appUserID))/offerings"

        case let .getIntroEligibility(appUserID):
            return "subscribers/\(Self.escape(appUserID))/intro_eligibility"

        case .logIn:
            return "subscribers/identify"

        case let .postAttributionData(appUserID):
            return "subscribers/\(Self.escape(appUserID))/attribution"

        case let .postAdServicesToken(appUserID):
            return "subscribers/\(Self.escape(appUserID))/adservices_attribution"

        case .postOfferForSigning:
            return "offers"

        case .postReceiptData:
            return "receipts"

        case let .postSubscriberAttributes(appUserID):
            return "subscribers/\(Self.escape(appUserID))/attributes"

        case .health:
            return "health"

        case .getProductEntitlementMapping:
            return "product_entitlement_mapping"

        case .postDiagnostics:
            return "diagnostics"
        }
    }

    private static func escape(_ appUserID: String) -> String {
        return appUserID.trimmedAndEscaped
    }

}
