//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPStatusCode.swift
//
//  Created by César de la Vega on 4/19/21.
//

import Foundation

enum HTTPStatusCode {

    case success
    case createdSuccess
    case redirect
    case notModified
    case invalidRequest
    case notFoundError
    case internalServerError
    case networkConnectTimeoutError

    case other(Int)

    private static let knownStatus: Set<HTTPStatusCode> = [
        .success,
        .createdSuccess,
        .redirect,
        .notModified,
        .invalidRequest,
        .notFoundError,
        .internalServerError,
        .networkConnectTimeoutError
    ]
    private static let statusByCode: [Int: HTTPStatusCode] = Self.knownStatus.dictionaryWithKeys { $0.rawValue }
}

extension HTTPStatusCode: RawRepresentable {

    init(rawValue: Int) {
        self = Self.statusByCode[rawValue] ?? .other(rawValue)
    }

    var rawValue: Int {
        switch self {
        case .success: return 200
        case .createdSuccess: return 201
        case .redirect: return 300
        case .notModified: return 304
        case .invalidRequest: return 400
        case .notFoundError: return 404
        case .internalServerError: return 500
        case .networkConnectTimeoutError: return 599

        case let .other(code): return code
        }
    }

}

extension HTTPStatusCode: ExpressibleByIntegerLiteral {

    init(integerLiteral value: IntegerLiteralType) {
        self.init(rawValue: value)
    }

}

extension HTTPStatusCode: Hashable {}

extension HTTPStatusCode: Codable {}

extension HTTPStatusCode {

    var isSuccessfulResponse: Bool {
        return 200...299 ~= self.rawValue
    }

    var isServerError: Bool {
        return 500...599 ~= self.rawValue
    }

    var isSuccessfullySynced: Bool {
        return !(self.isServerError || self == .notFoundError)
    }

}
