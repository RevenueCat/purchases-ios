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

// swiftlint:disable file_length

class HTTPClient {

    typealias RequestHeaders = HTTPRequest.Headers
    typealias ResponseHeaders = HTTPResponse<HTTPEmptyResponseBody>.Headers
    typealias Completion<Value: HTTPResponseBody> = (VerifiedHTTPResponse<Value>.Result) -> Void

    let systemInfo: SystemInfo
    let timeout: TimeInterval
    let apiKey: String
    let authHeaders: RequestHeaders

    private let session: URLSession
    private let state: Atomic<State> = .init(.initial)
    private let eTagManager: ETagManager
    private let dnsChecker: DNSCheckerType.Type
    private let signing: SigningType

    init(apiKey: String,
         systemInfo: SystemInfo,
         eTagManager: ETagManager,
         signing: SigningType,
         dnsChecker: DNSCheckerType.Type = DNSChecker.self,
         requestTimeout: TimeInterval = Configuration.networkTimeoutDefault) {
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 1
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout
        config.urlCache = nil // We implement our own caching with `ETagManager`.
        self.session = URLSession(configuration: config,
                                  delegate: RedirectLoggerSessionDelegate(),
                                  delegateQueue: nil)
        self.systemInfo = systemInfo
        self.eTagManager = eTagManager
        self.signing = signing
        self.dnsChecker = dnsChecker
        self.timeout = requestTimeout
        self.apiKey = apiKey
        self.authHeaders = HTTPClient.authorizationHeader(withAPIKey: apiKey)
    }

    /// - Parameter verificationMode: if `nil`, this will default to `SystemInfo.responseVerificationMode`
    func perform<Value: HTTPResponseBody>(
        _ request: HTTPRequest,
        with verificationMode: Signing.ResponseVerificationMode? = nil,
        completionHandler: Completion<Value>?
    ) {
        #if DEBUG
        guard !self.systemInfo.dangerousSettings.internalSettings.forceServerErrors else {
            Logger.warn(Strings.network.api_request_forcing_server_error(request))

            // `FB13133387`: when computing offline CustomerInfo, `StoreKit.Transaction.unfinished`
            // might be empty if called immediately after `Product.purchase()`.
            // This introduces a delay to simulate a real API request, and avoid that race condition.
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                completionHandler?(
                    .failure(.errorResponse(Self.serverErrorResponse, .internalServerError))
                )
            }

            return
        }
        #endif

        self.perform(request: .init(httpRequest: request,
                                    authHeaders: self.authHeaders,
                                    verificationMode: verificationMode ?? self.systemInfo.responseVerificationMode,
                                    completionHandler: completionHandler))
    }

    func clearCaches() {
        self.eTagManager.clearCaches()
    }

    var signatureVerificationEnabled: Bool {
        return self.systemInfo.responseVerificationMode.isEnabled
    }

}

extension HTTPClient {

    static func authorizationHeader(withAPIKey apiKey: String) -> RequestHeaders {
        return [RequestHeader.authorization.rawValue: "Bearer \(apiKey)"]
    }

    static func nonceHeader(with data: Data) -> RequestHeaders {
        return [RequestHeader.nonce.rawValue: data.base64EncodedString()]
    }

    static func postParametersHeaderForSigning(with body: HTTPRequestBody) -> RequestHeaders {
        if let header = body.postParameterHeader {
            return [RequestHeader.postParameters.rawValue: header]
        } else {
            return [:]
        }
    }

    enum RequestHeader: String {

        case authorization = "Authorization"
        case nonce = "X-Nonce"
        case eTag = "X-RevenueCat-ETag"
        case eTagValidationTime = "X-RC-Last-Refresh-Time"
        case postParameters = "X-Post-Params-Hash"

    }

    enum ResponseHeader: String {

        case eTag = "X-RevenueCat-ETag"
        case location = "Location"
        case signature = "X-Signature"
        case requestDate = "X-RevenueCat-Request-Time"
        case contentType = "Content-Type"
        case isLoadShedder = "X-RevenueCat-Fortress"
        case requestID = "X-Request-ID"
        case amazonTraceID = "X-Amzn-Trace-ID"

    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension HTTPClient: @unchecked Sendable {}

// MARK: - Private

private extension HTTPClient {

    struct State {
        var queuedRequests: [Request]
        var currentSerialRequest: Request?

        static let initial: Self = .init(queuedRequests: [], currentSerialRequest: nil)
    }

