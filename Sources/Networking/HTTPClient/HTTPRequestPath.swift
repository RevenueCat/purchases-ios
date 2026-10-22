//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPRequestPath.swift
//
//  Created by Nacho Soto on 8/8/23.

import Foundation

/// Provides endpoint-specific inputs for backend response signature verification.
///
/// Most endpoints use the raw response body and request body. Specialized endpoints can override
/// either input.
protocol ResponseSignatureContextProvider {

    /// Returns the response bytes that should be verified against the backend signature.
    ///
    /// This may throw when deriving the signed payload requires validating response structure first.
    func responsePayloadForSignature(from body: Data?, statusCode: HTTPStatusCode) throws -> Data?

    /// Returns the request body component to include in signature parameters, if any.
    func requestBodyForSignature(for request: HTTPRequest) -> HTTPRequestBody?

}

struct DefaultResponseSignatureContextProvider: ResponseSignatureContextProvider {

    func responsePayloadForSignature(from body: Data?, statusCode: HTTPStatusCode) throws -> Data? {
        return body
    }

    func requestBodyForSignature(for request: HTTPRequest) -> HTTPRequestBody? {
        return request.requestBody
    }

}
