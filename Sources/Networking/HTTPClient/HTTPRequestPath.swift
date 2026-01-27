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

    var url: URL? { return self.url(proxyURL: nil) }

    func url(proxyURL: URL? = nil, fallbackUrlIndex: Int? = nil, iamEnabled: Bool = false) -> URL? {
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
        return URL(string: self.relativePath(iamEnabled: iamEnabled), relativeTo: baseURL)
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
        case iamLogin
        case iamToken

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
                .iamLogin,
                .iamToken:
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
                .postCreateTicket:
            return true
        case .health,
             .appHealthReportAvailability,
             .iamLogin,
             .iamToken:
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
                .iamLogin,
                .iamToken:
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
                .iamLogin,
                .iamToken:
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
        return self.relativePath(iamEnabled: false)
    }

    func relativePath(iamEnabled: Bool) -> String {
        switch self {
        case .iamLogin, .iamToken:
            // IAM endpoints use /auth base path instead of /v1
            return "/auth/\(self.pathComponent(iamEnabled: iamEnabled))"
        default:
            return "/v1/\(self.pathComponent(iamEnabled: iamEnabled))"
        }
    }

    var pathComponent: String {
        return self.pathComponent(iamEnabled: false)
    }

    func pathComponent(iamEnabled: Bool) -> String {
        switch self {
        case let .getCustomerInfo(appUserID):
            // IAM: /v1/customer (no app_user_id in path)
            // Legacy: /v1/subscribers/{app_user_id}
            return iamEnabled ? "customer" : "subscribers/\(Self.escape(appUserID))"

        case let .getOfferings(appUserID):
            // This endpoint doesn't change with IAM
            return "subscribers/\(Self.escape(appUserID))/offerings"

        case let .getIntroEligibility(appUserID):
            // IAM: /v1/customer/intro_eligibility
            // Legacy: /v1/subscribers/{app_user_id}/intro_eligibility
            return iamEnabled ? "customer/intro_eligibility" : "subscribers/\(Self.escape(appUserID))/intro_eligibility"

        case let .appHealthReport(appUserID):
            // This endpoint doesn't change with IAM
            return "subscribers/\(Self.escape(appUserID))/health_report"

        case let .appHealthReportAvailability(appUserID):
            // This endpoint doesn't change with IAM
            return "subscribers/\(Self.escape(appUserID))/health_report_availability"

        case .logIn:
            // This endpoint doesn't change with IAM
            return "subscribers/identify"

        case let .postAttributionData(appUserID):
            // This endpoint doesn't change with IAM
            return "subscribers/\(Self.escape(appUserID))/attribution"

        case let .postAdServicesToken(appUserID):
            // This endpoint doesn't change with IAM
            return "subscribers/\(Self.escape(appUserID))/adservices_attribution"

        case .postOfferForSigning:
            return "offers"

        case .postReceiptData:
            return "receipts"

        case let .postSubscriberAttributes(appUserID):
            // IAM: /v1/customer/attributes
            // Legacy: /v1/subscribers/{app_user_id}/attributes
            return iamEnabled ? "customer/attributes" : "subscribers/\(Self.escape(appUserID))/attributes"

        case .health:
            return "health"

        case .getProductEntitlementMapping:
            return "product_entitlement_mapping"

        case let .getCustomerCenterConfig(appUserID):
            // IAM: /v1/customer/customercenter
            // Legacy: /v1/customercenter/{app_user_id}
            return iamEnabled ? "customer/customercenter" : "customercenter/\(Self.escape(appUserID))"

        case .postRedeemWebPurchase:
            // IAM: /v1/customer/redeem_web_purchase
            // Legacy: /v1/subscribers/redeem_purchase
            return iamEnabled ? "customer/redeem_web_purchase" : "subscribers/redeem_purchase"

        case let .getVirtualCurrencies(appUserID):
            // IAM: /v1/customer/virtual_currencies
            // Legacy: /v1/subscribers/{app_user_id}/virtual_currencies
            return iamEnabled ? "customer/virtual_currencies" : "subscribers/\(Self.escape(appUserID))/virtual_currencies"

        case .postCreateTicket:
            // This endpoint doesn't change with IAM
            return "customercenter/support/create-ticket"

        case .iamLogin:
            return "login"

        case .iamToken:
            return "token"
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

        case .iamLogin:
            return "iam_login"

        case .iamToken:
            return "iam_token"

        }
    }

    private static func escape(_ appUserID: String) -> String {
        return appUserID.trimmedAndEscaped
    }
}
