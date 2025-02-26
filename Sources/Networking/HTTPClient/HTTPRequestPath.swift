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

    /// The name of the endpoint.
    var name: String { get }

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
        case getCustomerCenterConfig(appUserID: String)
        case postRedeemWebPurchase

    }

    enum PaywallPath: Hashable {

        case postEvents

    }

    enum DiagnosticsPath: Hashable {

        case postDiagnostics

    }

}

extension HTTPRequest.Path: HTTPRequestPath {

    // swiftlint:disable:next force_unwrapping
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
                .postRedeemWebPurchase,
                .getProductEntitlementMapping,
                .getCustomerCenterConfig:
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
                .postRedeemWebPurchase,
                .getProductEntitlementMapping,
                .getCustomerCenterConfig:
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
                .postOfferForSigning,
                .postRedeemWebPurchase,
                .getCustomerCenterConfig:
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
                .postRedeemWebPurchase,
                .getProductEntitlementMapping,
                .getCustomerCenterConfig:
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

        case let .getCustomerCenterConfig(appUserID):
            return "customercenter/\(Self.escape(appUserID))"

        case .postRedeemWebPurchase:
            return "subscribers/redeem_purchase"

        }
    }

    var name: String {
        switch self {
        case .getCustomerInfo:
            return "get_customer"

        case .getOfferings:
            return "get_offerings"

        case .getIntroEligibility:
            return "get_intro_eligibility"

        case .logIn:
            return "log_in"

        case .postAttributionData:
            return "post_attribution"

        case .postAdServicesToken:
            return "post_adservices_token"

        case .postOfferForSigning:
            return "post_offer_for_signing"

        case .postReceiptData:
            return "post_receipt"

        case .postSubscriberAttributes:
            return "post_attributes"

        case .health:
            return "post_health"

        case .getProductEntitlementMapping:
            return "get_product_entitlement_mapping"

        case .getCustomerCenterConfig:
            return "customer_center"

        case .postRedeemWebPurchase:
            return "post_redeem_web_purchase"

        }
    }

    private static func escape(_ appUserID: String) -> String {
        return appUserID.trimmedAndEscaped
    }
}
