//
//  ErrorResponse.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation

public enum BackendErrorCode: Int {

    case invalidCredentials     = 7002
    case optCodeRequired        = 7008
    case unknown                = -1

}

/// The response content of a failed request.
public struct ErrorResponse {

    public var code: BackendErrorCode
    public var originalCode: Int
    public var message: String

    public init(code: BackendErrorCode, originalCode: Int, message: String) {
        self.code = code
        self.originalCode = originalCode
        self.message = message
    }

}

extension ErrorResponse: Decodable {

    private enum CodingKeys: String, CodingKey {

        case code
        case message

    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let codeAsInteger = try? container.decodeIfPresent(Int.self, forKey: .code)
        let codeAsString = try? container.decodeIfPresent(String.self, forKey: .code)

        self.code = .init(code: codeAsInteger ?? codeAsString)
        self.originalCode = codeAsInteger ?? BackendErrorCode.unknown.rawValue
        self.message = try container.decode(String.self, forKey: .message)
    }

}

// MARK: -

private extension BackendErrorCode {

    init(code: Any?) {
        let codeInt: Int? = (code as? String).flatMap { Int($0) } ?? (code as? Int)

        if let codeInt {
            self = .init(rawValue: codeInt) ?? .unknown
        } else {
            self = .unknown
        }
    }

}
