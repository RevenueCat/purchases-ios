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

}