    struct Request: CustomStringConvertible {

        var httpRequest: HTTPRequest
        var headers: HTTPClient.RequestHeaders
        var verificationMode: Signing.ResponseVerificationMode
        var completionHandler: HTTPClient.Completion<Data>?
        var retried: Bool = false

        init<Value: HTTPResponseBody>(httpRequest: HTTPRequest,
                                      authHeaders: HTTPClient.RequestHeaders,
                                      verificationMode: Signing.ResponseVerificationMode,
                                      completionHandler: HTTPClient.Completion<Value>?) {
            self.httpRequest = httpRequest.requestAddingNonceIfRequired(with: verificationMode)
            self.headers = self.httpRequest.headers(with: authHeaders,
                                                    verificationMode: verificationMode)
            self.verificationMode = verificationMode

            if let completionHandler = completionHandler {
                self.completionHandler = { result in
                    completionHandler(result.parseResponse())
                }
            } else {
                self.completionHandler = nil
            }
        }

        var method: HTTPRequest.Method { self.httpRequest.method }
        var path: String { self.httpRequest.path.relativePath }

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

}

private extension HTTPClient {

    var defaultHeaders: [String: String] {
        var headers: [String: String] = [
            "content-type": "application/json",
            "X-Version": SystemInfo.frameworkVersion,
            "X-Platform": SystemInfo.platformHeader,
            "X-Platform-Version": SystemInfo.systemVersion,
            "X-Platform-Flavor": systemInfo.platformFlavor,
            "X-Client-Version": SystemInfo.appVersion,
            "X-Client-Build-Version": SystemInfo.buildVersion,
            "X-Client-Bundle-ID": SystemInfo.bundleIdentifier,
            "X-StoreKit2-Enabled": "\(self.systemInfo.storeKit2Setting.isEnabledAndAvailable)",
            "X-Observer-Mode-Enabled": "\(self.systemInfo.observerMode)",
            "X-Is-Sandbox": "\(self.systemInfo.isSandbox)"
        ]

        if let platformFlavorVersion = self.systemInfo.platformFlavorVersion {
            headers["X-Platform-Flavor-Version"] = platformFlavorVersion
        }

        if let idfv = systemInfo.identifierForVendor {
            headers["X-Apple-Device-Identifier"] = idfv
        }

        if systemInfo.dangerousSettings.customEntitlementComputation {
            headers["X-Custom-Entitlements-Computation"] = "\(true)"
        }

        return headers
    }

    static let serverErrorResponse: ErrorResponse = .init(code: .internalServerError,
                                                          originalCode: BackendErrorCode.unknownBackendError.rawValue)

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

    /// - Returns: `nil` if the request must be retried
    func parse(urlResponse: URLResponse?,
               request: Request,
               urlRequest: URLRequest,
               data: Data?,
               error networkError: Error?) -> VerifiedHTTPResponse<Data>.Result? {
        if let networkError = networkError {
            return .failure(NetworkError(networkError, dnsChecker: self.dnsChecker))
        }

        guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
            return .failure(.unexpectedResponse(urlResponse))
        }

        let statusCode: HTTPStatusCode = .init(rawValue: httpURLResponse.statusCode)

        // `nil` if status code is 304, since the response will be empty and fetched from the eTag.
        let dataIfAvailable = statusCode == .notModified
            ? nil
            : data

        return self.createVerifiedResponse(request: request,
                                           urlRequest: urlRequest,
                                           data: dataIfAvailable,
                                           response: httpURLResponse)
    }

    /// - Returns `Result<VerifiedHTTPResponse<Data>, NetworkError>?`
    private func createVerifiedResponse(
        request: Request,
        urlRequest: URLRequest,
        data: Data?,
        response httpURLResponse: HTTPURLResponse
    ) -> VerifiedHTTPResponse<Data>.Result? {
        return Result
            .success(data)
            .mapToResponse(response: httpURLResponse, request: request.httpRequest)
            // Verify response
            .map { cachedResponse -> VerifiedHTTPResponse<Data?> in
                return cachedResponse.verify(
                    signing: self.signing(for: request.httpRequest),
                    request: request.httpRequest,
                    publicKey: request.verificationMode.publicKey
                )
            }
            // Fetch from ETagManager if available
            .map { (response) -> VerifiedHTTPResponse<Data>? in
                return self.eTagManager.httpResultFromCacheOrBackend(
                    with: response,
                    request: urlRequest,
                    retried: request.retried
                )
            }
            // Upgrade to error in enforced mode
            .flatMap { response -> Result<VerifiedHTTPResponse<Data>?, NetworkError> in
                if let response = response, response.verificationResult == .failed {
                    if case .enforced = request.verificationMode {
                        return .failure(.signatureVerificationFailed(path: request.httpRequest.path,
                                                                     code: response.httpStatusCode))
                    } else {
                        // Any other mode gets forwarded as a success, but we log the error
                        Logger.error(Strings.signing.request_failed_verification(request.httpRequest))
                        return .success(response)
                    }
                } else {
                    return .success(response)
                }
            }
            .asOptionalResult?
            .convertUnsuccessfulResponseToError()
    }

