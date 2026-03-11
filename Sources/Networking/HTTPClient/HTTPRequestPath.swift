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

    /// The fallback URLs to use when the main server is down.
    ///
    /// Not all endpoints have a fallback URL, but some do.
    var fallbackUrls: [URL] { get }

    /// Whether requests to this path are authenticated.
    var authenticated: Bool { get }

    /// Whether requests to this path can be cached using `ETagManager`.
    var shouldSendEtag: Bool { get }

    /// Whether the endpoint will perform signature verification.
    var supportsSignatureVerification: Bool { get }

    /// Whether endpoint requires a nonce for signature verification.
    var needsNonceForSigning: Bool { get }

    /// The name of the endpoint.
    var name: String { get }

    /// The full relative path for this endpoint.
    var relativePath: String { get }

    /// The fallback relative path for this endpoint, if any.
    var fallbackRelativePath: String? { get }
}

extension HTTPRequestPath {

    var fallbackUrls: [URL] {
        return []
    }

    var supportsFallbackURLs: Bool {
        !fallbackUrls.isEmpty
    }

    var fallbackRelativePath: String? {
        return nil
    }

    /// Whether this path belongs to the IAM authentication service (uses API key, not access token).
    var isIAMAuthPath: Bool { return false }

    var url: URL? { return self.url(proxyURL: nil) }

    func url(proxyURL: URL? = nil, fallbackUrlIndex: Int? = nil) -> URL? {
        let baseURL: URL
        if let proxyURL {
            // When a Proxy URL is set, we don't support fallback URLs
            guard fallbackUrlIndex == nil else {
                // This is to safe guard against a potential infinite loop if the caller mistakenly
                // passes both a proxyURL and a fallbackUrlIndex.
                return nil
            }
            baseURL = proxyURL
        } else if let fallbackUrlIndex {
            return self.fallbackUrls[safe: fallbackUrlIndex]
        } else {
            baseURL = Self.serverHostURL
        }
        return URL(string: self.relativePath, relativeTo: baseURL)
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
        case appHealthReport(appUserID: String)
        case appHealthReportAvailability(appUserID: String)
        case getProductEntitlementMapping
        case getCustomerCenterConfig(appUserID: String)
        case getVirtualCurrencies(appUserID: String)
        case postRedeemWebPurchase
        case postCreateTicket
        case isPurchaseAllowedByRestoreBehavior(appUserID: String)

    }

    enum FeatureEventsPath: Hashable {

        case postEvents

    }

    enum DiagnosticsPath: Hashable {

        case postDiagnostics

    }

    enum WebBillingPath: Hashable {

        case getWebOfferingProducts(appUserID: String)
        case getWebBillingProducts(userId: String, productIds: Set<String>)

    }

    enum AdPath: Hashable {

        case postEvents

    }

    /// Paths for the IAM authentication service (`/auth/...`).
    ///
    /// These endpoints use the API key for authentication (not the IAM access token).
    enum IAMAuthPath: Hashable {

        /// POST /auth/login — establishes an IAM session.
        case login

        /// POST /auth/token — refreshes an IAM access token.
        case token

    }

    /// Customer paths used in IAM mode (`/v1/customer/...`).
    ///
    /// These paths replace the legacy `/v1/subscribers/<app_user_id>/...` paths
    /// when IAM mode is enabled.  The app_user_id is no longer part of the URL
    /// because the identity is carried in the Bearer access token.
    enum IAMCustomerPath: Hashable {

        case getCustomerInfo
        case getOfferings
        case getIntroEligibility
        case postSubscriberAttributes
        case postAttributionData
        case postAdServicesToken
        case appHealthReport
        case getCustomerCenterConfig
        case isPurchaseAllowedByRestoreBehavior

    }

}

extension HTTPRequest.Path: HTTPRequestPath {

    static var serverHostURL: URL {
        SystemInfo.apiBaseURL
    }

    private static let fallbackServerHostURLs = [
        URL(string: "https://api-production.8-lives-cat.io")
    ]

    var fallbackRelativePath: String? {
        switch self {
        case .getOfferings:
            return "/v1/offerings"
        case .getProductEntitlementMapping:
            return "/v1/product_entitlement_mapping"
        default:
            return nil
        }
    }

    var fallbackUrls: [URL] {
        guard let fallbackRelativePath = self.fallbackRelativePath else {
            return []
        }

        return Self.fallbackServerHostURLs.compactMap { baseURL in
            guard let baseURL = baseURL,
                  let fallbackUrl = URL(string: fallbackRelativePath, relativeTo: baseURL) else {
                let errorMessage = "Invalid fallback URL configuration for path: \(self.name)"
                assertionFailure(errorMessage)
                Logger.error(errorMessage)
                return nil
            }
            return fallbackUrl
        }
    }

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
                .getCustomerCenterConfig,
                .getVirtualCurrencies,
                .appHealthReport,
                .postCreateTicket,
                .isPurchaseAllowedByRestoreBehavior:
            return true

