//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NetworkError.swift
//
//  Created by Nacho Soto on 3/31/22.

// swiftlint:disable multiline_parameters

import Foundation

/// Represents an error created by `HTTPClient`.
enum NetworkError: Swift.Error, Equatable {

    case decoding(NSError, Source)
    case offlineConnection(Source)
    case networkError(NSError, Source)
    case dnsError(failedURL: URL, resolvedHost: String?, Source)
    case unableToCreateRequest(HTTPRequest.Path, Source)
    case unexpectedResponse(URLResponse?, Source)
    case errorResponse(ErrorResponse, HTTPStatusCode, Source)

}

extension NetworkError {

    static func decoding(
        _ error: Error,
        _ data: Data,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        // Explicitly logging errors since it might help debugging issues.
        Logger.error(Strings.network.parsing_json_error(error: error))
        Logger.error(Strings.network.json_data_received(
            dataString: String(data: data, encoding: .utf8) ?? ""
        ))

        return .decoding(error as NSError, .init(file: file, function: function, line: line))
    }

    static func offlineConnection(
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .offlineConnection(.init(file: file, function: function, line: line))
    }

    static func networkError(
        _ error: Error,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .networkError(error as NSError, .init(file: file, function: function, line: line))
    }

    static func dnsError(
        failedURL: URL, resolvedHost: String?,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .dnsError(failedURL: failedURL, resolvedHost: resolvedHost,
                         .init(file: file, function: function, line: line))
    }

    static func unableToCreateRequest(
        _ path: HTTPRequest.Path,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .unableToCreateRequest(path, .init(file: file, function: function, line: line))
    }

    static func unexpectedResponse(
        _ response: URLResponse?,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .unexpectedResponse(response, .init(file: file, function: function, line: line))
    }

    static func errorResponse(
        _ response: ErrorResponse, _ statusCode: HTTPStatusCode,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .errorResponse(response, statusCode, .init(file: file, function: function, line: line))
    }

}

extension NetworkError: PurchasesErrorConvertible {

    var asPurchasesError: PurchasesError {
        switch self {
        case let .decoding(error, source):
            return ErrorUtils.unexpectedBackendResponse(
                withSubError: error,
                fileName: source.file,
                functionName: source.function,
                line: source.line
            )

        case let .offlineConnection(source):
            return ErrorUtils.offlineConnectionError(
                fileName: source.file,
                functionName: source.function,
                line: source.line
            )

        case let .networkError(error, source):
            return ErrorUtils.networkError(
                withUnderlyingError: error,
                fileName: source.file,
                functionName: source.function,
                line: source.line
            )

        case let .dnsError(failedURL, resolvedHost, source):
            return ErrorUtils.networkError(
                message: NetworkStrings.blocked_network(url: failedURL, newHost: resolvedHost).description,
                withUnderlyingError: self,
                fileName: source.file,
                functionName: source.function,
                line: source.line
            )

        case let .unableToCreateRequest(path, source):
            return ErrorUtils.networkError(
                extraUserInfo: [
                    "request_url": path.description
                ],
                fileName: source.file,
                functionName: source.function,
                line: source.line
            )

        case let .unexpectedResponse(response, source):
            return ErrorUtils.unexpectedBackendResponseError(
                extraUserInfo: [
                    "response": response?.description ?? ""
                ],
                fileName: source.file,
                functionName: source.function,
                line: source.line
            )

        case let .errorResponse(response, statusCode, source):
            return response.asBackendError(with: statusCode,
                                           file: source.file,
                                           function: source.function,
                                           line: source.line)

        }
    }

}

extension NetworkError: DescribableError {}

extension NetworkError {

    /// Whether the network request producing this error actually synced the data.
    var successfullySynced: Bool {
        return self.errorStatusCode?.isSuccessfullySynced ?? false
    }

    /// Whether the network request producing this error can be completed.
    /// If `false`, the response was a server error.
    var finishable: Bool {
        if let statusCode = self.errorStatusCode {
            return !statusCode.isServerError
        } else {
            return false
        }
    }

    private var errorStatusCode: HTTPStatusCode? {
        switch self {
        case let .errorResponse(_, statusCode, _):
            return statusCode

        case .offlineConnection,
             .decoding,
             .networkError,
             .dnsError,
             .unableToCreateRequest,
             .unexpectedResponse:
            return nil
        }
    }

}

extension NetworkError {

    typealias Source = ErrorSource

}
