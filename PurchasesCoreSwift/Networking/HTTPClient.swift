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

// TODO (post-migration): set this back to internal
@objc(RCHTTPClient) public class HTTPClient: NSObject {

    private let accessQueue = DispatchQueue(label: "HTTPClientQueue", attributes: .concurrent)

    let session: URLSession
    let systemInfo: SystemInfo
    var queuedRequests: [HTTPRequest] = []
    var currentSerialRequest: HTTPRequest?
    var eTagManager: ETagManager

    @objc public init(systemInfo: SystemInfo, eTagManager: ETagManager) {
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 1
        self.session = URLSession(configuration: config)
        self.systemInfo = systemInfo
        self.eTagManager = eTagManager
    }

    // TODO:(post-migration) remove and use only the private performRequest
    @objc public func performRequest(_ httpMethod: String,
                                     performSerially: Bool = false,
                                     path: String,
                                     requestBody: [String: Any]?,
                                     headers: [String: String]?,
                                     completionHandler: HTTPClientResponseHandler?) {
        performRequest(httpMethod,
                       performSerially: performSerially,
                       path: path,
                       requestBody: requestBody,
                       headers: headers,
                       retried: false,
                       completionHandler: completionHandler)
    }

    @objc public func clearCaches() {
        self.eTagManager.clearCaches()
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
            "X-Observer-Mode-Enabled": observerMode
        ]

        if let platformFlavorVersion = self.systemInfo.platformFlavorVersion {
            headers["X-Platform-Flavor-Version"] = platformFlavorVersion
        }

