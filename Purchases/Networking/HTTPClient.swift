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

    typealias RequestHeaders = [String: String]
    typealias Completion = ((_ statusCode: HTTPStatusCode, _ response: [String: Any]?, _ error: Error?) -> Void)

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
                 completionHandler: Completion?) {
        perform(request: .init(httpRequest: request,
                               headers: authHeaders,
                               completionHandler: completionHandler))
    }

    func clearCaches() {
        eTagManager.clearCaches()
    }

}

extension HTTPClient {

    static func authorizationHeader(withAPIKey apiKey: String) -> RequestHeaders {
        return ["Authorization": "Bearer \(apiKey)"]
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

    struct Request: CustomStringConvertible {

        var httpRequest: HTTPRequest
        var headers: HTTPClient.RequestHeaders
        var completionHandler: Completion?
        var retried: Bool = false

        var method: HTTPRequest.Method { self.httpRequest.method }
        var path: String { self.httpRequest.path.description }

        func adding(defaultHeaders: HTTPClient.RequestHeaders) -> Self {
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
        var statusCode: HTTPStatusCode = .networkConnectTimeoutError
        var jsonObject: [String: Any]?
        var httpResponse: HTTPResponse? = HTTPResponse(statusCode: statusCode, jsonObject: jsonObject)
        var receivedJSONError: Error?

        if networkError == nil {
            if let httpURLResponse = urlResponse as? HTTPURLResponse {
                statusCode = .init(rawValue: httpURLResponse.statusCode)
                Logger.debug(Strings.network.api_request_completed(httpMethod: request.method.httpMethod,
                                                                   path: request.path,
                                                                   httpCode: statusCode))

                if statusCode == .notModified || data == nil {
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
            Logger.error("Could not create request to \(request.path)")

            request.completionHandler?(.invalidRequest,
                                       nil,
                                       ErrorUtils.networkError(withUnderlyingError: ErrorUtils.unknownError()))
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
        guard let requestURL = request.httpRequest.path.url else {
            return nil
        }

        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = request.method.httpMethod

        let eTagHeader = eTagManager.eTagHeader(for: urlRequest, refreshETag: request.retried)
        let headersWithETag = request.headers.merging(eTagHeader)

        urlRequest.allHTTPHeaderFields = headersWithETag
        do {
            urlRequest.httpBody = try request.httpRequest.requestBody?.asData()
        } catch {
            Logger.error(Strings.network.creating_json_error(error: error.localizedDescription))
            return nil
        }

        return urlRequest
    }

}

extension HTTPRequest.Path {

    var url: URL? {
        return URL(string: self.relativePath,
                   relativeTo: SystemInfo.serverHostURL)
    }

    var relativePath: String {
        return "\(Self.pathPrefix)/\(self.description)"
    }

    private static let pathPrefix: String = "/v1"

}

private extension Encodable {

    func asData() throws -> Data {
        return try jsonEncoder.encode(self)
    }

}

private let jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase

    return encoder
}()
