//
//  HTTPStatusCode.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation

public enum HTTPStatusCode {

    case success
    case createdSuccess
    case redirect
    case notModified
    case temporaryRedirect
    case invalidRequest
    case unauthorized
    case forbidden
    case notFoundError
    case internalServerError
    case networkConnectTimeoutError

    case other(Int)

    private static let knownStatus: Set<HTTPStatusCode> = [
        .success,
        .createdSuccess,
        .redirect,
        .notModified,
        .temporaryRedirect,
        .invalidRequest,
        .unauthorized,
        .forbidden,
        .notFoundError,
        .internalServerError,
        .networkConnectTimeoutError
    ]
    private static let statusByCode: [Int: HTTPStatusCode] = Self.knownStatus.dictionaryWithKeys { $0.rawValue }
}

extension HTTPStatusCode: RawRepresentable {

    public init(rawValue: Int) {
        self = Self.statusByCode[rawValue] ?? .other(rawValue)
    }

    public var rawValue: Int {
        switch self {
        case .success: return 200
        case .createdSuccess: return 201
        case .redirect: return 300
        case .notModified: return 304
        case .temporaryRedirect: return 307
        case .invalidRequest: return 400
        case .unauthorized: return 401
        case .forbidden: return 403
        case .notFoundError: return 404
        case .internalServerError: return 500
        case .networkConnectTimeoutError: return 599

        case let .other(code): return code
        }
    }

}

extension HTTPStatusCode: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: IntegerLiteralType) {
        self.init(rawValue: value)
    }

}

extension HTTPStatusCode: Hashable {}

extension HTTPStatusCode: Codable {}

extension HTTPStatusCode {

    var isSuccessfulResponse: Bool {
        return 200...399 ~= self.rawValue
    }

    var isServerError: Bool {
        return 500...599 ~= self.rawValue
    }

}
