//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPRequestPath.swift
//
//  Created by Nacho Soto on 8/8/23.

import Foundation

protocol HTTPRequestPath {

    /// The base URL for requests to this path.
    static var serverHostURL: URL { get }

    /// Whether requests to this path are authenticated.
    var authenticated: Bool { get }

    /// Whether requests to this path can be cached using `ETagManager`.
    var shouldSendEtag: Bool { get }

    /// Whether the endpoint will perform signature verification.
    var supportsSignatureVerification: Bool { get }

    /// Whether endpoint requires a nonce for signature verification.
    var needsNonceForSigning: Bool { get }

    /// The path component for this endpoint.
    var pathComponent: String { get }

}

extension HTTPRequestPath {

    /// The full relative path for this endpoint.
    var relativePath: String {
        return "/v1/\(self.pathComponent)"
    }

    var url: URL? { return self.url(proxyURL: nil) }

    func url(proxyURL: URL? = nil) -> URL? {
        return URL(string: self.relativePath, relativeTo: proxyURL ?? Self.serverHostURL)
    }

}

// MARK: - Main paths

extension HTTPRequest {

    enum Path: Hashable {

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

    }

}

extension HTTPRequest.Path: HTTPRequestPath {

    static let serverHostURL = URL(string: "https://api.revenuecat.com")!

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
                .getProductEntitlementMapping:
            return true

        case .health:
            return false
        }
    }

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
        case .health:
            return false
        }
    }

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
                .getProductEntitlementMapping:
            return false
        }
    }

    var pathComponent: String {
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
        }
    }

    private static func escape(_ appUserID: String) -> String {
        return appUserID.trimmedAndEscaped
    }
}
