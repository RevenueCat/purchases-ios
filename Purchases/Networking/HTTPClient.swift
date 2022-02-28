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
    private let state: Atomic<State> = .init(.initial)
    private let eTagManager: ETagManager
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

    func perform(_ request: HTTPRequest,
                 authHeaders: [String: String],
                 completionHandler: ((Int, [String: Any]?, Error?) -> Void)?) {
        perform(request: .init(httpRequest: request,
                               headers: authHeaders,
                               completionHandler: completionHandler))
    }

    func clearCaches() {
        eTagManager.clearCaches()
    }

}

private extension HTTPClient {
    struct State {
        var queuedRequests: [Request]
        var currentSerialRequest: Request?

        static let initial: Self = .init(queuedRequests: [],
                                         currentSerialRequest: nil)
    }
}

private extension HTTPClient {

    // swiftlint:disable nesting
    struct Request: CustomStringConvertible {

        typealias Headers = [String: String]
        typealias Completion = ((_ statusCode: Int, _ response: [String: Any]?, _ error: Error?) -> Void)

        var httpRequest: HTTPRequest
        var headers: Headers
        var completionHandler: Completion?
        var retried: Bool = false

        var method: HTTPRequest.Method { self.httpRequest.method }
        var path: String { self.httpRequest.path.description }
        var requestBody: HTTPRequest.Body? { self.httpRequest.requestBody }

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

    func perform(request: Request) {
        if !request.retried {
            let requestEnqueued: Bool = self.state.modify {
                if $0.currentSerialRequest != nil {
                    Logger.debug(Strings.network.serial_request_queued(httpMethod: request.method.httpMethod,
                                                                       path: request.path,
                                                                       queuedRequestsCount: $0.queuedRequests.count))

                    $0.queuedRequests.append(request)
                    return true
                } else {
                    Logger.debug(Strings.network.starting_request(httpMethod: request.method.httpMethod,
                                                                  path: request.path))
                    $0.currentSerialRequest = request
                    return false
                }
            }

            guard !requestEnqueued else { return }
        }

        self.start(request: request)
    }

    // swiftlint:disable:next function_body_length
    func handle(urlResponse: URLResponse?,
                request: Request,
                urlRequest: URLRequest,
                data: Data?,
                error networkError: Error?) {
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
                    self.state.modify {
                        $0.queuedRequests.insert(request.retriedRequest(), at: 0)
                    }
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

        self.beginNextRequest()
    }

    func beginNextRequest() {
        let nextRequest: Request? = self.state.modify {
            Logger.debug(Strings.network.serial_request_done(httpMethod: $0.currentSerialRequest?.method.httpMethod,
                                                             path: $0.currentSerialRequest?.path,
                                                             queuedRequestsCount: $0.queuedRequests.count))
            $0.currentSerialRequest = $0.queuedRequests.popFirst()

            return $0.currentSerialRequest
        }

        if let nextRequest = nextRequest {
            Logger.debug(Strings.network.starting_next_request(request: nextRequest.description))
            self.start(request: nextRequest)
        }
    }

    func start(request: Request) {
        let urlRequest = self.convert(request: request.adding(defaultHeaders: self.defaultHeaders))

        guard let urlRequest = urlRequest else {
            if case let .post(requestBody) = request.method {
                Logger.error("Could not create request to \(request.path) with body \(requestBody)")
            } else {
                Logger.error("Could not create request to \(request.path) without body")
            }

            request.completionHandler?(-1, nil, ErrorUtils.networkError(withUnderlyingError: ErrorUtils.unknownError()))
            return
        }

        Logger.debug(Strings.network.api_request_started(httpMethod: urlRequest.httpMethod,
                                                         path: urlRequest.url?.path))

        let task = session.dataTask(with: urlRequest) { (data, urlResponse, error) -> Void in
            self.handle(urlResponse: urlResponse,
                        request: request,
                        urlRequest: urlRequest,
                        data: data,
                        error: error)
        }
        task.resume()
    }

    func convert(request: Request) -> URLRequest? {
        guard let requestURL = URL(string: request.httpRequest.path.relativePath,
                                   relativeTo: SystemInfo.serverHostURL) else {
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

extension HTTPRequest.Path {

    var relativePath: String {
        return "\(Self.pathPrefix)\(self.description)"
    }

    private static let pathPrefix: String = "/v1"

}