        if let idfv = SystemInfo.identifierForVendor {
            headers["X-Apple-Device-Identifier"] = idfv
        }
        return headers
    }

    func performRequest(_ httpMethod: String,
                        performSerially: Bool = false,
                        path: String,
                        requestBody: [String: Any]?,
                        headers: [String: String]?,
                        retried: Bool = false,
                        completionHandler: HTTPClientResponseHandler?) {
        do {
            try assertIsValidRequest(httpMethod: httpMethod, requestBody: requestBody)
        } catch let error {
            if let maybeCompletionHandler = completionHandler {
                maybeCompletionHandler(-1, nil, error)
            }
        }

        var requestHeaders = defaultHeaders
        if let maybeHeaders = headers {
            requestHeaders = requestHeaders.merging(maybeHeaders, uniquingKeysWith: { (_, last) in last })
        }

        let urlRequest = createRequest(httpMethod: httpMethod, path: path, requestBody: requestBody,
                                       headers: requestHeaders, refreshETag: retried)

        guard let maybeURLRequest = urlRequest else {
            if let maybeRequestBody = requestBody {
                Logger.error("Could not create request to \(path) with body \(maybeRequestBody)")
            } else {
                Logger.error("Could not create request to \(path) without body")
            }
            if let maybeCompletionHandler = completionHandler {
                maybeCompletionHandler(-1, nil, ErrorUtils.networkError(withUnderlyingError: ErrorUtils.unknownError()))
            }
            return
        }

        let rcRequest = HTTPRequest(httpMethod: httpMethod, path: path, requestBody: requestBody, headers: headers,
                                    retried: retried, completionHandler: completionHandler)

        if performSerially && !retried {
            accessQueue.sync(flags: .barrier) { [self] in
                if self.currentSerialRequest != nil {
                    let message =
                        String(format: Strings.network.serial_request_queued, self.queuedRequests.count, httpMethod, path)
                    Logger.debug(message)
                    self.queuedRequests.append(rcRequest)
                    return
                } else {
                    let message = String(format: Strings.network.starting_request, httpMethod, path)
                    Logger.debug(message)
                    self.currentSerialRequest = rcRequest
                }
            }
        }

        let message =
            String(format: Strings.network.api_request_started,
                   maybeURLRequest.httpMethod ?? "",
                   maybeURLRequest.url?.path ?? "")
        Logger.debug(message)

        let task = session.dataTask(with: maybeURLRequest) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            self.handleResponse(response: response,
                                data: data,
                                error: error,
                                request: maybeURLRequest,
                                completionHandler: completionHandler,
                                beginNextRequestWhenFinished: performSerially,
                                queableRequest: rcRequest,
                                retried: retried)
        }
        task.resume()
    }

    // swiftlint:disable function_parameter_count
    func handleResponse(response: URLResponse?,
                        data: Data?,
                        error: Error?,
                        request: URLRequest,
                        completionHandler: HTTPClientResponseHandler?,
                        beginNextRequestWhenFinished: Bool,
                        queableRequest: HTTPRequest,
                        retried: Bool) {
        var shouldBeginNextRequestWhenFinished = beginNextRequestWhenFinished
        var statusCode = HTTPStatusCodes.networkConnectTimeoutError.rawValue
        var jsonObject: [String: Any]?
        var httpResponse: HTTPResponse? = HTTPResponse(statusCode: statusCode, jsonObject: jsonObject)

        var maybeError = error
        if maybeError == nil {
            if let httpURLResponse = response as? HTTPURLResponse {
                statusCode = httpURLResponse.statusCode
                let message =
                    String(format: Strings.network.api_request_completed,
                           request.httpMethod ?? "", request.url?.path ?? "", statusCode)
                Logger.debug(message)

                var jsonError: Error?
                if statusCode == HTTPStatusCodes.notModifiedResponseCode.rawValue || data == nil {
                    jsonObject = [:]
                } else if let maybeData = data {
                    do {
                        jsonObject =
                            try JSONSerialization.jsonObject(with: maybeData,
                                                             options: .mutableContainers) as? [String: Any]
                    } catch let error {
                        jsonError = error
                    }
                }

                if let maybeJSONError = jsonError {
                    Logger.error(String(format: Strings.network.parsing_json_error, maybeJSONError.localizedDescription))
                    let dataAsString = String(data: data ?? Data(), encoding: .utf8) ?? ""
                    let message = String(format: Strings.network.json_data_received, dataAsString)
                    Logger.error(message)

                    maybeError = jsonError
                }

                httpResponse = eTagManager.httpResultFromCacheOrBackend(with: httpURLResponse,
                                                                        jsonObject: jsonObject, error: maybeError, request: request, retried: retried)
                if httpResponse == nil {
                    accessQueue.sync(flags: .barrier) { [self] in
                        let message = String(format: Strings.network.retrying_request, queableRequest.httpMethod,
                                             queableRequest.path)
                        Logger.debug(message)
                        let retriedRequest = HTTPRequest(RCHTTPRequest: queableRequest, retried: true)
                        queuedRequests.insert(retriedRequest, at: 0)
                        shouldBeginNextRequestWhenFinished = true
                    }
                }
            }
        }

        if let maybeHTTPResponse = httpResponse,
           let maybeCompletionHandler = completionHandler {
            maybeCompletionHandler(maybeHTTPResponse.statusCode, maybeHTTPResponse.jsonObject, maybeError)
        }

        if shouldBeginNextRequestWhenFinished {
            var nextRequest: HTTPRequest?
            accessQueue.sync(flags: .barrier) { [self] in
                let message = String(
                    format: Strings.network.serial_request_done,
                    self.currentSerialRequest?.httpMethod ?? "",
                    self.currentSerialRequest?.path ?? "",
                    self.queuedRequests.count)
                Logger.debug(message)
                self.currentSerialRequest = nil
                if !self.queuedRequests.isEmpty {
                    nextRequest = self.queuedRequests[0]
                    self.queuedRequests.remove(at: 0)
                }
            }
            if let maybeNextRequest = nextRequest {
                Logger.debug(String(format: Strings.network.starting_next_request, maybeNextRequest))
                self.performRequest(maybeNextRequest.httpMethod, performSerially: true,
                                    path: maybeNextRequest.path, requestBody: maybeNextRequest.requestBody,
                                    headers: maybeNextRequest.headers, completionHandler: maybeNextRequest.completionHandler)
            }
        }
    }

    func createRequest(httpMethod: String,
                       path: String,
                       requestBody: [AnyHashable: Any]?,
                       headers: [String: String],
                       refreshETag: Bool) -> URLRequest? {
        let relativeURLString = "/v1\(path)"
        guard let requestURL = URL(string: relativeURLString, relativeTo: SystemInfo.serverHostURL) else {
            return nil
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = httpMethod

        let eTagHeader = eTagManager.eTagHeader(for: request, refreshETag: refreshETag)
        let headersWithETag = headers.merging(eTagHeader) { (_, last) -> String in
            last
        }

        request.allHTTPHeaderFields = headersWithETag

        if httpMethod == "POST" {
            if let maybeRequestBody = requestBody {
                var jsonParseError: Error?
                let isValidJSONObject = JSONSerialization.isValidJSONObject(maybeRequestBody)
                if isValidJSONObject {
                    do {
                        request.httpBody =
                            try JSONSerialization.data(withJSONObject: maybeRequestBody)
                    } catch let error {
                        jsonParseError = error
                    }
                }
                if !isValidJSONObject || jsonParseError != nil {
                    Logger.error(String(format: Strings.network.creating_json_error, maybeRequestBody))
                    return nil
                }
            }
        }
        return request
    }

    func assertIsValidRequest(httpMethod: String, requestBody: [String: Any]?) throws {
        if httpMethod != "GET" && httpMethod != "POST" ||
            httpMethod == "GET" && requestBody != nil ||
            httpMethod == "POST" && requestBody == nil {
            throw HTTPClientError.invalidNetworkCall(httpMethod, requestBody: requestBody)
        }
    }

}

enum HTTPClientError: Error {
    case invalidNetworkCall(_ httpMethod: String, requestBody: [String: Any]?)
}

extension HTTPClientError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidNetworkCall(let httpMethod, let requestBody):
            if requestBody == nil {
                return "invalid network call with method \(httpMethod) and empty body"
            } else {
                return "invalid network call with method \(httpMethod) and not an empty body"
            }
        }
    }
}
