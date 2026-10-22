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

    /// The base URL for this request's path.
    ///
    /// Defaults to `Self.serverHostURL`.
    var serverHostURL: URL { get }

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

    /// The full relative path for this endpoint when using IAM tokens.
    var relativeIAMPath: String { get }

    /// The fallback relative path for this endpoint, if any.
    var fallbackRelativePath: String? { get }

    /// Whether this path resolves its base host from the API source provider (the main-API host
    /// list with failover) rather than the static `serverHostURL`.
    var usesAPISources: Bool { get }

    /// Whether this path's `serverHostURL` is a fallback host rather than the main API host.
    ///
    /// Requests to such a path are fallback attempts from the very first try, even though
    /// `HTTPClient`'s own fallback walk never started, so they must not be treated as main-source
    /// requests when picking a timeout or updating the per-host fail-fast memory.
    var isFallbackHostPath: Bool { get }

    /// Additional headers specific to this endpoint.
    var additionalHeaders: HTTPRequest.Headers { get }

    /// Provides endpoint-specific inputs for response signature verification.
    var responseSignatureContextProvider: ResponseSignatureContextProvider { get }

    /// Whether this path corresponds to an IAM request
    var isIAMPath: Bool { get }
}

/// Provides endpoint-specific inputs for backend response signature verification.
///
/// Most endpoints use the raw response body and request body. Specialized endpoints can override
/// either input.
protocol ResponseSignatureContextProvider {

    /// Returns the response bytes that should be verified against the backend signature.
    ///
    /// This may throw when deriving the signed payload requires validating response structure first.
    func responsePayloadForSignature(from body: Data?, statusCode: HTTPStatusCode) throws -> Data?

    /// Returns the request body component to include in signature parameters, if any.
    func requestBodyForSignature(for request: HTTPRequest) -> HTTPRequestBody?

}

struct DefaultResponseSignatureContextProvider: ResponseSignatureContextProvider {

    func responsePayloadForSignature(from body: Data?, statusCode: HTTPStatusCode) throws -> Data? {
        return body
    }

    func requestBodyForSignature(for request: HTTPRequest) -> HTTPRequestBody? {
        return request.requestBody
    }

}

extension HTTPRequestPath {

    var serverHostURL: URL { Self.serverHostURL }

    var fallbackUrls: [URL] {
        return []
    }

    var supportsFallbackURLs: Bool {
        !fallbackUrls.isEmpty
    }

    var fallbackRelativePath: String? {
        return nil
    }

    var relativeIAMPath: String {
        return self.relativePath
    }

    var usesAPISources: Bool {
        return false
    }

    var isFallbackHostPath: Bool {
        return false
    }

    var additionalHeaders: HTTPRequest.Headers {
        return [:]
    }

    var responseSignatureContextProvider: ResponseSignatureContextProvider {
        return DefaultResponseSignatureContextProvider()
    }

    var isIAMPath: Bool {
        return false
    }

    func url(proxyURL: URL? = nil,
             apiSourceURL: URL? = nil,
             fallbackUrlIndex: Int? = nil,
             preferIAMPath: Bool) -> URL? {
        let baseURL: URL
        if let proxyURL {
            // When a Proxy URL is set, we don't support API sources or fallback URLs
            guard fallbackUrlIndex == nil, apiSourceURL == nil else {
                // This is to safe guard against a potential infinite loop if the caller mistakenly
                // passes a proxyURL together with an apiSourceURL or a fallbackUrlIndex.
                return nil
            }
            baseURL = proxyURL
        } else if let fallbackUrlIndex {
            return self.fallbackUrls[safe: fallbackUrlIndex]
        } else if let apiSourceURL {
            baseURL = apiSourceURL
        } else {
            baseURL = self.serverHostURL
        }

        let path = preferIAMPath ? self.relativeIAMPath : self.relativePath
        return URL(string: path, relativeTo: baseURL)
    }
}
