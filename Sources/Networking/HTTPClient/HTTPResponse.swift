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
        HTTPResponse(" +
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
                     verificationResult: self.verificationResult)
    }

}

extension HTTPResponse {

    func mapBody<NewBody>(_ mapping: (Body) throws -> NewBody) rethrows -> HTTPResponse<NewBody> {
        return .init(statusCode: self.statusCode,
                     responseHeaders: self.responseHeaders,
                     body: try mapping(self.body),
                     verificationResult: self.verificationResult)
    }

}

// MARK: -

/// The response content of a failed request.
struct ErrorResponse: Equatable {

    var code: BackendErrorCode
    var originalCode: Int
    var message: String?
    var attributeErrors: [String: String] = [:]

}

extension ErrorResponse {

    /// Converts this `ErrorResponse` into an `ErrorCode` backed by the corresponding `BackendErrorCode`.
    func asBackendError(
        with statusCode: HTTPStatusCode,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> PurchasesError {
        var userInfo: [NSError.UserInfoKey: Any] = [
            .statusCode: statusCode.rawValue
        ]

        if !self.attributeErrors.isEmpty {
            userInfo[.attributeErrors] = self.attributeErrors as NSDictionary
        }

        let message: String? = self.code != .unknownBackendError
            ? self.message
            : [
                self.message,
                // Append original error code if we couldn't map it to a value.
                "(\(self.originalCode))"
            ]
            .compactMap { $0 }
            .joined(separator: " ")

        return ErrorUtils.backendError(
            withBackendCode: self.code,
            originalBackendErrorCode: self.originalCode,
            message: self.attributeErrors.isEmpty
                ? nil
                : self.attributeErrors.description,
            backendMessage: message,
            extraUserInfo: userInfo,
            fileName: file, functionName: function, line: line
        )
    }

}

extension ErrorResponse: Decodable {

    private enum CodingKeys: String, CodingKey {

        case code
        case message
        case attributeErrors

    }

    private struct AttributeError: Decodable {

        let keyName: String
        let message: String

    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let codeAsInteger = try? container.decodeIfPresent(Int.self, forKey: .code)
        let codeAsString = try? container.decodeIfPresent(String.self, forKey: .code)

        self.code = BackendErrorCode(code: codeAsInteger ?? codeAsString)
        self.originalCode = codeAsInteger ?? BackendErrorCode.unknownBackendError.rawValue
        self.message = try container.decodeIfPresent(String.self, forKey: .message)

        let attributeErrors = (
            try? container.decodeIfPresent(Array<AttributeError>.self,
                                           forKey: .attributeErrors)
        ) ?? []

        self.attributeErrors = attributeErrors
            .dictionaryAllowingDuplicateKeys { $0.keyName }
            .mapValues { $0.message }
    }

}

extension ErrorResponse {

    /// For some endpoints the backend may return `ErrorResponse` inside of this wrapper.
    private struct Wrapper: Decodable {

        let attributesErrorResponse: ErrorResponse

    }

    private static func parseWrapper(_ data: Data) -> Wrapper? {
        return try? JSONDecoder.default.decode(jsonData: data, logErrors: false)
    }

    /// Creates an `ErrorResponse` with the content of an `HTTPResponse`.
    /// This method supports extracting error information from the root, or from inside `"attributes_error_response"`
    /// - Note: if the error couldn't be decoded, a default error is created.
    /// - Warning: this is "deprecated". Ideally in the future all `ErrorResponses` are created from `Data`.
    static func from(_ dictionary: [String: Any]) -> Self {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary) else {
            return .defaultResponse
        }

        return Self.from(data)
    }

    /// Creates an `ErrorResponse` with the content of an `HTTPResponse`.
    /// This method supports extracting error information from the root, or from inside `"attributes_error_response"`
    /// - Note: if the error couldn't be decoded, a default error is created.
    static func from(_ data: Data) -> Self {
        do {
            if let wrapper = Self.parseWrapper(data) {
                return wrapper.attributesErrorResponse
            } else {
                return try JSONDecoder.default.decode(jsonData: data)
            }
        } catch {
            Logger.error(Strings.codable.decoding_error(error))

            return Self.defaultResponse
        }
    }

    private static let defaultResponse: Self = .init(code: .unknownError,
                                                     originalCode: BackendErrorCode.unknownError.rawValue,
                                                     message: nil)

}