    func handle(urlResponse: URLResponse?,
                request: Request,
                urlRequest: URLRequest,
                data: Data?,
                error networkError: Error?) {
        RCTestAssertNotMainThread()

        let response = self.parse(
            urlResponse: urlResponse,
            request: request,
            urlRequest: urlRequest,
            data: data,
            error: networkError
        )

        if let response = response {
            let httpURLResponse = urlResponse as? HTTPURLResponse

            switch response {
            case let .success(response):
                Logger.debug(Strings.network.api_request_completed(
                    request.httpRequest,
                    // Getting status code from the original response to detect 304s
                    // If that can't be extracted, get status code from the parsed response.
                    httpCode: httpURLResponse?.httpStatusCode ?? response.httpStatusCode,
                    metadata: Logger.verboseLogsEnabled ? response.metadata : nil
                ))

                if response.isLoadShedder {
                    Logger.debug(Strings.network.request_handled_by_load_shedder(request.httpRequest.path))
                }

            case let .failure(error):
                let httpURLResponse = urlResponse as? HTTPURLResponse

                Logger.debug(Strings.network.api_request_failed(
                    request.httpRequest,
                    httpCode: httpURLResponse?.httpStatusCode,
                    error: error,
                    metadata: httpURLResponse?.metadata)
                )

                if httpURLResponse?.isLoadShedder == true {
                    Logger.debug(Strings.network.request_handled_by_load_shedder(request.httpRequest.path))
                }
            }

            request.completionHandler?(response)
        } else {
            Logger.debug(Strings.network.retrying_request(httpMethod: request.method.httpMethod,
                                                          path: request.path))

            self.state.modify {
                $0.queuedRequests.insert(request.retriedRequest(), at: 0)
            }
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
            let error: NetworkError = .unableToCreateRequest(request.httpRequest.path)

            Logger.error(error.description)
            request.completionHandler?(.failure(error))
            return
        }

        Logger.debug(Strings.network.api_request_started(request.httpRequest))

        let task = self.session.dataTask(with: urlRequest) { (data, urlResponse, error) -> Void in
            self.handle(urlResponse: urlResponse,
                        request: request,
                        urlRequest: urlRequest,
                        data: data,
                        error: error)
        }
        task.resume()
    }

    func convert(request: Request) -> URLRequest? {
        guard let requestURL = request.httpRequest.path.url(proxyURL: SystemInfo.proxyURL) else {
            return nil
        }
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = request.method.httpMethod
        urlRequest.allHTTPHeaderFields = self.headers(for: request, urlRequest: urlRequest)

        do {
            urlRequest.httpBody = try request.httpRequest.requestBody?.jsonEncodedData
        } catch {
            Logger.error(Strings.network.creating_json_error(error: error.localizedDescription))
            return nil
        }

        return urlRequest
    }

    private func headers(for request: Request, urlRequest: URLRequest) -> HTTPClient.RequestHeaders {
        if request.httpRequest.path.shouldSendEtag {
            let eTagHeader = self.eTagManager.eTagHeader(
                for: urlRequest,
                withSignatureVerification: request.verificationMode.isEnabled,
                refreshETag: request.retried
            )
            return request.headers.merging(eTagHeader)
        } else {
            return request.headers
        }
    }

    private func signing(for request: HTTPRequest) -> SigningType {
        #if DEBUG
        if self.systemInfo.dangerousSettings.internalSettings.forceSignatureFailures {
            Logger.warn(Strings.network.api_request_forcing_signature_failure(request))
            return FakeSigning.default
        }
        #endif

        return self.signing
    }

}

// MARK: - Extensions

extension HTTPClient {

    /// Information from a response to help identify a request.
    struct ResponseMetadata {
        var requestID: String?
        var amazonTraceID: String?
    }

}

extension HTTPRequest {

