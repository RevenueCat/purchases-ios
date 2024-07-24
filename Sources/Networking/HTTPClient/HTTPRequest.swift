//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPRequest.swift
//
//  Created by Nacho Soto on 2/27/22.

import Foundation

/// A request to be made by ``HTTPClient``
struct HTTPRequest {

    typealias Headers = [String: String]

    var method: Method
    var path: HTTPRequestPath
    /// If present, this will be used by the server to compute a checksum of the response signed with a private key.
    var nonce: Data?
    /// Whether or not this request should be retried by the HTTPClient for certain status codes.
    var isRetryable: Bool

    init(
        method: Method,
        path: HTTPRequest.Path,
        nonce: Data? = nil,
        isRetryable: Bool = false
    ) {
        self.init(method: method, requestPath: path, nonce: nonce, isRetryable: isRetryable)
    }

    init(
        method: Method,
        path: HTTPRequest.PaywallPath,
        nonce: Data? = nil,
        isRetryable: Bool = false
    ) {
        self.init(method: method, requestPath: path, nonce: nonce, isRetryable: isRetryable)
    }

    init(
        method: Method,
        path: HTTPRequest.DiagnosticsPath,
        nonce: Data? = nil,
        isRetryable: Bool = false
    ) {
        self.init(method: method, requestPath: path, nonce: nonce, isRetryable: isRetryable)
    }

    private init(
        method: Method,
        requestPath: HTTPRequestPath,
        nonce: Data? = nil,
        isRetryable: Bool = false
    ) {
        assert(nonce == nil || nonce?.count == Data.nonceLength,
               "Invalid nonce: \(nonce?.description ?? "")")

        self.method = method
        self.path = requestPath
        self.nonce = nonce
        self.isRetryable = isRetryable
    }

}

// MARK: - Method

extension HTTPRequest {

    enum Method {

        case get
        case post(HTTPRequestBody)

    }

}

extension HTTPRequest {

    var requestBody: HTTPRequestBody? {
        switch self.method {
        case let .post(body): return body
        case .get: return nil
        }
    }

}

extension HTTPRequest.Method {

    var httpMethod: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        }
    }

}
