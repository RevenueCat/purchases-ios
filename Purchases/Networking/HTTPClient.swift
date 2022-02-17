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
    private var queuedRequests: [Request] = []
    private var currentSerialRequest: Request?
    private let eTagManager: ETagManager
    private let recursiveLock = NSRecursiveLock()
    private let dnsChecker: DNSCheckerType.Type

    init(
        systemInfo: SystemInfo,
        eTagManager: ETagManager,
        dnsChecker: DNSCheckerType.Type = DNSChecker.self
    ) {
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 1
        self.session = URLSession(configuration: config)
        self.systemInfo = systemInfo
        self.eTagManager = eTagManager
        self.dnsChecker = dnsChecker
    }

    func performGETRequest(serially: Bool = true,
                           path: String,
                           headers authHeaders: [String: String],
                           completionHandler: ((Int, [String: Any]?, Error?) -> Void)?) {
        perform(request: .init(method: .get,
                               path: path,
                               headers: authHeaders,
                               completionHandler: completionHandler),
                serially: serially)
    }

    func performPOSTRequest(serially: Bool = true,
                            path: String,
                            requestBody: [String: Any],
                            headers authHeaders: [String: String],
                            completionHandler: ((Int, [String: Any]?, Error?) -> Void)?) {
        perform(request: .init(method: .post(body: requestBody),
                               path: path,
                               headers: authHeaders,
                               completionHandler: completionHandler),
                serially: serially)
    }

    func clearCaches() {
        eTagManager.clearCaches()
    }

}

private extension HTTPClient {

    // swiftlint:disable nesting
    struct Request: CustomStringConvertible {

        typealias Headers = [String: String]
        typealias RequestBody = [String: Any]
        typealias Completion = ((_ statusCode: Int, _ response: [String: Any]?, _ error: Error?) -> Void)

        enum Method {

            case get
            case post(body: RequestBody)

            var httpMethod: String {
                switch self {
                case .get: return "GET"
                case .post: return "POST"
                }
            }

        }

        var method: Method
        var path: String
        var headers: Headers
        var completionHandler: Completion?
        var retried: Bool = false

        var requestBody: RequestBody? {
            switch self.method {
            case let .post(body): return body
            case .get: return nil
            }
        }

        func adding(defaultHeaders: Headers) -> Self {
            var copy = self
            copy.headers = defaultHeaders.merging(self.headers)

            return copy
        }

        func retriedRequest() -> Self {
            var copy = self
            copy.retried = true

            return copy
        }

        var description: String {
            """
            <\(type(of: self)): httpMethod=\(self.method.httpMethod)
            path=\(self.path)
            requestBody=\(self.requestBody?.description ?? "(null)")
            headers=\(self.headers.description )
            retried=\(self.retried)
            >
            """
        }
    }
    // swiftlint:enable nesting

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

    func perform(request: Request,
                 serially: Bool = true) {
        let urlRequest = convert(request: request.adding(defaultHeaders: self.defaultHeaders))

        guard let urlRequest = urlRequest else {
            if case let .post(requestBody) = request.method {
                Logger.error("Could not create request to \(request.path) with body \(requestBody)")
            } else {
                Logger.error("Could not create request to \(request.path) without body")
            }

            request.completionHandler?(-1, nil, ErrorUtils.networkError(withUnderlyingError: ErrorUtils.unknownError()))
            return
        }

        if serially && !request.retried {
            recursiveLock.lock()
            if currentSerialRequest != nil {
                Logger.debug(Strings.network.serial_request_queued(httpMethod: request.method.httpMethod,
                                                                   path: request.path,
                                                                   queuedRequestsCount: queuedRequests.count))
                queuedRequests.append(request)
                recursiveLock.unlock()
                return
            } else {
                Logger.debug(Strings.network.starting_request(httpMethod: request.method.httpMethod,
                                                              path: request.path))
                currentSerialRequest = request
                recursiveLock.unlock()
            }
        }

        Logger.debug(Strings.network.api_request_started(httpMethod: urlRequest.httpMethod,
                                                         path: urlRequest.url?.path))

        let task = session.dataTask(with: urlRequest) { (data, urlResponse, error) -> Void in
            self.handle(urlResponse: urlResponse,
                        request: request,
                        urlRequest: urlRequest,
                        data: data,
                        error: error,
                        beginNextRequestWhenFinished: serially)
        }
        task.resume()
    }

