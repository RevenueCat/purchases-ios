//
//  HTTPRequestPathNew.swift
//  RevenueCat
//
//  Created by Dave DeLong on 10/9/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

extension HTTPRequest {

    struct Path2: Hashable {

        // swiftlint:disable:next nesting
        enum ETagBehavior {
            case send
            case ignore
        }

        private static let fallbackServerHostURLs = [
            URL(string: "https://api-production.8-lives-cat.io")
        ]

        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.name == rhs.name &&
                   lhs.serverHostURL == rhs.serverHostURL &&
                   lhs.relativePath == rhs.relativePath
        }

        /// The base URL for requests to this path.
        var serverHostURL: URL

        /// The fallback URLs to use when the main server is down.
        ///
        /// Not all endpoints have a fallback URL, but some do.
        var fallbackUrls: [URL]

        /// Whether requests to this path are authenticated.
        var authenticated: Bool

        /// Whether requests to this path can be cached using `ETagManager`.
        var etagBehavior: ETagBehavior

        /// Whether the endpoint will perform signature verification.
        var supportsSignatureVerification: Bool

        /// Whether endpoint requires a nonce for signature verification.
        var needsNonceForSigning: Bool

        /// The name of the endpoint.
        var name: String

        var pathComponent: String

        /// The full relative path for this endpoint.
        var relativePath: String {
            pathComponent.hasPrefix("/") ? pathComponent : "/v1/\(pathComponent)"
        }

        var iamPathComponent: String

        /// The full relative path for this endpoint when using IAM tokens.
        var relativeIAMPath: String {
            iamPathComponent.hasPrefix("/") ? iamPathComponent : "/v1/\(iamPathComponent)"
        }

        /// The fallback relative path for this endpoint, if any.
        var fallbackRelativePath: String?

        /// Whether this path resolves its base host from the API source provider (the main-API host
        /// list with failover) rather than the static `serverHostURL`.
        var usesAPISources: Bool

        /// Whether this path's `serverHostURL` is a fallback host rather than the main API host.
        ///
        /// Requests to such a path are fallback attempts from the very first try, even though
        /// `HTTPClient`'s own fallback walk never started, so they must not be treated as main-source
        /// requests when picking a timeout or updating the per-host fail-fast memory.
        var isFallbackHostPath: Bool

        /// Additional headers specific to this endpoint.
        var additionalHeaders: HTTPRequest.Headers

        /// Provides endpoint-specific inputs for response signature verification.
        var responseSignatureContextProvider: ResponseSignatureContextProvider

        /// Whether this path corresponds to an IAM request
        var isIAMPath: Bool

        init(name: String,
             serverHostURL: URL? = nil,
             authenticated: Bool = true,
             etagBehavior: ETagBehavior,
             supportsSignatureVerification: Bool,
             needsNonceForSigning: Bool,
             pathComponent: String,
             iamPathComponent: String? = nil,
             fallbackRelativePath: String? = nil,
             usesAPISources: Bool = true,
             isFallbackHostPath: Bool = false,
             additionalHeaders: HTTPRequest.Headers = [:],
             responseSignatureContextProvider: ResponseSignatureContextProvider? = nil,
             isIAMPath: Bool = false) {

            self.serverHostURL = serverHostURL ?? Self.serverHostURL
            self.authenticated = authenticated
            self.etagBehavior = etagBehavior
            self.supportsSignatureVerification = supportsSignatureVerification
            self.needsNonceForSigning = needsNonceForSigning
            self.name = name
            self.pathComponent = pathComponent
            self.iamPathComponent = (iamPathComponent ?? pathComponent)
            self.fallbackRelativePath = fallbackRelativePath
            self.usesAPISources = usesAPISources
            self.isFallbackHostPath = isFallbackHostPath
            self.additionalHeaders = additionalHeaders

            let signatureContextProvider = responseSignatureContextProvider ?? DefaultResponseSignatureContextProvider()
            self.responseSignatureContextProvider = signatureContextProvider

            self.isIAMPath = isIAMPath

            if let fallbackRelativePath {
                self.fallbackUrls = Self.fallbackServerHostURLs.compactMap { baseURL in
                    guard let baseURL = baseURL,
                          let fallbackUrl = URL(string: fallbackRelativePath, relativeTo: baseURL) else {
                        let errorMessage = "Invalid fallback URL configuration for path: \(name)"
                        assertionFailure(errorMessage)
                        Logger.error(errorMessage)
                        return nil
                    }
                    return fallbackUrl
                }
            } else {
                self.fallbackUrls = []
            }

            return
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(pathComponent)
        }

    }

}

extension HTTPRequest.Path2: HTTPRequestPath {
    static var serverHostURL: URL { SystemInfo.apiBaseURL }
    var shouldSendEtag: Bool { etagBehavior == .send }
}

extension HTTPRequest.Path2 {

    // swiftlint:disable:next force_unwrapping
    private static let remoteConfigFallbackHost = URL(string: "https://api-production.8-lives-cat.io")!

    // swiftlint:disable:next force_unwrapping
    private static let apiDiagnosticsHost = URL(string: "https://api-diagnostics.revenuecat.com")!

