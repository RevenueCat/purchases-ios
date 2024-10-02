//
//  MockETagManager.swift
//  PurchasesTests
//
//  Created by César de la Vega on 4/20/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@testable import RevenueCat

// swiftlint:disable type_name
class MockETagManager: ETagManager {

    init() {
        super.init(userDefaults: MockUserDefaults())
    }

    struct ETagHeaderRequest {
        var urlRequest: URLRequest
        var withSignatureVerification: Bool
        var refreshETag: Bool
    }

    var invokedETagHeader = false
    var invokedETagHeaderCount = 0
    var invokedETagHeaderParameters: ETagHeaderRequest?
    var invokedETagHeaderParametersList: [ETagHeaderRequest] = []
    var stubbedETagHeaderResult: [String: String]! = [:]

    func stubResponseEtag(_ tag: String, validationTime: Date = Date()) {
        self.stubbedETagHeaderResult = [
            ETagManager.eTagRequestHeader.rawValue: tag,
            ETagManager.eTagValidationTimeRequestHeader.rawValue: validationTime.millisecondsSince1970.description
        ]
    }

    override func eTagHeader(
        for urlRequest: URLRequest,
        withSignatureVerification: Bool,
        refreshETag: Bool = false
    ) -> [String: String] {
        return self.lock.perform {
            let request: ETagHeaderRequest = .init(urlRequest: urlRequest,
                                                   withSignatureVerification: withSignatureVerification,
                                                   refreshETag: refreshETag)

            self.invokedETagHeader = true
            self.invokedETagHeaderCount += 1
            self.invokedETagHeaderParameters = request
            self.invokedETagHeaderParametersList.append(request)

            return self.stubbedETagHeaderResult
        }
    }

    private struct InvokedHTTPResultFromCacheOrBackendParams {
        let response: VerifiedHTTPResponse<Data?>
        let request: URLRequest
        let retried: Bool
    }

    var invokedHTTPResultFromCacheOrBackend = false
    var invokedHTTPResultFromCacheOrBackendCount = 0
    private var invokedHTTPResultFromCacheOrBackendParameters: InvokedHTTPResultFromCacheOrBackendParams?
    private var invokedHTTPResultFromCacheOrBackendParametersList = [InvokedHTTPResultFromCacheOrBackendParams]()
    var stubbedHTTPResultFromCacheOrBackendResult: VerifiedHTTPResponse<Data>!
    var shouldReturnResultFromBackend = true

    override func httpResultFromCacheOrBackend(with response: VerifiedHTTPResponse<Data?>,
                                               request: URLRequest,
                                               retried: Bool) -> VerifiedHTTPResponse<Data>? {
        return self.lock.perform {
            self.invokedHTTPResultFromCacheOrBackend = true
            self.invokedHTTPResultFromCacheOrBackendCount += 1
            let params = InvokedHTTPResultFromCacheOrBackendParams(
                response: response,
                request: request,
                retried: retried
            )
            self.invokedHTTPResultFromCacheOrBackendParameters = params
            self.invokedHTTPResultFromCacheOrBackendParametersList.append(params)

            if self.shouldReturnResultFromBackend {
                return response.asOptionalResponse
            } else {
                // Mimic behavior from `ETagManager`, returning the cached response
                // with the original headers, request date, and verification result
                var result = self.stubbedHTTPResultFromCacheOrBackendResult
                result?.verificationResult = response.verificationResult
                if var newResponse = result?.response {
                    newResponse.responseHeaders = response.responseHeaders
                    newResponse.requestDate = response.requestDate
                    result?.response = newResponse
                }

                return result
            }
        }
    }

    var invokedClearCaches = false
    var invokedClearCachesCount = 0

    override func clearCaches() {
        lock.perform {
            invokedClearCaches = true
            invokedClearCachesCount += 1
        }
    }

    private let lock = Lock()

}

extension MockETagManager: @unchecked Sendable {}
