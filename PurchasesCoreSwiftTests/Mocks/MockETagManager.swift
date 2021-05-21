//
//  MockETagManager.swift
//  PurchasesCoreSwiftTests
//
//  Created by César de la Vega on 4/20/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@testable import PurchasesCoreSwift

class MockETagManager: ETagManager {

    var invokedGetETagHeader = false
    var invokedGetETagHeaderCount = 0
    var invokedGetETagHeaderParameters: (urlRequest: URLRequest, refreshETag: Bool)?
    var invokedGetETagHeaderParametersList = [(urlRequest: URLRequest, refreshETag: Bool)]()
    var stubbedGetETagHeaderResult: [String: String]! = [:]

    override func getETagHeader(for urlRequest: URLRequest, refreshETag: Bool = false) -> [String: String] {
        invokedGetETagHeader = true
        invokedGetETagHeaderCount += 1
        invokedGetETagHeaderParameters = (urlRequest, refreshETag)
        invokedGetETagHeaderParametersList.append((urlRequest, refreshETag))
        return stubbedGetETagHeaderResult
    }

    var invokedGetHTTPResultFromCacheOrBackend = false
    var invokedGetHTTPResultFromCacheOrBackendCount = 0
    var invokedGetHTTPResultFromCacheOrBackendParameters: (statusCode: Int, responseObject: [String: Any]?, error: Error?, headersInResponse: [String: Any], request: URLRequest, retried: Bool)?
    var invokedGetHTTPResultFromCacheOrBackendParametersList = [(statusCode: Int, responseObject: [String: Any]?, error: Error?, headersInResponse: [String: Any], request: URLRequest, retried: Bool)]()
    var stubbedGetHTTPResultFromCacheOrBackendResult: HTTPResponse!
    var shouldReturnResultFromBackend = true

    override func getHTTPResultFromCacheOrBackend(with statusCode: Int,
                                                  responseObject: [String: Any]?,
                                                  error: Error?,
                                                  headersInResponse: [String: Any],
                                                  request: URLRequest,
                                                  retried: Bool) -> HTTPResponse? {
        invokedGetHTTPResultFromCacheOrBackend = true
        invokedGetHTTPResultFromCacheOrBackendCount += 1
        invokedGetHTTPResultFromCacheOrBackendParameters = (statusCode, responseObject, error, headersInResponse, request, retried)
        invokedGetHTTPResultFromCacheOrBackendParametersList.append((statusCode, responseObject, error, headersInResponse, request, retried))
        if (shouldReturnResultFromBackend) {
            return HTTPResponse(statusCode: statusCode, responseObject: responseObject)
        }
        return stubbedGetHTTPResultFromCacheOrBackendResult
    }

    var invokedClearCaches = false
    var invokedClearCachesCount = 0

    override func clearCaches() {
        invokedClearCaches = true
        invokedClearCachesCount += 1
    }
}
