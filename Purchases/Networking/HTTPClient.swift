//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPClient.swift
//
//  Created by César de la Vega on 7/22/21.

import Foundation

class HTTPClient {

    private let session: URLSession
    internal let systemInfo: SystemInfo
    private var queuedRequests: [HTTPRequest] = []
    private var currentSerialRequest: HTTPRequest?
    private var eTagManager: ETagManager
    private let recursiveLock = NSRecursiveLock()

    init(systemInfo: SystemInfo, eTagManager: ETagManager) {
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 1
        self.session = URLSession(configuration: config)
        self.systemInfo = systemInfo
        self.eTagManager = eTagManager
    }

    func performGETRequest(serially: Bool = true,
                           path: String,
                           headers authHeaders: [String: String],
                           completionHandler: ((Int, [String: Any]?, Error?) -> Void)?) {
        performRequest("GET",
                       serially: serially,
                       path: path,
                       requestBody: nil,
                       authHeaders: authHeaders,
                       retried: false,
                       completionHandler: completionHandler)
    }

    func performPOSTRequest(serially: Bool = true,
                            path: String,
                            requestBody: [String: Any],
                            headers authHeaders: [String: String],
                            completionHandler: ((Int, [String: Any]?, Error?) -> Void)?) {
        performRequest("POST",
                       serially: serially,
                       path: path,
                       requestBody: requestBody,
                       authHeaders: authHeaders,
                       retried: false,
                       completionHandler: completionHandler)
    }

    func clearCaches() {
        eTagManager.clearCaches()
    }

}

private extension HTTPClient {

    var defaultHeaders: [String: String] {
        let observerMode = systemInfo.finishTransactions ? "false" : "true"
        var headers: [String: String] = [
            "content-type": "application/json",
            "X-Version": SystemInfo.frameworkVersion,
            "X-Platform": SystemInfo.platformHeader,
            "X-Platform-Version": SystemInfo.systemVersion,
            "X-Platform-Flavor": systemInfo.platformFlavor,
            "X-Client-Version": SystemInfo.appVersion,
            "X-Client-Build-Version": SystemInfo.buildVersion,
            "X-StoreKit2-Enabled": "\(self.systemInfo.useStoreKit2IfAvailable)",
            "X-Observer-Mode-Enabled": observerMode
        ]

        if let platformFlavorVersion = self.systemInfo.platformFlavorVersion {
            headers["X-Platform-Flavor-Version"] = platformFlavorVersion
        }

        if let idfv = systemInfo.identifierForVendor {
            headers["X-Apple-Device-Identifier"] = idfv
        }
        return headers
    }

    // swiftlint:disable:next function_body_length
    func performRequest(_ httpMethod: String,
                        serially: Bool = true,
                        path: String,
                        requestBody maybeRequestBody: [String: Any]?,
                        authHeaders: [String: String],
                        retried: Bool = false,
                        completionHandler maybeCompletionHandler: ((Int, [String: Any]?, Error?) -> Void)?) {

        let requestHeaders = defaultHeaders.merging(authHeaders)

        let maybeURLRequest = createRequest(httpMethod: httpMethod,
                                            path: path,
                                            requestBody: maybeRequestBody,
                                            headers: requestHeaders,
                                            refreshETag: retried)

        guard let urlRequest = maybeURLRequest else {
            if let requestBody = maybeRequestBody {
                Logger.error("Could not create request to \(path) with body \(requestBody)")
            } else {
                Logger.error("Could not create request to \(path) without body")
            }

            maybeCompletionHandler?(-1, nil, ErrorUtils.networkError(withUnderlyingError: ErrorUtils.unknownError()))
            return
        }

        let request = HTTPRequest(httpMethod: httpMethod,
                                  path: path,
                                  requestBody: maybeRequestBody,
                                  authHeaders: authHeaders,
                                  retried: retried,
                                  urlRequest: urlRequest,
                                  completionHandler: maybeCompletionHandler)

        if serially && !retried {
            recursiveLock.lock()
            if currentSerialRequest != nil {
                Logger.debug(Strings.network.serial_request_queued(httpMethod: httpMethod,
                                                                   path: path,
                                                                   queuedRequestsCount: queuedRequests.count))
                queuedRequests.append(request)
                recursiveLock.unlock()
                return
            } else {
                Logger.debug(Strings.network.starting_request(httpMethod: httpMethod, path: path))
                currentSerialRequest = request
                recursiveLock.unlock()
            }
        }

        Logger.debug(Strings.network.api_request_started(httpMethod: urlRequest.httpMethod,
                                                         path: urlRequest.url?.path))

        let task = session.dataTask(with: urlRequest) { (data, urlResponse, error) -> Void in
            self.handleResponse(urlResponse: urlResponse,
                                request: request,
                                data: data,
                                error: error,
                                completion: maybeCompletionHandler,
                                beginNextRequestWhenFinished: serially,
                                retried: retried)
        }
        task.resume()
    }

    // swiftlint:disable:next function_parameter_count
    func handleResponse(urlResponse maybeURLResponse: URLResponse?,
                        request: HTTPRequest,
                        data maybeData: Data?,
                        error maybeNetworkError: Error?,
                        completion maybeCompletionHandler: ((Int, [String: Any]?, Error?) -> Void)?,
                        beginNextRequestWhenFinished: Bool,
                        retried: Bool) {
        threadUnsafeHandleResponse(urlResponse: maybeURLResponse,
                                   request: request,
                                   data: maybeData,
                                   error: maybeNetworkError,
                                   completionHandler: maybeCompletionHandler,
                                   beginNextRequestWhenFinished: beginNextRequestWhenFinished,
                                   retried: retried)
    }