    func requestAddingNonceIfRequired(
        with verificationMode: Signing.ResponseVerificationMode
    ) -> HTTPRequest {
        var result = self

        if result.nonce == nil,
           result.path.needsNonceForSigning,
           verificationMode.isEnabled,
           #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            result.addRandomNonce()
        }

        return result
    }

    func headers(
        with authHeaders: HTTPClient.RequestHeaders,
        verificationMode: Signing.ResponseVerificationMode
    ) -> HTTPClient.RequestHeaders {
        var result: HTTPClient.RequestHeaders = [:]

        if self.path.authenticated {
            result += authHeaders
        }

        if let nonce = self.nonce {
            result += HTTPClient.nonceHeader(with: nonce)
        }

        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *),
           verificationMode.isEnabled,
           self.path.supportsSignatureVerification,
           let body = self.requestBody {
            result += HTTPClient.postParametersHeaderForSigning(with: body)
        }

        return result
    }

    /// Add a nonce to the request
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    private mutating func addRandomNonce() {
        self.nonce = Data.randomNonce()
    }

}

private extension NetworkError {

    /// Creates a `NetworkError` from any request `Error`.
    init(_ error: Error, dnsChecker: DNSCheckerType.Type) {
        if let blockedError = dnsChecker.errorWithBlockedHostFromError(error) {
            Logger.error(blockedError.description)
            self = blockedError
        } else {
            self = .networkError(error as NSError)
        }
    }

}

extension Result where Success == Data?, Failure == NetworkError {

    /// Converts a `Result<Data?, NetworkError>` into `Result<HTTPResponse<Data?>, NetworkError>`
    func mapToResponse(
        response: HTTPURLResponse,
        request: HTTPRequest
    ) -> Result<HTTPResponse<Data?>, Failure> {
        return self.flatMap { body in
            return .success(
                .init(
                    httpStatusCode: response.httpStatusCode,
                    responseHeaders: response.allHeaderFields,
                    body: body
                )
            )
        }
    }

}

extension Result where Success == VerifiedHTTPResponse<Data>, Failure == NetworkError {

    // Parses a `Result<VerifiedHTTPResponse<Data>>` to `Result<VerifiedHTTPResponse<Value>>`
    func parseResponse<Value: HTTPResponseBody>() -> VerifiedHTTPResponse<Value>.Result {
        return self.flatMap { response in                   // Convert the `Result` type
            Result<VerifiedHTTPResponse<Value>, Error> {    // Create a new `Result<Value>`
                try response.mapBody { data in              // Convert the from `Data` -> `Value`
                    try Value.create(with: data)            // Decode `Data` into `Value`
                }
                .copyWithNewRequestDate()                   // Update request date for 304 responses
            }
            // Convert decoding errors into `NetworkError.decoding`
            .mapError { NetworkError.decoding($0, response.response.body) }
        }
    }

}

extension Result where Success == VerifiedHTTPResponse<Data>, Failure == NetworkError {

    // Converts an unsuccessful response into a `Result.failure`
    fileprivate func convertUnsuccessfulResponseToError() -> Self {
        return self.flatMap {
            $0.response.httpStatusCode.isSuccessfulResponse
            ? .success($0)
            : .failure($0.response.parseUnsuccessfulResponse())
        }
    }

}

private extension VerifiedHTTPResponse {

    func copyWithNewRequestDate() -> Self {
        // Update request time from server unless it failed verification.
        guard self.verificationResult != .failed, let requestDate = self.requestDate else { return self }

        return self.mapBody {
            return $0.copy(with: requestDate)
        }
    }

}

private extension HTTPResponseType {

    var isLoadShedder: Bool {
        return self.value(forHeaderField: HTTPClient.ResponseHeader.isLoadShedder) == "true"
    }

    var metadata: HTTPClient.ResponseMetadata {
        return .init(
            requestID: self.value(forHeaderField: HTTPClient.ResponseHeader.requestID),
            amazonTraceID: self.value(forHeaderField: HTTPClient.ResponseHeader.amazonTraceID)
        )
    }

}

private extension HTTPResponse where Body == Data {

    func parseUnsuccessfulResponse() -> NetworkError {
        let contentType = self.value(forHeaderField: HTTPClient.ResponseHeader.contentType) ?? ""
        let isJSON = contentType.starts(with: "application/json")

        return .errorResponse(
            isJSON
                ? .from(self.body)
                : .defaultResponse,
            self.httpStatusCode
        )
    }

}
