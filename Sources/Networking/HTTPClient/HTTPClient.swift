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
    private let diagnosticsTracker: DiagnosticsTrackerType?
    private let dateProvider: DateProvider
    private let retriableStatusCodes: Set<HTTPStatusCode>
    private let operationDispatcher: OperationDispatcher

    private let retryBackoffIntervals: [TimeInterval] = [
        TimeInterval(0),
        TimeInterval(0.75),
        TimeInterval(3)
    ]

    init(apiKey: String,
         systemInfo: SystemInfo,
         eTagManager: ETagManager,
         signing: SigningType,
         diagnosticsTracker: DiagnosticsTrackerType?,
         dnsChecker: DNSCheckerType.Type = DNSChecker.self,
         retriableStatusCodes: Set<HTTPStatusCode> = Set([.tooManyRequests]),
         requestTimeout: TimeInterval = Configuration.networkTimeoutDefault,
         dateProvider: DateProvider = DateProvider(),
         operationDispatcher: OperationDispatcher) {
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
        self.diagnosticsTracker = diagnosticsTracker
        self.dnsChecker = dnsChecker
        self.retriableStatusCodes = retriableStatusCodes
        self.timeout = requestTimeout
        self.apiKey = apiKey
        self.authHeaders = HTTPClient.authorizationHeader(withAPIKey: apiKey)
        self.dateProvider = dateProvider
        self.operationDispatcher = operationDispatcher
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
                                    defaultHeaders: self.defaultHeaders,
                                    verificationMode: verificationMode ?? self.systemInfo.responseVerificationMode,
                                    internalSettings: self.systemInfo.dangerousSettings.internalSettings,
                                    completionHandler: completionHandler))
    }

    func clearCaches() {
        self.eTagManager.clearCaches()
    }

    var signatureVerificationEnabled: Bool {
        return self.systemInfo.responseVerificationMode.isEnabled
    }

    // Visible for tests
    var defaultHeaders: RequestHeaders {
        let preferredLanguages = self.systemInfo.preferredLanguages.prefix(3).map {
            $0.replacingOccurrences(of: "-", with: "_")
        }.joined(separator: ",")
        var headers: RequestHeaders = [
            "content-type": "application/json",
            "X-Version": SystemInfo.frameworkVersion,
            "X-Platform": SystemInfo.platformHeader,
            "X-Platform-Version": SystemInfo.systemVersion,
            "X-Platform-Flavor": self.systemInfo.platformFlavor,
            "X-Platform-Device": SystemInfo.deviceVersion,
            "X-Client-Version": SystemInfo.appVersion,
            "X-Client-Build-Version": SystemInfo.buildVersion,
            "X-Client-Bundle-ID": SystemInfo.bundleIdentifier,
            "X-Preferred-Locales": preferredLanguages,
            "X-StoreKit2-Enabled": "\(self.systemInfo.storeKitVersion.isStoreKit2EnabledAndAvailable)",
            "X-StoreKit-Version": "\(self.systemInfo.storeKitVersion.effectiveVersion)",
            "X-Observer-Mode-Enabled": "\(self.systemInfo.observerMode)",
            RequestHeader.retryCount.rawValue: "0",
            RequestHeader.sandbox.rawValue: "\(self.systemInfo.isSandbox)",
            "X-Is-Debug-Build": "\(self.systemInfo.isDebugBuild)"
        ]

        if let storefront = self.systemInfo.storefront {
            headers["X-Storefront"] = storefront.countryCode
        }

        if let platformFlavorVersion = self.systemInfo.platformFlavorVersion {
            headers["X-Platform-Flavor-Version"] = platformFlavorVersion
        }

        if let idfv = self.systemInfo.identifierForVendor {
            headers["X-Apple-Device-Identifier"] = idfv
        }

        if self.systemInfo.dangerousSettings.customEntitlementComputation {
            headers["X-Custom-Entitlements-Computation"] = "\(true)"
        }

        if self.systemInfo.dangerousSettings.uiPreviewMode {
            headers["X-UI-Preview-Mode"] = "\(true)"
        }

        return headers
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

    static func headerParametersForSignatureHeader(
        with headers: RequestHeaders,
        path: HTTPRequestPath
    ) -> RequestHeaders {
        if let header = HTTPRequest.headerParametersForSignatureHeader(
            headers: headers,
            path: path
        ) {
            return [RequestHeader.headerParametersForSignature.rawValue: header]
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
        case headerParametersForSignature = "X-Headers-Hash"
        case sandbox = "X-Is-Sandbox"
        case retryCount = "X-Retry-Count"

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
        case retryAfter = "Retry-After"
        case isRetryable = "Is-Retryable"

    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension HTTPClient: @unchecked Sendable {}

// MARK: - Private

internal extension HTTPClient {

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

        /// Whether the request has been retried.
        var retried: Bool {
            return self.retryCount > 0
        }

        /// The number of times that we have retried the request
        var retryCount: UInt = 0

        init<Value: HTTPResponseBody>(httpRequest: HTTPRequest,
                                      authHeaders: HTTPClient.RequestHeaders,
                                      defaultHeaders: HTTPClient.RequestHeaders,
                                      verificationMode: Signing.ResponseVerificationMode,
                                      internalSettings: InternalDangerousSettingsType,
                                      completionHandler: HTTPClient.Completion<Value>?) {
            self.httpRequest = httpRequest.requestAddingNonceIfRequired(with: verificationMode)
            self.headers = self.httpRequest.headers(
                with: authHeaders,
                defaultHeaders: defaultHeaders,
                verificationMode: verificationMode,
                internalSettings: internalSettings
            )
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

        func retriedRequest() -> Self {
            var copy = self
            copy.retryCount += 1
            copy.headers[RequestHeader.retryCount.rawValue] = "\(copy.retryCount)"

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
    // swiftlint:disable:next function_parameter_count
    func parse(urlResponse: URLResponse?,
               request: Request,
               urlRequest: URLRequest,
               data: Data?,
               error networkError: Error?,
               requestStartTime: Date) -> VerifiedHTTPResponse<Data>.Result? {
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
                                           response: httpURLResponse,
                                           requestStartTime: requestStartTime)
    }

    /// - Returns `Result<VerifiedHTTPResponse<Data>, NetworkError>?`
    private func createVerifiedResponse(
        request: Request,
        urlRequest: URLRequest,
        data: Data?,
        response httpURLResponse: HTTPURLResponse,
        requestStartTime: Date
    ) -> VerifiedHTTPResponse<Data>.Result? {
        #if DEBUG
        let requestHeaders: HTTPClient.RequestHeaders

        if self.systemInfo.dangerousSettings.internalSettings.disableHeaderSignatureVerification {
            Logger.warn(Strings.network.api_request_disabling_header_parameter_signature_verification(
                request.httpRequest
            ))
            requestHeaders = [:]
        } else {
            requestHeaders = request.headers
        }
        #else
        let requestHeaders = request.headers
        #endif

        let result = Result
            .success(data)
            .mapToResponse(response: httpURLResponse, request: request.httpRequest)
            // Verify response
            .map { cachedResponse -> VerifiedHTTPResponse<Data?> in
                return cachedResponse.verify(
                    signing: self.signing(for: request.httpRequest),
                    request: request.httpRequest,
                    requestHeaders: requestHeaders,
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

        return result
    }

    // swiftlint:disable:next function_parameter_count
    func handle(urlResponse: URLResponse?,
                request: Request,
                urlRequest: URLRequest,
                data: Data?,
                error networkError: Error?,
                requestStartTime: Date) {
        RCTestAssertNotMainThread()

        let response = self.parse(
            urlResponse: urlResponse,
            request: request,
            urlRequest: urlRequest,
            data: data,
            error: networkError,
            requestStartTime: requestStartTime
        )

        if let response = response {
            let httpURLResponse = urlResponse as? HTTPURLResponse
            var requestRetryScheduled = false

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

                requestRetryScheduled = self.retryRequestIfNeeded(request: request, httpURLResponse: httpURLResponse)
            }

            if !requestRetryScheduled {
                request.completionHandler?(response)
            }
        } else {
            Logger.debug(Strings.network.retrying_request(httpMethod: request.method.httpMethod,
                                                          path: request.path))

            self.state.modify {
                $0.queuedRequests.insert(request.retriedRequest(), at: 0)
            }
        }

        self.trackHttpRequestPerformedIfNeeded(request: request,
                                               requestStartTime: requestStartTime,
                                               result: response)

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
        let urlRequest = self.convert(request: request)

        guard let urlRequest = urlRequest else {
            let error: NetworkError = .unableToCreateRequest(request.httpRequest.path)

            Logger.error(error.description)
            request.completionHandler?(.failure(error))
            return
        }

        Logger.debug(Strings.network.api_request_started(request.httpRequest))

        let requestStartTime = self.dateProvider.now()

        // swiftlint:disable:next redundant_void_return
        let task = self.session.dataTask(with: urlRequest) { (data, urlResponse, error) -> Void in
            self.handle(urlResponse: urlResponse,
                        request: request,
                        urlRequest: urlRequest,
                        data: data,
                        error: error,
                        requestStartTime: requestStartTime)
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

    private func trackHttpRequestPerformedIfNeeded(request: Request,
                                                   requestStartTime: Date,
                                                   result: Result<VerifiedHTTPResponse<Data>, NetworkError>?) {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            guard let diagnosticsTracker = self.diagnosticsTracker, let result else { return }
            let responseTime = self.dateProvider.now().timeIntervalSince(requestStartTime)
            let requestPathName = request.httpRequest.path.name
            switch result {
            case let .success(response):
                let httpStatusCode = response.httpStatusCode.rawValue
                let verificationResult = response.verificationResult
                diagnosticsTracker.trackHttpRequestPerformed(endpointName: requestPathName,
                                                             responseTime: responseTime,
                                                             wasSuccessful: true,
                                                             responseCode: httpStatusCode,
                                                             backendErrorCode: nil,
                                                             resultOrigin: response.origin,
                                                             verificationResult: verificationResult,
                                                             isRetry: request.retried)
            case let .failure(error):
                var responseCode = -1
                var backendErrorCode: Int?
                if case let .errorResponse(errorResponse, code, _) = error {
                    responseCode = code.rawValue
                    backendErrorCode = errorResponse.code.rawValue
                }
                diagnosticsTracker.trackHttpRequestPerformed(endpointName: requestPathName,
                                                             responseTime: responseTime,
                                                             wasSuccessful: false,
                                                             responseCode: responseCode,
                                                             backendErrorCode: backendErrorCode,
                                                             resultOrigin: nil,
                                                             verificationResult: .notRequested,
                                                             isRetry: request.retried)
            }
        }
    }
}

// MARK: - Request Retry Logic
extension HTTPClient {

    /// Evaluates whether a request should be retried and schedules a retry if necessary.
    ///
    /// This function checks the HTTP response status code to determine if the request should be retried.
    /// If the retry conditions are met, it schedules the request to be retried after a backoff interval.
    ///
    /// - Parameters:
    ///   - request: The original `HTTPClient.Request` that may need to be retried.
    ///   - httpURLResponse: An optional `HTTPURLResponse` that contains the status code of the response.
    /// - Returns: A Boolean value indicating whether the request was scheduled for a retry.
    internal func retryRequestIfNeeded(
        request: HTTPClient.Request,
        httpURLResponse: HTTPURLResponse?
    ) -> Bool {

        guard request.httpRequest.isRetryable,
              let httpURLResponse = httpURLResponse,
              isResponseRetryable(httpURLResponse) else { return false }

        // At this point, retryCount hasn't been incremented yet, so we'll need to do it early here
        // to determine if another retry is appropriate.
        let nextRetryCount = request.retryCount + 1

        guard nextRetryCount <= self.retryBackoffIntervals.count else {
            Logger.error(
                NetworkStrings.api_request_failed_all_retries(
                    httpMethod: request.method.httpMethod,
                    path: request.path,
                    retryCount: request.retryCount
                )
            )
            return false
        }

        let retryBackoffInterval: TimeInterval = calculateRetryBackoffTime(
            forResponse: httpURLResponse,
            retryCount: nextRetryCount
        )

        Logger.debug(
            NetworkStrings.api_request_queued_for_retry(
                httpMethod: request.method.httpMethod,
                retryNumber: nextRetryCount,
                path: request.path,
                backoffInterval: retryBackoffInterval
            )
        )
        self.operationDispatcher.dispatchOnWorkerThread(after: retryBackoffInterval) {
            let retriedRequest = request.retriedRequest()
            self.state.modify {
                $0.queuedRequests.insert(retriedRequest, at: 0)
            }
            self.beginNextRequest()
        }
        return true
    }

    internal func isResponseRetryable(_ urlResponse: HTTPURLResponse) -> Bool {
        let isStatusCodeRetryable = self.retriableStatusCodes.contains(urlResponse.httpStatusCode)
        let doesServerAllowRetryString = urlResponse.value(forHTTPHeaderField: ResponseHeader.isRetryable.rawValue)
        let doesServerAllowRetry: Bool
        if let doesServerAllowRetryString = doesServerAllowRetryString {
            doesServerAllowRetry = Bool(doesServerAllowRetryString.lowercased()) ?? true
        } else {
            doesServerAllowRetry = true
        }

        return isStatusCodeRetryable && doesServerAllowRetry
    }

    internal func calculateRetryBackoffTime(
        forResponse httpURLResponse: HTTPURLResponse,
        retryCount: UInt
    ) -> TimeInterval {
        // Use the retry after value from the backend if present
        if let retryAfterHeaderValue = httpURLResponse.allHeaderFields[ResponseHeader.retryAfter.rawValue] as? String,
            let retryAfterSeconds = Double(retryAfterHeaderValue) {

            // Ensure that the retry interval is not negative or greater than 1 hour
            let nonNegativeRetryAfterSeconds = max(0, retryAfterSeconds)
            let cappedRetryInterval = min(
                nonNegativeRetryAfterSeconds,
                3_600   // 1 hour in seconds
            )

            return TimeInterval(cappedRetryInterval)
        }

        // Otherwise, use a default value
        let backoffIntervalIndex = Int(max(retryCount - 1, 0))
        let backoffIntervalIndexIsWithinBounds = backoffIntervalIndex < self.retryBackoffIntervals.count
        return backoffIntervalIndexIsWithinBounds ? self.retryBackoffIntervals[backoffIntervalIndex] : 0
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
           verificationMode.isEnabled {
            result.addRandomNonce()
        }

        return result
    }

    func headers(
        with authHeaders: HTTPClient.RequestHeaders,
        defaultHeaders: HTTPClient.RequestHeaders,
        verificationMode: Signing.ResponseVerificationMode,
        internalSettings: InternalDangerousSettingsType
    ) -> HTTPClient.RequestHeaders {
        var result: HTTPClient.RequestHeaders = defaultHeaders

        if self.path.authenticated {
            result += authHeaders
        }

        if let nonce = self.nonce {
            result += HTTPClient.nonceHeader(with: nonce)
        }

        if verificationMode.isEnabled,
           self.path.supportsSignatureVerification {
            let headerParametersSignature = HTTPClient.headerParametersForSignatureHeader(
                with: defaultHeaders,
                path: self.path
            )

            #if DEBUG
            if !internalSettings.disableHeaderSignatureVerification {
                result += headerParametersSignature
            }
            #else
            result += headerParametersSignature
            #endif

            if let body = self.requestBody {
                result += HTTPClient.postParametersHeaderForSigning(with: body)
            }
        }

        return result
    }

    /// Add a nonce to the request
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
