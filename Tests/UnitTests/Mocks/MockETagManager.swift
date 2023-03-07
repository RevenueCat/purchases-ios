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
        super.init(userDefaults: MockUserDefaults(), verificationMode: .default)
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

    func stubResponseEtag(_ tag: String) {
        self.stubbedETagHeaderResult[ETagManager.eTagResponseHeaderName] = tag
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
        let response: HTTPResponse<Data?>
        let request: URLRequest
        let retried: Bool
    }

    var invokedHTTPResultFromCacheOrBackend = false
    var invokedHTTPResultFromCacheOrBackendCount = 0
    private var invokedHTTPResultFromCacheOrBackendParameters: InvokedHTTPResultFromCacheOrBackendParams?
    private var invokedHTTPResultFromCacheOrBackendParametersList = [InvokedHTTPResultFromCacheOrBackendParams]()
    var stubbedHTTPResultFromCacheOrBackendResult: HTTPResponse<Data>!
    var shouldReturnResultFromBackend = true

    override func httpResultFromCacheOrBackend(with response: HTTPResponse<Data?>,
                                               request: URLRequest,
                                               retried: Bool) -> HTTPResponse<Data>? {
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
            }
            return self.stubbedHTTPResultFromCacheOrBackendResult
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
