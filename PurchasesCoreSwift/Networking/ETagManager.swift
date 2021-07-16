//
// Created by César de la Vega on 4/16/21.
//

import Foundation

@objc(RCETagManager) public class ETagManager: NSObject {
    internal static let eTagHeaderName = "X-RevenueCat-ETag"

    private let queue = DispatchQueue(label: "ETagManager")

    private let userDefaults: UserDefaults

    @objc public override init() {
        self.userDefaults = UserDefaults(suiteName: ETagManager.suiteName) ?? UserDefaults.standard
    }

    @objc public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    @objc public func eTagHeader(for urlRequest: URLRequest, refreshETag: Bool = false) -> [String: String] {
        var storedETag = ""
        if !refreshETag, let storedETagAndResponse = storedETagAndResponse(for: urlRequest) {
            storedETag = storedETagAndResponse.eTag
        }
        return [ETagManager.eTagHeaderName: storedETag]
    }

    @objc public func httpResultFromCacheOrBackend(with response: HTTPURLResponse,
                                                   jsonObject: [String: Any]?,
                                                   error: Error?,
                                                   request: URLRequest,
                                                   retried: Bool) -> HTTPResponse? {
        let statusCode = response.statusCode
        let resultFromBackend = HTTPResponse(statusCode: statusCode, jsonObject: jsonObject)
        guard error == nil else { return resultFromBackend }
        let headersInResponse = response.allHeaderFields

        let maybeETagInResponse: String? = headersInResponse[ETagManager.eTagHeaderName] as? String ??
                headersInResponse[ETagManager.eTagHeaderName.lowercased()] as? String

        guard let eTagInResponse = maybeETagInResponse else { return resultFromBackend }
        if shouldUseCachedVersion(responseCode: statusCode) {
            if let storedResponse = storedHTTPResponse(for: request) {
                return storedResponse
            }
            if retried {
                Logger.warn(String(format: Strings.network.could_not_find_cached_response_in_already_retried,
                        resultFromBackend))
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

    @objc public func clearCaches() {
        self.userDefaults.removePersistentDomain(forName: ETagManager.suiteName)
    }

}

private extension ETagManager {

    func shouldUseCachedVersion(responseCode: Int) -> Bool {
        responseCode == HTTPStatusCodes.notModifiedResponseCode.rawValue
    }

    func storedETagAndResponse(for request: URLRequest) -> ETagAndResponseWrapper? {
        if let cacheKey = eTagDefaultCacheKey(for: request),
            let value = userDefaults.object(forKey: cacheKey),
            let data = value as? Data {
                return ETagAndResponseWrapper(with: data)
            }

        return nil
    }

    func storedHTTPResponse(for request: URLRequest) -> HTTPResponse? {
        if let storedETagAndResponse = storedETagAndResponse(for: request) {
            return HTTPResponse(
                    statusCode: storedETagAndResponse.statusCode,
                    jsonObject: storedETagAndResponse.jsonObject)
        }

        return nil
    }

    func storeStatusCodeAndResponseIfNoError(for request: URLRequest,
                                             statusCode: Int,
                                             responseObject: [String: Any]?,
                                             eTag: String) {
        if statusCode != HTTPStatusCodes.notModifiedResponseCode.rawValue &&
            statusCode < HTTPStatusCodes.internalServerError.rawValue,
           let responseObject = responseObject,
           let cacheKey = eTagDefaultCacheKey(for: request) {
            let eTagAndResponse =
                ETagAndResponseWrapper(eTag: eTag, statusCode: statusCode, jsonObject: responseObject)
            if let dataToStore = eTagAndResponse.asData() {
                userDefaults.set(dataToStore, forKey: cacheKey)
            }
        }
    }

    func eTagDefaultCacheKey(for request: URLRequest) -> String? {
        return request.url?.absoluteString
    }

    private static let suiteNameBase: String  = "revenuecat.etags"
    static var suiteName: String {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return suiteNameBase
        }
        return bundleID + ".\(suiteNameBase)"
    }
}
