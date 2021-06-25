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

    var invokedGetHTTPResultFromCacheOrBackend = false
    var invokedGetHTTPResultFromCacheOrBackendCount = 0
    var invokedGetHTTPResultFromCacheOrBackendParameters: (response: HTTPURLResponse, responseObject: [String: Any]?, error: Error?, request: URLRequest, retried: Bool)?
    var invokedGetHTTPResultFromCacheOrBackendParametersList = [(response: HTTPURLResponse, responseObject: [String: Any]?, error: Error?, request: URLRequest, retried: Bool)]()
    var stubbedGetHTTPResultFromCacheOrBackendResult: HTTPResponse!
    var shouldReturnResultFromBackend = true

    override func getHTTPResultFromCacheOrBackend(with response: HTTPURLResponse,
        jsonObject: [String: Any]?,
        error: Error?,
        request: URLRequest,
        retried: Bool) -> HTTPResponse? {
        invokedGetHTTPResultFromCacheOrBackend = true
        invokedGetHTTPResultFromCacheOrBackendCount += 1
        invokedGetHTTPResultFromCacheOrBackendParameters = (response, jsonObject, error, request, retried)
        invokedGetHTTPResultFromCacheOrBackendParametersList.append((response, jsonObject, error, request, retried))
        if shouldReturnResultFromBackend {
            return HTTPResponse(statusCode: response.statusCode, jsonObject: jsonObject)
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