    // swiftlint:disable:next force_unwrapping
    private static let postFeatureEventsHost = URL(string: "https://api-paywalls.revenuecat.com")!

    // swiftlint:disable:next force_unwrapping
    private static let postAdEventsHost = URL(string: "https://a.revenue.cat")!

    static func getCustomerInfo(appUserID: String) -> Self {
        HTTPRequest.Path2(name: "get_customer",
                          etagBehavior: .send,
                          supportsSignatureVerification: true,
                          needsNonceForSigning: true,
                          pathComponent: "subscribers/\(appUserID.trimmedAndEscaped)",
                          iamPathComponent: "customer")
    }

    static func getOfferings(appUserID: String) -> Self {
        HTTPRequest.Path2(name: "get_offerings",
                          etagBehavior: .send,
                          supportsSignatureVerification: true,
                          needsNonceForSigning: false,
                          pathComponent: "subscribers/\(appUserID.trimmedAndEscaped)/offerings",
                          iamPathComponent: "customer/offerings",
                          fallbackRelativePath: "/v1/offerings")
    }

    static func getIntroEligibility(appUserID: String) -> Self {
        HTTPRequest.Path2(name: "get_intro_eligibility",
                          etagBehavior: .send,
                          supportsSignatureVerification: false,
                          needsNonceForSigning: false,
                          pathComponent: "subscribers/\(appUserID.trimmedAndEscaped)/intro_eligibility",
                          iamPathComponent: "customer/intro_eligibility")
    }

    static func remoteConfigFallback(domain: String) -> Self {
        HTTPRequest.Path2(name: "remote_config_fallback",
                          serverHostURL: remoteConfigFallbackHost,
                          etagBehavior: .send,
                          supportsSignatureVerification: true,
                          needsNonceForSigning: false,
                          pathComponent: "config/\(domain.trimmedAndEscaped)",
                          fallbackRelativePath: nil,
                          usesAPISources: false,
                          isFallbackHostPath: true,
                          responseSignatureContextProvider: FallbackSignatureContextProvider())
    }

    static let postDiagnostics = HTTPRequest.Path2(name: "post_diagnostics",
                                                   serverHostURL: apiDiagnosticsHost,
                                                   etagBehavior: .ignore,
                                                   supportsSignatureVerification: false,
                                                   needsNonceForSigning: false,
                                                   pathComponent: "diagnostics",
                                                   usesAPISources: false)

    static let postFeatureEvents = HTTPRequest.Path2(name: "post_paywall_events",
                                                     serverHostURL: postFeatureEventsHost,
                                                     etagBehavior: .ignore,
                                                     supportsSignatureVerification: false,
                                                     needsNonceForSigning: false,
                                                     pathComponent: "events",
                                                     usesAPISources: false)

    static let postAdEvents = HTTPRequest.Path2(name: "post_ad_events",
                                                serverHostURL: postAdEventsHost,
                                                etagBehavior: .ignore,
                                                supportsSignatureVerification: false,
                                                needsNonceForSigning: false,
                                                pathComponent: "events",
                                                usesAPISources: false)

    static func postAttributionData(appUserID: String) -> Self {
        HTTPRequest.Path2(name: "post_attribution",
                          etagBehavior: .send,
                          supportsSignatureVerification: false,
                          needsNonceForSigning: false,
                          pathComponent: "subscribers/\(appUserID.trimmedAndEscaped)/attribution",
                          iamPathComponent: "customer/attribution")
    }

    static let postOfferForSigning = HTTPRequest.Path2(name: "post_offer_for_signing",
                                                       etagBehavior: .send,
                                                       supportsSignatureVerification: false,
                                                       needsNonceForSigning: false,
                                                       pathComponent: "offers")

    static let postReceiptData = HTTPRequest.Path2(name: "post_receipt",
                                                   etagBehavior: .send,
                                                   supportsSignatureVerification: true,
                                                   needsNonceForSigning: true,
                                                   pathComponent: "receipts")

    static func postSubscriberAttributes(appUserID: String) -> Self {
        HTTPRequest.Path2(name: "post_attributes",
                          etagBehavior: .send,
                          supportsSignatureVerification: false,
                          needsNonceForSigning: false,
                          pathComponent: "subscribers/\(appUserID.trimmedAndEscaped)/attributes",
                          iamPathComponent: "customer/attributes")
    }

    static func postAdServicesToken(appUserID: String) -> Self {
        HTTPRequest.Path2(name: "post_adservices_token",
                          etagBehavior: .send,
                          supportsSignatureVerification: false,
                          needsNonceForSigning: false,
                          pathComponent: "subscribers/\(appUserID.trimmedAndEscaped)/adservices_attribution",
                          iamPathComponent: "customer/adservices_attribution")
    }

    static func appHealthReport(appUserID: String) -> Self {
        HTTPRequest.Path2(name: "get_app_health_report",
                          etagBehavior: .send,
                          supportsSignatureVerification: true,
                          needsNonceForSigning: false,
                          pathComponent: "subscribers/\(appUserID.trimmedAndEscaped)/health_report",
                          iamPathComponent: "customer/health_report")
    }

