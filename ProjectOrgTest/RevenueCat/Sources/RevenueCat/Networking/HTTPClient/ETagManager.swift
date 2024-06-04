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

    static let eTagRequestHeader = HTTPClient.RequestHeader.eTag
    static let eTagValidationTimeRequestHeader = HTTPClient.RequestHeader.eTagValidationTime
    static let eTagResponseHeader = HTTPClient.ResponseHeader.eTag

    private let userDefaults: SynchronizedUserDefaults

    convenience init() {
        self.init(
            userDefaults: UserDefaults(suiteName: Self.suiteName)
            // This should never return `nil` for this known `suiteName`,
            // but `.standard` is a good fallback anyway.
            ?? UserDefaults.standard
        )
    }

    init(userDefaults: UserDefaults) {
        self.userDefaults = .init(userDefaults: userDefaults)
    }

    /// - Parameter withSignatureVerification: whether requests require a signature.
    func eTagHeader(
        for urlRequest: URLRequest,
        withSignatureVerification: Bool,
        refreshETag: Bool = false
    ) -> [String: String] {
        func eTag() -> (tag: String, date: String?)? {
            if refreshETag { return nil }
            guard let storedETagAndResponse = self.storedETagAndResponse(for: urlRequest) else {
                Logger.verbose(Strings.etag.found_no_etag(urlRequest))
                return nil
            }

            if self.shouldUseETag(storedETagAndResponse,
                                  withSignatureVerification: withSignatureVerification) {
                Logger.verbose(Strings.etag.using_etag(urlRequest,
                                                       storedETagAndResponse.eTag,
                                                       storedETagAndResponse.validationTime))

                return (tag: storedETagAndResponse.eTag,
                        date: storedETagAndResponse.validationTime?.millisecondsSince1970.description)
            } else {
                Logger.verbose(Strings.etag.not_using_etag(
                    urlRequest,
                    storedETagAndResponse.verificationResult,
                    needsSignatureVerification: withSignatureVerification

                ))
                return nil
            }
        }

        let (etag, date) = eTag() ?? ("", nil)

        return [
            HTTPClient.RequestHeader.eTag.rawValue: etag,
            HTTPClient.RequestHeader.eTagValidationTime.rawValue: date
        ]
            .compactMapValues { $0 }
    }

    /// - Returns: `response` if a cached response couldn't be fetched,
    /// or the cached `HTTPResponse`, always including the headers in `response`.
    func httpResultFromCacheOrBackend(with response: VerifiedHTTPResponse<Data?>,
                                      request: URLRequest,
                                      retried: Bool) -> VerifiedHTTPResponse<Data>? {
        let statusCode: HTTPStatusCode = response.httpStatusCode
        let resultFromBackend = response.asOptionalResponse

        guard let eTagInResponse = response.value(forHeaderField: Self.eTagResponseHeader) else {
            return resultFromBackend
        }

        if self.shouldUseCachedVersion(responseCode: statusCode) {
            if let storedResponse = self.storedETagAndResponse(for: request) {
                let newResponse = storedResponse.withUpdatedValidationTime()

                self.storeIfPossible(newResponse, for: request)
                return newResponse.asResponse(withRequestDate: response.requestDate,
                                              headers: response.responseHeaders,
                                              responseVerificationResult: response.verificationResult)
            }
            if retried {
                Logger.warn(
                    Strings.etag.could_not_find_cached_response_in_already_retried(
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
        Logger.debug(Strings.etag.clearing_cache)

        self.userDefaults.write {
            $0.removePersistentDomain(forName: ETagManager.suiteName)
        }
    }

}

extension ETagManager {

    // Visible for tests
    static func cacheKey(for request: URLRequest) -> String? {
        return request.url?.absoluteString
    }

}

// MARK: - Private

private extension ETagManager {

    func shouldUseCachedVersion(responseCode: HTTPStatusCode) -> Bool {
        responseCode == .notModified
    }

    func shouldUseETag(_ response: Response, withSignatureVerification: Bool) -> Bool {
        switch response.verificationResult {
        case .verified: return true
        case .notRequested: return !withSignatureVerification
        // This is theoretically impossible since we won't store these responses anyway.
        case .failed, .verifiedOnDevice: return false
        }
    }

    func storedETagAndResponse(for request: URLRequest) -> Response? {
        return self.userDefaults.read {
            if let cacheKey = Self.cacheKey(for: request),
               let value = $0.object(forKey: cacheKey),
               let data = value as? Data {
                return try? JSONDecoder.default.decode(Response.self, jsonData: data)
            }

            return nil
        }
    }

    func storeStatusCodeAndResponseIfNoError(for request: URLRequest,
                                             response: VerifiedHTTPResponse<Data?>,
                                             eTag: String) {
        if let data = response.body {
            if response.shouldStore {
                self.storeIfPossible(
                    Response(
                        eTag: eTag,
                        statusCode: response.httpStatusCode,
                        data: data,
                        verificationResult: response.verificationResult
                    ),
                    for: request
                )
            } else {
                Logger.verbose(Strings.etag.not_storing_etag(response))
            }
        }
    }

    func storeIfPossible(_ response: Response, for request: URLRequest) {
        if let cacheKey = Self.cacheKey(for: request),
           let dataToStore = response.asData() {
            Logger.verbose(Strings.etag.storing_response(request, response))

            self.userDefaults.write {
                $0.set(dataToStore, forKey: cacheKey)
            }
        }
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
        /// Used by the backend for advanced load shedding techniques.
        @DefaultValue<Date?>
        var validationTime: Date?
        @DefaultValue<VerificationResult>
        var verificationResult: VerificationResult

        init(
            eTag: String,
            statusCode: HTTPStatusCode,
            data: Data,
            validationTime: Date? = nil,
            verificationResult: VerificationResult
        ) {
            self.eTag = eTag
            self.statusCode = statusCode
            self.data = data
            self.validationTime = validationTime
            self.verificationResult = verificationResult
        }

    }

}

extension ETagManager.Response: Codable {}

extension ETagManager.Response {

    func asData() -> Data? {
        return try? self.jsonEncodedData
    }

    /// - Parameter responseVerificationResult: the result of the 304 response
    fileprivate func asResponse(
        withRequestDate requestDate: Date?,
        headers: HTTPClient.ResponseHeaders,
        responseVerificationResult: VerificationResult
    ) -> VerifiedHTTPResponse<Data> {
        return HTTPResponse(
            httpStatusCode: self.statusCode,
            responseHeaders: headers,
            body: self.data,
            requestDate: requestDate,
            origin: .cache
        )
        .verified(with: responseVerificationResult)
    }

    fileprivate func withUpdatedValidationTime() -> Self {
        var copy = self
        copy.validationTime = Date()

        return copy
    }

}

// MARK: -

private extension VerifiedHTTPResponse {

    var shouldStore: Bool {
        return (
            self.httpStatusCode != .notModified &&
            // Note that we do want to store 400 responses to help the server
            // If the request was wrong, it will also be wrong the next time.
            !self.httpStatusCode.isServerError &&
            self.verificationResult.shouldStore
        )
    }

}

private extension VerificationResult {

    var shouldStore: Bool {
        switch self {
        case .notRequested, .verified: return true
        case .verifiedOnDevice, .failed: return false
        }
    }

}
