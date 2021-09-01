//
//  MockETagManager.swift
//  PurchasesTests
//
//  Created by César de la Vega on 4/20/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@testable import RevenueCat

class MockETagManager: ETagManager {

    var invokedETagHeader = false
    var invokedETagHeaderCount = 0
    var invokedETagHeaderParameters: (urlRequest: URLRequest, refreshETag: Bool)?
    var invokedETagHeaderParametersList = [(urlRequest: URLRequest, refreshETag: Bool)]()
    var stubbedETagHeaderResult: [String: String]! = [:]

    override func eTagHeader(for urlRequest: URLRequest, refreshETag: Bool = false) -> [String: String] {
        invokedETagHeader = true
        invokedETagHeaderCount += 1
        invokedETagHeaderParameters = (urlRequest, refreshETag)
        invokedETagHeaderParametersList.append((urlRequest, refreshETag))
        return stubbedETagHeaderResult
    }

    var invokedHTTPResultFromCacheOrBackend = false
    var invokedHTTPResultFromCacheOrBackendCount = 0
    var invokedHTTPResultFromCacheOrBackendParameters: (response: HTTPURLResponse, responseObject: [String: Any]?, error: Error?, request: URLRequest, retried: Bool)?
    var invokedHTTPResultFromCacheOrBackendParametersList = [(response: HTTPURLResponse, responseObject: [String: Any]?, error: Error?, request: URLRequest, retried: Bool)]()
    var stubbedHTTPResultFromCacheOrBackendResult: HTTPResponse!
    var shouldReturnResultFromBackend = true

    override func httpResultFromCacheOrBackend(with response: HTTPURLResponse,
                                               jsonObject: [String: Any]?,
                                               error: Error?,
                                               request: URLRequest,
                                               retried: Bool) -> HTTPResponse? {
        invokedHTTPResultFromCacheOrBackend = true
        invokedHTTPResultFromCacheOrBackendCount += 1
        invokedHTTPResultFromCacheOrBackendParameters = (response, jsonObject, error, request, retried)
        invokedHTTPResultFromCacheOrBackendParametersList.append((response, jsonObject, error, request, retried))
        if shouldReturnResultFromBackend {
            return HTTPResponse(statusCode: response.statusCode, jsonObject: jsonObject)
        }
        return stubbedHTTPResultFromCacheOrBackendResult
    }

    var invokedClearCaches = false
    var invokedClearCachesCount = 0

    override func clearCaches() {
        invokedClearCaches = true
        invokedClearCachesCount += 1
    }
}
