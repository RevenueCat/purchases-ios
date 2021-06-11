//
// Created by César de la Vega on 4/16/21.
//

import Foundation

internal let ETAG_HEADER_NAME: String = "X-RevenueCat-ETag"

@objc(RCETagManager) public class ETagManager: NSObject {
    private let queue = DispatchQueue(label: "ETagManager")

    private var userDefaults: UserDefaults

    @objc public override init() {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        self.userDefaults = UserDefaults(suiteName: bundleID + ".revenuecat.etags") ?? UserDefaults.standard
    }
    
    @objc public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    @objc public func getETagHeader(for urlRequest: URLRequest, refreshETag: Bool = false) -> [String: String] {
        var storedETag = ""
        if (!refreshETag) {
            if let storedETagAndResponse = getStoredETagAndResponse(for: urlRequest) {
                storedETag = storedETagAndResponse.eTag
            }
        }
        return [ETAG_HEADER_NAME: storedETag]
    }

    @objc public func getHTTPResultFromCacheOrBackend(with statusCode: Int,
                                                      responseObject: [String: Any]?,
                                                      error: Error?,
                                                      headersInResponse: [String: Any],
                                                      request: URLRequest,
                                                      retried: Bool) -> HTTPResponse? {
        let resultFromBackend = HTTPResponse(statusCode: statusCode, responseObject: responseObject)
        if error != nil {
            return resultFromBackend
        }
        
        var eTagInResponse: String? = headersInResponse[ETAG_HEADER_NAME] as! String?
        if ((eTagInResponse == nil)) {
            eTagInResponse = headersInResponse[ETAG_HEADER_NAME.lowercased()] as! String?
        }
        
        if (eTagInResponse != nil) {
            if (shouldUseCachedVersion(responseCode: statusCode)) {
                guard let storedResponse = getStoredHTTPResponse(for: request) else {
                    if (retried) {
                        Logger.warn(
                                String(
                                        format: Strings.network.could_not_find_cached_response_in_already_retried,
                                        resultFromBackend
                                )
                        )
                        return resultFromBackend
                    } else {
                        return nil
                    }
                }
                return storedResponse
            }
            storeStatusCodeAndResponseIfNoError(
                    for: request,
                    statusCode: statusCode,
                    responseObject: responseObject,
                    eTag: eTagInResponse!)
        }

        return resultFromBackend
    }

    @objc public func clearCaches() {
        if let bundleID = Bundle.main.bundleIdentifier {
            self.userDefaults.removePersistentDomain(forName: bundleID + ".revenuecat.etags")
        }
    }

    private func shouldUseCachedVersion(responseCode: Int) -> Bool {
        responseCode == HTTPStatusCodes.notModifiedResponseCode.rawValue
    }

    private func getStoredETagAndResponse(for request: URLRequest) -> ETagAndResponseWrapper? {
        if let cacheKey = eTagDefaultCacheKey(for: request) {
            if let data = userDefaults.object(forKey: cacheKey) as! Data? {
                do {
                    return try ETagAndResponseWrapper(with: data)
                } catch {
                }
            }
        }

        return nil
    }

    private func getStoredHTTPResponse(for request: URLRequest) -> HTTPResponse? {
        if let storedETagAndResponse = getStoredETagAndResponse(for: request) {
            return HTTPResponse(
                    statusCode: storedETagAndResponse.statusCode,
                    responseObject: storedETagAndResponse.responseObject)
        }

        return nil
    }

    private func storeStatusCodeAndResponseIfNoError(for request: URLRequest,
                                                     statusCode: Int,
                                                     responseObject: [String: Any]?,
                                                     eTag: String) {
        if statusCode != HTTPStatusCodes.notModifiedResponseCode.rawValue &&
                   statusCode < HTTPStatusCodes.internalServerError.rawValue &&
                   responseObject != nil {
            if let cacheKey = eTagDefaultCacheKey(for: request) {
                let eTagAndResponse =
                        ETagAndResponseWrapper(eTag: eTag, statusCode: statusCode, responseObject: responseObject!)
                if let dataToStore = eTagAndResponse.asData() {
                    userDefaults.set(dataToStore, forKey: cacheKey)
                }
            }
        }
    }

    private func eTagDefaultCacheKey(for request: URLRequest) -> String? {
        if let url = request.url?.absoluteString {
            return url
        }
        return nil
    }

}

let ETAG_KEY = "eTag"
let STATUS_CODE_KEY = "statusCode"
let RESPONSE_OBJECT_KEY = "responseObject"

internal class ETagAndResponseWrapper {

    let eTag: String
    let statusCode: Int
    let responseObject: Dictionary<String, Any>

    init(eTag: String, statusCode: Int, responseObject: Dictionary<String, Any>) {
        self.eTag = eTag
        self.statusCode = statusCode
        self.responseObject = responseObject
    }

    convenience init(with data: Data) throws {
        let dictionary =
                try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! Dictionary<String, Any>
        self.init(dictionary: dictionary)
    }

    convenience init(dictionary: Dictionary<String, Any>) {
        let eTag = dictionary[ETAG_KEY] as! String
        let statusCode = dictionary[STATUS_CODE_KEY] as! Int
        let responseObject = dictionary[RESPONSE_OBJECT_KEY] as! Dictionary<String, Any>
        self.init(eTag: eTag, statusCode: statusCode, responseObject: responseObject)
    }

    func asDictionary() -> Dictionary<String, Any> {
        [
            ETAG_KEY: eTag,
            STATUS_CODE_KEY: statusCode,
            RESPONSE_OBJECT_KEY: responseObject
        ]
    }

    func asData() -> Data? {
        let dictionary = asDictionary()
        if JSONSerialization.isValidJSONObject(dictionary) {
            do {
                return try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
            } catch {
                return nil
            }
        }
        return nil
    }
}
