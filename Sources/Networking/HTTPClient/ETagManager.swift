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

    static let eTagHeaderName = "X-RevenueCat-ETag"

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

    func eTagHeader(for urlRequest: URLRequest, refreshETag: Bool = false) -> [String: String] {
        var storedETag = ""
        if !refreshETag, let storedETagAndResponse = storedETagAndResponse(for: urlRequest) {
            storedETag = storedETagAndResponse.eTag
        }
        return [ETagManager.eTagHeaderName: storedETag]
    }

    func httpResultFromCacheOrBackend(with response: HTTPURLResponse,
                                      data: Data?,
                                      request: URLRequest,
                                      retried: Bool) -> HTTPResponse<Data>? {
        let statusCode: HTTPStatusCode = .init(rawValue: response.statusCode)
        let resultFromBackend = HTTPResponse(statusCode: statusCode, body: data)
            .asOptionalResponse

        let headersInResponse = response.allHeaderFields

        let eTagInResponse: String? = headersInResponse[ETagManager.eTagHeaderName] as? String ??
        headersInResponse[ETagManager.eTagHeaderName.lowercased()] as? String

        guard let eTagInResponse = eTagInResponse else { return resultFromBackend }
        if shouldUseCachedVersion(responseCode: statusCode) {
            if let storedResponse = storedHTTPResponse(for: request) {
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
        storeStatusCodeAndResponseIfNoError(
                for: request,
                statusCode: statusCode,
                data: data,
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

    func storedHTTPResponse(for request: URLRequest) -> HTTPResponse<Data>? {
        return storedETagAndResponse(for: request)?.asResponse
    }

    func storeStatusCodeAndResponseIfNoError(for request: URLRequest,
                                             statusCode: HTTPStatusCode,
                                             data: Data?,
                                             eTag: String) {
        if let data = data, statusCode != .notModified && !statusCode.isServerError,
           let cacheKey = eTagDefaultCacheKey(for: request) {
            let eTagAndResponse = Response(eTag: eTag, statusCode: statusCode, data: data)
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

        let eTag: String
        let statusCode: HTTPStatusCode
        let data: Data

    }

}

extension ETagManager.Response: Codable {}

extension ETagManager.Response {

    func asData() -> Data? {
        return try? JSONEncoder.default.encode(self)
    }

    fileprivate var asResponse: HTTPResponse<Data> {
        return HTTPResponse(
            statusCode: self.statusCode,
            body: self.data
        )
    }
}