    // swiftlint:disable:next function_body_length function_parameter_count
    func handle(urlResponse: URLResponse?,
                request: Request,
                urlRequest: URLRequest,
                data: Data?,
                error networkError: Error?,
                beginNextRequestWhenFinished: Bool) {
        var shouldBeginNextRequestWhenFinished = beginNextRequestWhenFinished
        var statusCode = HTTPStatusCodes.networkConnectTimeoutError.rawValue
        var jsonObject: [String: Any]?
        var httpResponse: HTTPResponse? = HTTPResponse(statusCode: statusCode, jsonObject: jsonObject)
        var receivedJSONError: Error?

        if networkError == nil {
            if let httpURLResponse = urlResponse as? HTTPURLResponse {
                statusCode = httpURLResponse.statusCode
                Logger.debug(Strings.network.api_request_completed(httpMethod: request.method.httpMethod,
                                                                   path: request.path,
                                                                   httpCode: statusCode))

                if statusCode == HTTPStatusCodes.notModifiedResponseCode.rawValue || data == nil {
                    jsonObject = [:]
                } else if let data = data {
                    do {
                        jsonObject = try JSONSerialization.jsonObject(with: data,
                                                                      options: .mutableContainers) as? [String: Any]
                    } catch let jsonError {
                        Logger.error(Strings.network.parsing_json_error(error: jsonError))

                        let dataAsString = String(data: data, encoding: .utf8) ?? ""
                        Logger.error(Strings.network.json_data_received(dataString: dataAsString))

                        receivedJSONError = jsonError
                    }
                }

                httpResponse = self.eTagManager.httpResultFromCacheOrBackend(with: httpURLResponse,
                                                                             jsonObject: jsonObject,
                                                                             error: receivedJSONError,
                                                                             request: urlRequest,
                                                                             retried: request.retried)
                if httpResponse == nil {
                    Logger.debug(Strings.network.retrying_request(httpMethod: request.method.httpMethod,
                                                                  path: request.path))
                    let retriedRequest = request.retriedRequest()
                    self.queuedRequests.insert(retriedRequest, at: 0)
                    shouldBeginNextRequestWhenFinished = true
                }
            }
        }

        var networkError = networkError
        if dnsChecker.isBlockedAPIError(networkError),
           let blockedError = dnsChecker.errorWithBlockedHostFromError(networkError) {
            Logger.error(blockedError.description)
            networkError = blockedError
        }

        if let httpResponse = httpResponse,
           let completionHandler = request.completionHandler {
            let error = receivedJSONError ?? networkError
            completionHandler(httpResponse.statusCode, httpResponse.jsonObject, error)
        }

        if shouldBeginNextRequestWhenFinished {
            recursiveLock.lock()
            Logger.debug(Strings.network.serial_request_done(httpMethod: currentSerialRequest?.method.httpMethod,
                                                             path: currentSerialRequest?.path,
                                                             queuedRequestsCount: queuedRequests.count))
            self.currentSerialRequest = nil
            if !self.queuedRequests.isEmpty {
                let nextRequest = self.queuedRequests.removeFirst()
                Logger.debug(Strings.network.starting_next_request(request: nextRequest.description))
                self.perform(request: nextRequest,
                             serially: true)
            }
            recursiveLock.unlock()
        }
    }

    func convert(request: Request) -> URLRequest? {
        let relativeURLString = "/v1\(request.path)"
        guard let requestURL = URL(string: relativeURLString, relativeTo: SystemInfo.serverHostURL) else {
            return nil
        }

        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = request.method.httpMethod

        let eTagHeader = eTagManager.eTagHeader(for: urlRequest, refreshETag: request.retried)
        let headersWithETag = request.headers.merging(eTagHeader)

        urlRequest.allHTTPHeaderFields = headersWithETag

        if let requestBody = request.requestBody {
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
