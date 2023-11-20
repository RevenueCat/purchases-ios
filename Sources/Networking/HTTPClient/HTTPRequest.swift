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

    init(method: Method, path: HTTPRequest.Path, nonce: Data? = nil) {
        self.init(method: method, requestPath: path, nonce: nonce)
    }

    init(method: Method, path: HTTPRequest.PaywallPath, nonce: Data? = nil) {
        self.init(method: method, requestPath: path, nonce: nonce)
    }

    private init(method: Method, requestPath: HTTPRequestPath, nonce: Data? = nil) {
        assert(nonce == nil || nonce?.count == Data.nonceLength,
               "Invalid nonce: \(nonce?.description ?? "")")

        self.method = method
        self.path = requestPath
        self.nonce = nonce
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

// MARK: -

extension HTTPRequest.Method: Sendable {}
extension HTTPRequest: Sendable {}