        case .health,
             .appHealthReportAvailability:
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
                .getCustomerCenterConfig,
                .getVirtualCurrencies,
                .appHealthReport,
                .postCreateTicket,
                .isPurchaseAllowedByRestoreBehavior:
            return true
        case .health,
             .appHealthReportAvailability:
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
                .getProductEntitlementMapping,
                .getVirtualCurrencies,
                .appHealthReport,
                .appHealthReportAvailability,
                .isPurchaseAllowedByRestoreBehavior:
            return true
        case .getIntroEligibility,
                .postSubscriberAttributes,
                .postAttributionData,
                .postAdServicesToken,
                .postOfferForSigning,
                .postRedeemWebPurchase,
                .getCustomerCenterConfig,
                .postCreateTicket:
            return false
        }
    }

    var needsNonceForSigning: Bool {
        switch self {
        case .getCustomerInfo,
                .logIn,
                .postReceiptData,
                .getVirtualCurrencies,
                .health,
                .appHealthReportAvailability,
                .isPurchaseAllowedByRestoreBehavior:
            return true
        case .getOfferings,
                .getIntroEligibility,
                .postSubscriberAttributes,
                .postAttributionData,
                .postAdServicesToken,
                .postOfferForSigning,
                .postRedeemWebPurchase,
                .getProductEntitlementMapping,
                .getCustomerCenterConfig,
                .appHealthReport,
                .postCreateTicket:
            return false
        }
    }

    var relativePath: String {
        return "/v1/\(self.pathComponent)"
    }

    var pathComponent: String {
        switch self {
        case let .getCustomerInfo(appUserID):
            return "subscribers/\(Self.escape(appUserID))"

        case let .getOfferings(appUserID):
            return "subscribers/\(Self.escape(appUserID))/offerings"

        case let .getIntroEligibility(appUserID):
            return "subscribers/\(Self.escape(appUserID))/intro_eligibility"

        case let .appHealthReport(appUserID):
            return "subscribers/\(Self.escape(appUserID))/health_report"

        case let .appHealthReportAvailability(appUserID):
            return "subscribers/\(Self.escape(appUserID))/health_report_availability"

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

        case let .getVirtualCurrencies(appUserID):
            return "subscribers/\(Self.escape(appUserID))/virtual_currencies"

        case .postCreateTicket:
            return "customercenter/support/create-ticket"
        case let .isPurchaseAllowedByRestoreBehavior(appUserID):
            return "subscribers/\(Self.escape(appUserID))/restore/eligibility"
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

        case .appHealthReport:
            return "get_app_health_report"

        case .getVirtualCurrencies:
            return "get_virtual_currencies"

        case .appHealthReportAvailability:
            return "get_app_health_report_availability"

        case .postCreateTicket:
            return "post_create_ticket"
        case .isPurchaseAllowedByRestoreBehavior:
            return "post_restore_eligibility"
        }
    }

    private static func escape(_ appUserID: String) -> String {
        return appUserID.trimmedAndEscaped
    }
}

// MARK: - IAMAuthPath conformance

extension HTTPRequest.IAMAuthPath: HTTPRequestPath {

    static var serverHostURL: URL {
        SystemInfo.apiBaseURL
    }

    var isIAMAuthPath: Bool { return true }

    var authenticated: Bool { return true }

    var shouldSendEtag: Bool { return false }

    var supportsSignatureVerification: Bool { return false }

    var needsNonceForSigning: Bool { return false }

    var relativePath: String {
        switch self {
        case .login: return "/auth/login"
        case .token: return "/auth/token"
        }
    }

    var name: String {
        switch self {
        case .login: return "iam_login"
        case .token: return "iam_token"
        }
    }

}

// MARK: - IAMCustomerPath conformance

extension HTTPRequest.IAMCustomerPath: HTTPRequestPath {

    static var serverHostURL: URL {
        SystemInfo.apiBaseURL
    }

    var authenticated: Bool { return true }

    var shouldSendEtag: Bool { return true }

    var supportsSignatureVerification: Bool { return false }

    var needsNonceForSigning: Bool { return false }

    var relativePath: String {
        return "/v1/\(self.pathComponent)"
    }

    var pathComponent: String {
        switch self {
        case .getCustomerInfo:
            return "customer"

        case .getOfferings:
            return "customer/offerings"

        case .getIntroEligibility:
            return "customer/intro_eligibility"

        case .postSubscriberAttributes:
            return "customer/attributes"

        case .postAttributionData:
            return "customer/attribution"

        case .postAdServicesToken:
            return "customer/adservices_attribution"

        case .appHealthReport:
            return "customer/health_report"

        case .getCustomerCenterConfig:
            return "customer/customercenter"

        case .isPurchaseAllowedByRestoreBehavior:
            return "customer/restore/eligibility"
        }
    }

    var name: String {
        switch self {
        case .getCustomerInfo:
            return "iam_get_customer"

        case .getOfferings:
            return "iam_get_offerings"

        case .getIntroEligibility:
            return "iam_get_intro_eligibility"

        case .postSubscriberAttributes:
            return "iam_post_attributes"

        case .postAttributionData:
            return "iam_post_attribution"

        case .postAdServicesToken:
            return "iam_post_adservices_token"

        case .appHealthReport:
            return "iam_get_app_health_report"

        case .getCustomerCenterConfig:
            return "iam_customer_center"

        case .isPurchaseAllowedByRestoreBehavior:
            return "iam_post_restore_eligibility"
        }
    }

}
