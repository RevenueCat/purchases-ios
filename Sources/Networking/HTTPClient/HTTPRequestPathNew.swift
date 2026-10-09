//
//  HTTPRequestPathNew.swift
//  RevenueCat
//
//  Created by Dave DeLong on 10/9/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

extension HTTPRequest {

    struct Path2: Hashable {

        enum ETagBehavior {
            case send
            case ignore
        }

        private static let fallbackServerHostURLs = [
            URL(string: "https://api-production.8-lives-cat.io")
        ]

        static func ==(lhs: Self, rhs: Self) -> Bool {
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
        var relativePath: String

        var iamPathComponent: String

        /// The full relative path for this endpoint when using IAM tokens.
        var relativeIAMPath: String

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
             authenticated: Bool,
             etagBehavior: ETagBehavior,
             supportsSignatureVerification: Bool,
             needsNonceForSigning: Bool,
             pathComponent: String,
             iamPathComponent: String,
             fallbackRelativePath: String? = nil,
             usesAPISources: Bool,
             isFallbackHostPath: Bool,
             additionalHeaders: HTTPRequest.Headers,
             responseSignatureContextProvider: ResponseSignatureContextProvider,
             isIAMPath: Bool) {

            self.serverHostURL = serverHostURL ?? SystemInfo.defaultApiBaseURL
            self.authenticated = authenticated
            self.etagBehavior = etagBehavior
            self.supportsSignatureVerification = supportsSignatureVerification
            self.needsNonceForSigning = needsNonceForSigning
            self.name = name
            self.pathComponent = pathComponent
            self.iamPathComponent = iamPathComponent
            self.fallbackRelativePath = fallbackRelativePath
            self.usesAPISources = usesAPISources
            self.isFallbackHostPath = isFallbackHostPath
            self.additionalHeaders = additionalHeaders
            self.responseSignatureContextProvider = responseSignatureContextProvider
            self.isIAMPath = isIAMPath

            self.relativePath = pathComponent.hasPrefix("/") ? pathComponent : "/v1/\(pathComponent)"
            self.relativeIAMPath = iamPathComponent.hasPrefix("/") ? iamPathComponent : "/v1/\(iamPathComponent)"

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

    static func getCustomerInfo(appUserID: String) ->Self {
        HTTPRequest.Path2(name: "get_customer",
                          authenticated: true,
                          etagBehavior: .send,
                          supportsSignatureVerification: true,
                          needsNonceForSigning: true,
                          pathComponent: "subscribers/\(appUserID.trimmedAndEscaped)",
                          iamPathComponent: "customer",
                          fallbackRelativePath: nil,
                          usesAPISources: true,
                          isFallbackHostPath: false,
                          additionalHeaders: [:],
                          responseSignatureContextProvider: DefaultResponseSignatureContextProvider(),
                          isIAMPath: false)
    }

}