    // swiftlint:disable:next function_body_length function_parameter_count
    func threadUnsafeHandleResponse(urlResponse maybeURLResponse: URLResponse?,
                                    request: HTTPRequest,
                                    data maybeData: Data?,
                                    error maybeNetworkError: Error?,
                                    completionHandler maybeCompletionHandler: ((Int, [String: Any]?, Error?) -> Void)?,
                                    beginNextRequestWhenFinished: Bool,
                                    retried: Bool) {
        var shouldBeginNextRequestWhenFinished = beginNextRequestWhenFinished
        var statusCode = HTTPStatusCodes.networkConnectTimeoutError.rawValue
        var jsonObject: [String: Any]?
        var maybeHTTPResponse: HTTPResponse? = HTTPResponse(statusCode: statusCode, jsonObject: jsonObject)
        var maybeJSONError: Error?

        if maybeNetworkError == nil {
            if let httpURLResponse = maybeURLResponse as? HTTPURLResponse {
                statusCode = httpURLResponse.statusCode
                Logger.debug(Strings.network.api_request_completed(httpMethod: request.httpMethod,
                                                                   path: request.path,
                                                                   httpCode: statusCode))

                if statusCode == HTTPStatusCodes.notModifiedResponseCode.rawValue || maybeData == nil {
                    jsonObject = [:]
                } else if let data = maybeData {
                    do {
                        jsonObject = try JSONSerialization.jsonObject(with: data,
                                                                      options: .mutableContainers) as? [String: Any]
                    } catch let jsonError {
                        Logger.error(Strings.network.parsing_json_error(error: jsonError))

                        let dataAsString = String(data: maybeData ?? Data(), encoding: .utf8) ?? ""
                        Logger.error(Strings.network.json_data_received(dataString: dataAsString))

                        maybeJSONError = jsonError
                    }
                }

                maybeHTTPResponse = self.eTagManager.httpResultFromCacheOrBackend(with: httpURLResponse,
                                                                                  jsonObject: jsonObject,
                                                                                  error: maybeJSONError,
                                                                                  request: request.urlRequest,
                                                                                  retried: retried)
                if maybeHTTPResponse == nil {
                    Logger.debug(Strings.network.retrying_request(httpMethod: request.httpMethod,
                                                                  path: request.path))
                    let retriedRequest = HTTPRequest(byCopyingRequest: request, retried: true)
                    self.queuedRequests.insert(retriedRequest, at: 0)
                    shouldBeginNextRequestWhenFinished = true
                }
            }
        }

        if DNSChecker.isBlockedAPIError(maybeNetworkError),
            let resolvedHost = DNSChecker.blockedHostFromError(maybeNetworkError) {
            Logger.error(NetworkStrings.blocked_network(newHost: resolvedHost))
        }

        if let httpResponse = maybeHTTPResponse,
            let completionHandler = maybeCompletionHandler {
            let error = maybeJSONError ?? maybeNetworkError
            completionHandler(httpResponse.statusCode, httpResponse.jsonObject, error)
        }

        if shouldBeginNextRequestWhenFinished {
            recursiveLock.lock()
            Logger.debug(Strings.network.serial_request_done(httpMethod: currentSerialRequest?.httpMethod,
                                                             path: currentSerialRequest?.path,
                                                             queuedRequestsCount: queuedRequests.count))
            self.currentSerialRequest = nil
            if !self.queuedRequests.isEmpty {
                let nextRequest = self.queuedRequests.removeFirst()
                Logger.debug(Strings.network.starting_next_request(request: nextRequest.description))
                self.performRequest(nextRequest.httpMethod,
                                    serially: true,
                                    path: nextRequest.path,
                                    requestBody: nextRequest.requestBody,
                                    authHeaders: nextRequest.authHeaders,
                                    retried: false,
                                    completionHandler: nextRequest.completionHandler)
            }
            recursiveLock.unlock()
        }
    }

    func createRequest(httpMethod: String,
                       path: String,
                       requestBody maybeRequestBody: [String: Any]?,
                       headers: [String: String],
                       refreshETag: Bool) -> URLRequest? {
        let relativeURLString = "/v1\(path)"
        guard let requestURL = URL(string: relativeURLString, relativeTo: SystemInfo.serverHostURL) else {
            return nil
        }

        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = httpMethod

        let eTagHeader = eTagManager.eTagHeader(for: urlRequest, refreshETag: refreshETag)
        let headersWithETag = headers.merging(eTagHeader)

        urlRequest.allHTTPHeaderFields = headersWithETag

        if httpMethod == "POST",
           let requestBody = maybeRequestBody {
            if JSONSerialization.isValidJSONObject(requestBody) {
                do {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                } catch {
                    Logger.error(Strings.network.creating_json_error(requestBody: requestBody,
                                                                     error: error.localizedDescription))
                    return nil
                }
            } else {
                Logger.error(Strings.network.creating_json_error_invalid(requestBody: requestBody))
                return nil
            }
        }
        return urlRequest
    }

}
