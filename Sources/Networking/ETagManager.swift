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
            userDefaults: UserDefaults(suiteName: ETagManager.suiteName) ?? UserDefaults.standard
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
                                      jsonObject: [String: Any],
                                      request: URLRequest,
                                      retried: Bool) -> HTTPResponse? {
        let statusCode: HTTPStatusCode = .init(rawValue: response.statusCode)
        let resultFromBackend = HTTPResponse(statusCode: statusCode, jsonObject: jsonObject)

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
                        response: resultFromBackend.description
                    )
                )
                return resultFromBackend
            }
            return nil
        }
        storeStatusCodeAndResponseIfNoError(
                for: request,
                statusCode: statusCode,
                responseObject: jsonObject,
                eTag: eTagInResponse)
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

    func storedETagAndResponse(for request: URLRequest) -> ETagAndResponseWrapper? {
        return self.userDefaults.read {
            if let cacheKey = eTagDefaultCacheKey(for: request),
               let value = $0.object(forKey: cacheKey),
               let data = value as? Data {
                return ETagAndResponseWrapper(with: data)
            }

            return nil
        }
    }

    func storedHTTPResponse(for request: URLRequest) -> HTTPResponse? {
        if let storedETagAndResponse = storedETagAndResponse(for: request) {
            return HTTPResponse(
                    statusCode: storedETagAndResponse.statusCode,
                    jsonObject: storedETagAndResponse.jsonObject
            )
        }

        return nil
    }

    func storeStatusCodeAndResponseIfNoError(for request: URLRequest,
                                             statusCode: HTTPStatusCode,
                                             responseObject: [String: Any]?,
                                             eTag: String) {
        if statusCode != .notModified && !statusCode.isServerError,
           let responseObject = responseObject,
           let cacheKey = eTagDefaultCacheKey(for: request) {
            let eTagAndResponse = ETagAndResponseWrapper(eTag: eTag, statusCode: statusCode, jsonObject: responseObject)
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
