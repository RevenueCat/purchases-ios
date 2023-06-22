//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPResponse.swift
//
//  Created by César de la Vega on 4/19/21.
//

import Foundation

struct HTTPResponse<Body: HTTPResponseBody> {

    typealias Result = Swift.Result<Self, NetworkError>
    typealias Headers = [AnyHashable: Any]

    var statusCode: HTTPStatusCode
    /// Because this property is a standard Swift dictionary, its keys are case-sensitive.
    /// To perform a case-insensitive header lookup, use the `value(forHeaderField:)` method instead.
    var responseHeaders: HTTPClient.ResponseHeaders
    var body: Body
    var requestDate: Date?
    var verificationResult: VerificationResult

}

extension HTTPResponse: CustomStringConvertible {

    var description: String {
        let body: String = {
            if let bodyDescription = (self.body as? CustomStringConvertible)?.description {
                return bodyDescription
            } else {
                return "\(type(of: self.body))"
            }
        }()

        return """
        HTTPResponse(
            statusCode: \(self.statusCode.rawValue),
            body: \(body),
            verification: \(self.verificationResult)
        )
        """
    }

}

extension HTTPResponse {

    /// Equivalent to `HTTPURLResponse.value(forHTTPHeaderField:)`
    /// In keeping with the HTTP RFC, HTTP header field names are case-insensitive.
    func value(forHeaderField field: String) -> String? {
        return Self.value(forCaseInsensitiveHeaderField: field, in: self.responseHeaders)
    }

    static func value(
        forCaseInsensitiveHeaderField field: HTTPClient.ResponseHeader,
        in headers: Headers
    ) -> String? {
        return Self.value(forCaseInsensitiveHeaderField: field.rawValue, in: headers)
    }

    static func value(forCaseInsensitiveHeaderField field: String, in headers: Headers) -> String? {
        let header = headers
            .first { (key, _) in
                (key as? String)?.caseInsensitiveCompare(field) == .orderedSame
            }

        return header?.value as? String
    }

}

extension HTTPResponse where Body: OptionalType, Body.Wrapped: HTTPResponseBody {

    /// Converts a `HTTPResponse<Body?>` into a `HTTPResponse<Body>?`
    var asOptionalResponse: HTTPResponse<Body.Wrapped>? {
        guard let body = self.body.asOptional else {
            return nil
        }

        return .init(statusCode: self.statusCode,
                     responseHeaders: self.responseHeaders,
                     body: body,
                     requestDate: self.requestDate,
                     verificationResult: self.verificationResult)
    }

}

extension HTTPResponse {

    func mapBody<NewBody>(_ mapping: (Body) throws -> NewBody) rethrows -> HTTPResponse<NewBody> {
        return .init(statusCode: self.statusCode,
                     responseHeaders: self.responseHeaders,
                     body: try mapping(self.body),
                     requestDate: self.requestDate,
                     verificationResult: self.verificationResult)
    }

    func copy(with newVerificationResult: VerificationResult) -> Self {
        guard newVerificationResult != self.verificationResult else { return self }

        return .init(
            statusCode: self.statusCode,
            responseHeaders: self.responseHeaders,
            body: self.body,
            requestDate: self.requestDate,
            verificationResult: newVerificationResult
        )
    }

}
