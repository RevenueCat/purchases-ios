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

/// A type that represents an HTTP response
protocol HTTPResponseType {

    associatedtype Body: HTTPResponseBody

    typealias Result = Swift.Result<Self, NetworkError>
    typealias Headers = [AnyHashable: Any]

    var httpStatusCode: HTTPStatusCode { get }
    /// Because this property is a standard Swift dictionary, its keys are case-sensitive.
    /// To perform a case-insensitive header lookup, use the `value(forHeaderField:)` method instead.
    var responseHeaders: HTTPClient.ResponseHeaders { get }
    var body: Body { get }
    var requestDate: Date? { get }
    var origin: HTTPResponseOrigin { get }

}

struct HTTPResponse<Body: HTTPResponseBody>: HTTPResponseType {

    var httpStatusCode: HTTPStatusCode
    var responseHeaders: HTTPClient.ResponseHeaders
    var body: Body
    var requestDate: Date?
    var origin: HTTPResponseOrigin = .backend

}

extension HTTPResponse: CustomStringConvertible {

    fileprivate var bodyDescription: String {
        if let bodyDescription = (self.body as? CustomStringConvertible)?.description {
            return bodyDescription
        } else {
            return "\(type(of: self.body))"
        }
    }

    var description: String {
        return """
        HTTPResponse(
            statusCode: \(self.httpStatusCode.rawValue),
            body: \(self.bodyDescription),
            requestDate: \(self.requestDate?.description ?? "<>")
        )
        """
    }

}

// MARK: - VerifiedHTTPResponse

struct VerifiedHTTPResponse<Body: HTTPResponseBody>: HTTPResponseType {

    var response: HTTPResponse<Body>
    var verificationResult: VerificationResult

    init(response: HTTPResponse<Body>, verificationResult: VerificationResult) {
        self.response = response
        self.verificationResult = verificationResult
    }

    init(
        httpStatusCode: HTTPStatusCode,
        responseHeaders: HTTPClient.ResponseHeaders,
        body: Body,
        requestDate: Date? = nil,
        verificationResult: VerificationResult
    ) {
        self.init(
            response: .init(
                httpStatusCode: httpStatusCode,
                responseHeaders: responseHeaders,
                body: body,
                requestDate: requestDate
            ),
            verificationResult: verificationResult
        )
    }

}

extension VerifiedHTTPResponse: CustomStringConvertible {

    var description: String {
        return """
        VerifiedHTTPResponse(
            statusCode: \(self.httpStatusCode.rawValue),
            body: \(self.response.bodyDescription),
            requestDate: \(self.requestDate?.description ?? "<>")
            verification: \(self.verificationResult)
        )
        """
    }

}

// MARK: - URLResponse

/// `HTTPURLResponse` conformance to `HTTPResponseType`
extension HTTPURLResponse: HTTPResponseType {

    typealias Body = Data?

    var httpStatusCode: HTTPStatusCode { .init(rawValue: self.statusCode) }

    var responseHeaders: HTTPClient.ResponseHeaders { return self.allHeaderFields }

    var body: Data? { return nil }

    var requestDate: Date? { HTTPResponse<Data>.parseRequestDate(headers: self.responseHeaders) }

    var origin: HTTPResponseOrigin { .backend }

}

// MARK: - Extensions

extension HTTPResponseType {

    /// Equivalent to `HTTPURLResponse.value(forHTTPHeaderField:)`
    /// In keeping with the HTTP RFC, HTTP header field names are case-insensitive.
    func value(forHeaderField field: HTTPClient.ResponseHeader) -> String? {
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

extension VerifiedHTTPResponse where Body: OptionalType, Body.Wrapped: HTTPResponseBody {

    /// Converts a `VerifiedHTTPResponse<Body?>` into a `VerifiedHTTPResponse<Body>?`
    var asOptionalResponse: VerifiedHTTPResponse<Body.Wrapped>? {
        guard let body = self.body.asOptional else {
            return nil
        }

        return self.mapBody { _ in body }
    }

}

extension HTTPResponse {

    func mapBody<NewBody>(_ mapping: (Body) throws -> NewBody) rethrows -> HTTPResponse<NewBody> {
        return .init(httpStatusCode: self.httpStatusCode,
                     responseHeaders: self.responseHeaders,
                     body: try mapping(self.body),
                     requestDate: self.requestDate)
    }

    func verified(with verificationResult: VerificationResult) -> VerifiedHTTPResponse<Body> {
        return .init(
            response: self,
            verificationResult: verificationResult
        )
    }

}

extension HTTPResponse {

    /// Creates an `HTTPResponse` extracting the `requestDate` from its headers
    init(
        httpStatusCode: HTTPStatusCode,
        responseHeaders: HTTPClient.ResponseHeaders,
        body: Body
    ) {
        self.httpStatusCode = httpStatusCode
        self.responseHeaders = responseHeaders
        self.body = body
        self.requestDate = Self.parseRequestDate(headers: responseHeaders)
    }

    fileprivate static func parseRequestDate(headers: HTTPResponseType.Headers) -> Date? {
        guard let stringValue = Self.value(
            forCaseInsensitiveHeaderField: HTTPClient.ResponseHeader.requestDate.rawValue,
            in: headers
        ),
              let intValue = UInt64(stringValue) else { return nil }

        return .init(millisecondsSince1970: intValue)
    }

}

extension VerifiedHTTPResponse {

    var httpStatusCode: HTTPStatusCode { self.response.httpStatusCode }
    var responseHeaders: HTTPClient.ResponseHeaders { self.response.responseHeaders }
    var body: Body { self.response.body }
    var requestDate: Date? { self.response.requestDate }
    var origin: HTTPResponseOrigin { self.response.origin }

    func mapBody<NewBody>(_ mapping: (Body) throws -> NewBody) rethrows -> VerifiedHTTPResponse<NewBody> {
        return .init(
            response: try self.response.mapBody(mapping),
            verificationResult: self.verificationResult
        )
    }

}

enum HTTPResponseOrigin {

    case backend
    case cache

}
