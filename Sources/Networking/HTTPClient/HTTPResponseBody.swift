//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPResponseBody.swift
//
//  Created by Nacho Soto on 3/30/22.

import Foundation

/// The content of an `HTTPResponse`
protocol HTTPResponseBody {

    static func create(with data: Data) throws -> Self

    /// Returns a copy of this response body updating only the request date
    /// This is useful for types that include a response date (like `CustomerInfo`), that need to
    /// get the most up-to-date time coming from the response header.
    ///
    /// - Note: The default implementation is a no-op.
    func copy(with newRequestDate: Date) -> Self

}

extension HTTPResponseBody {

    func copy(with newRequestDate: Date) -> Self { return self }

}

/// An empty `HTTPResponseBody` for responses with no content.
/// This can be used to obtain an `HTTPResponse` where the content of the response does not matter.
struct HTTPEmptyResponseBody: HTTPResponseBody {

    static func create(with data: Data) throws -> HTTPEmptyResponseBody {
        return .init()
    }

}

// MARK: - Implementations

/// Default implementation of `HTTPResponseBody` for `Data`
extension Data: HTTPResponseBody {

    static func create(with data: Data) throws -> Data {
        return data
    }

}

/// Default implementation of `HTTPResponseBody` for any `Decodable`
extension Decodable {

    static func create(with data: Data) throws -> Self {
        return try JSONDecoder.default.decode(jsonData: data)
    }

}

/// Default implementation of `HTTPResponseBody` for an `Optional<HTTPResponseBody>`
extension Optional: HTTPResponseBody where Wrapped: HTTPResponseBody {

    static func create(with data: Data) throws -> Wrapped? {
        return try Wrapped.create(with: data)
    }

}
