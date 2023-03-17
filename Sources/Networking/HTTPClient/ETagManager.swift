//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ETagManager.swift
//
//  Created by César de la Vega on 4/16/21.
//

import Foundation

class ETagManager {

    static let eTagRequestHeaderName = HTTPClient.RequestHeader.eTag.rawValue
    static let eTagResponseHeaderName = HTTPClient.ResponseHeader.eTag.rawValue

    private let userDefaults: SynchronizedUserDefaults
    private let verificationMode: Signing.ResponseVerificationMode

    convenience init(verificationMode: Signing.ResponseVerificationMode) {
        self.init(
            userDefaults: UserDefaults(suiteName: Self.suiteName)
            // This should never return `nil` for this known `suiteName`,
            // but `.standard` is a good fallback anyway.
            ?? UserDefaults.standard,
            verificationMode: verificationMode
        )
    }

    init(userDefaults: UserDefaults, verificationMode: Signing.ResponseVerificationMode) {
        self.userDefaults = .init(userDefaults: userDefaults)
        self.verificationMode = verificationMode
    }

    /// - Parameter withSignatureVerification: whether the request contains a nonce.
    func eTagHeader(
        for urlRequest: URLRequest,
        withSignatureVerification: Bool,
        refreshETag: Bool = false
    ) -> [String: String] {
        func eTag() -> String? {
            if refreshETag { return nil }
            guard let storedETagAndResponse = self.storedETagAndResponse(for: urlRequest) else { return nil }

            let shouldUseETag = (
                !withSignatureVerification ||
                self.shouldIgnoreVerificationErrors ||
                storedETagAndResponse.verificationResult == .verified
            )

            return shouldUseETag ? storedETagAndResponse.eTag : nil
        }

        return [HTTPClient.RequestHeader.eTag.rawValue: eTag() ?? ""]
    }

    func httpResultFromCacheOrBackend(with response: HTTPResponse<Data?>,
                                      request: URLRequest,
                                      retried: Bool) -> HTTPResponse<Data>? {
        let statusCode: HTTPStatusCode = response.statusCode
        let resultFromBackend = response.asOptionalResponse

        let eTagInResponse = response.value(forHeaderField: HTTPClient.ResponseHeader.eTag.rawValue)

        guard let eTagInResponse = eTagInResponse else { return resultFromBackend }

        if self.shouldUseCachedVersion(responseCode: statusCode) {
            if let storedResponse = self.storedHTTPResponse(for: request, withRequestDate: response.requestDate) {
                return storedResponse
            }
            if retried {
                Logger.warn(
                    Strings.network.could_not_find_cached_response_in_already_retried(
                        response: resultFromBackend?.description ?? ""
                    )
                )
                return resultFromBackend
            }
            return nil
        }

        self.storeStatusCodeAndResponseIfNoError(
            for: request,
            response: response,
            eTag: eTagInResponse
        )
        return resultFromBackend
    }

    func clearCaches() {
        self.userDefaults.write {
            $0.removePersistentDomain(forName: ETagManager.suiteName)
        }
    }

}

private extension ETagManager {

    func shouldUseCachedVersion(responseCode: HTTPStatusCode) -> Bool {
        responseCode == .notModified
    }

    func storedETagAndResponse(for request: URLRequest) -> Response? {
        return self.userDefaults.read {
            if let cacheKey = eTagDefaultCacheKey(for: request),
               let value = $0.object(forKey: cacheKey),
               let data = value as? Data {
                return try? JSONDecoder.default.decode(Response.self, jsonData: data)
            }

            return nil
        }
    }

    func storedHTTPResponse(for request: URLRequest, withRequestDate requestDate: Date?) -> HTTPResponse<Data>? {
        return self.storedETagAndResponse(for: request)?.asResponse(withRequestDate: requestDate)
    }

    func storeStatusCodeAndResponseIfNoError(for request: URLRequest,
                                             response: HTTPResponse<Data?>,
                                             eTag: String) {
        if let data = response.body,
           response.shouldStore(ignoreVerificationErrors: self.shouldIgnoreVerificationErrors),
           let cacheKey = self.eTagDefaultCacheKey(for: request) {
            let eTagAndResponse = Response(
                eTag: eTag,
                statusCode: response.statusCode,
                data: data,
                verificationResult: response.verificationResult
            )
            if let dataToStore = eTagAndResponse.asData() {
                self.userDefaults.write {
                    $0.set(dataToStore, forKey: cacheKey)
                }
            }
        }
    }

    func eTagDefaultCacheKey(for request: URLRequest) -> String? {
        return request.url?.absoluteString
    }

    var shouldIgnoreVerificationErrors: Bool {
        return !self.verificationMode.isEnabled
    }

    static let suiteNameBase: String  = "revenuecat.etags"
    static var suiteName: String {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return suiteNameBase
        }
        return bundleID + ".\(suiteNameBase)"
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension ETagManager: @unchecked Sendable {}

// MARK: Response

extension ETagManager {

    struct Response {

        var eTag: String
        var statusCode: HTTPStatusCode
        var data: Data
        @DefaultValue<VerificationResult>
        var verificationResult: VerificationResult

        init(
            eTag: String,
            statusCode: HTTPStatusCode,
            data: Data,
            verificationResult: VerificationResult
        ) {
            self.eTag = eTag
            self.statusCode = statusCode
            self.data = data
            self.verificationResult = verificationResult
        }

    }

}

extension ETagManager.Response: Codable {}

extension ETagManager.Response {

    func asData() -> Data? {
        return try? JSONEncoder.default.encode(self)
    }

    fileprivate func asResponse(withRequestDate requestDate: Date?) -> HTTPResponse<Data> {
        return HTTPResponse(
            statusCode: self.statusCode,
            responseHeaders: [:],
            body: self.data,
            requestDate: requestDate,
            verificationResult: self.verificationResult
        )
    }

}

// MARK: -

private extension HTTPResponse {

    func shouldStore(ignoreVerificationErrors: Bool) -> Bool {
        return (
            self.statusCode != .notModified &&
            !self.statusCode.isServerError &&
            (ignoreVerificationErrors || self.verificationResult != .failed)
        )
    }

}