    static func appHealthReportAvailability(appUserID: String) -> Self {
        HTTPRequest.Path2(name: "get_app_health_report_availability",
                          authenticated: false,
                          etagBehavior: .ignore,
                          supportsSignatureVerification: true,
                          needsNonceForSigning: true,
                          pathComponent: "subscribers/\(appUserID.trimmedAndEscaped)/health_report_availability")
    }

    static let getProductEntitlementMapping = HTTPRequest.Path2(name: "get_product_entitlement_mapping",
                                                                etagBehavior: .send,
                                                                supportsSignatureVerification: true,
                                                                needsNonceForSigning: false,
                                                                pathComponent: "product_entitlement_mapping",
                                                                fallbackRelativePath: "/v1/product_entitlement_mapping")

    static func getCustomerCenterConfig(appUserID: String) -> Self {
        HTTPRequest.Path2(name: "customer_center",
                          etagBehavior: .send,
                          supportsSignatureVerification: false,
                          needsNonceForSigning: false,
                          pathComponent: "customercenter/\(appUserID.trimmedAndEscaped)",
                          iamPathComponent: "customer/customercenter")
    }

    static func getVirtualCurrencies(appUserID: String) -> Self {
        HTTPRequest.Path2(name: "get_virtual_currencies",
                          etagBehavior: .send,
                          supportsSignatureVerification: true,
                          needsNonceForSigning: true,
                          pathComponent: "subscribers/\(appUserID.trimmedAndEscaped)/virtual_currencies",
                          iamPathComponent: "customer/virtual_currencies")
    }

    static let spendVirtualCurrencies = HTTPRequest.Path2(name: "spend_virtual_currencies",
                                                          etagBehavior: .send,
                                                          supportsSignatureVerification: true,
                                                          needsNonceForSigning: true,
                                                          pathComponent: "customer/virtual_currencies/spend")

    static let postRedeemWebPurchase = HTTPRequest.Path2(name: "post_redeem_web_purchase",
                                                         etagBehavior: .send,
                                                         supportsSignatureVerification: true,
                                                         needsNonceForSigning: true,
                                                         pathComponent: "subscribers/redeem_purchase")

    static let postExternalPurchaseToken = HTTPRequest.Path2(name: "post_external_purchase_token",
                                                             authenticated: true,
                                                             etagBehavior: .ignore,
                                                             supportsSignatureVerification: false,
                                                             needsNonceForSigning: false,
                                                             pathComponent: "external_purchase_tokens")

    static let postCreateTicket = HTTPRequest.Path2(name: "post_create_ticket",
                                                    etagBehavior: .send,
                                                    supportsSignatureVerification: false,
                                                    needsNonceForSigning: false,
                                                    pathComponent: "customercenter/support/create-ticket")

    static func isPurchaseAllowedByRestoreBehavior(appUserID: String) -> Self {
        HTTPRequest.Path2(name: "post_restore_eligibility",
                          etagBehavior: .send,
                          supportsSignatureVerification: true,
                          needsNonceForSigning: true,
                          pathComponent: "subscribers/\(appUserID.trimmedAndEscaped)/restore/eligibility",
                          iamPathComponent: "customer/restore/eligibility")
    }

    static func rewardVerificationStatus(appUserID: String, clientTransactionID: String, adUnitID: String?) -> Self {
        let txn = clientTransactionID.trimmedAndEscaped
        var path = "subscribers/\(appUserID.trimmedAndEscaped)/ads/reward_verifications/\(txn)"
        if let adUnitID = adUnitID?.notEmptyOrWhitespaces,
           let encodedAdUnitID = adUnitID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            path += "?ad_unit_id=\(encodedAdUnitID)"
        }

        return HTTPRequest.Path2(name: "get_reward_verification_status",
                                 etagBehavior: .send,
                                 supportsSignatureVerification: true,
                                 needsNonceForSigning: true,
                                 pathComponent: path)
    }

    static func remoteConfig(domain: String) -> Self {
        HTTPRequest.Path2(name: "remote_config",
                          etagBehavior: .ignore,
                          supportsSignatureVerification: true,
                          needsNonceForSigning: true,
                          pathComponent: "config/\(domain.trimmedAndEscaped)",
                          additionalHeaders: [
                            HTTPClient.RequestHeader.accept.rawValue: HTTPClient.rcContainerFormatAcceptHeaderValue,
                            HTTPClient.RequestHeader.acceptRCElementEncoding.rawValue:
                                HTTPClient.rcContainerFormatElementEncodingHeaderValue
                          ],
                          responseSignatureContextProvider: RemoteConfigSignatureContextProvider())
    }

    static func getWebOfferingProducts(appUserID: String) -> Self {
        HTTPRequest.Path2(name: "get_web_offering_products",
                          etagBehavior: .send,
                          supportsSignatureVerification: false,
                          needsNonceForSigning: false,
                          pathComponent: "/rcbilling/v1/subscribers/\(appUserID.trimmedAndEscaped)/offering_products",
                          iamPathComponent: "/rcbilling/v1/customer/offering_products")
    }
}
