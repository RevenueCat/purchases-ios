//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Result+Extensions.swift
//
//  Created by Nacho Soto on 12/1/21.

extension Result {

    /// Creates a `Result` from either a value or an error.
    /// This is useful for converting from old Objective-C closures to new APIs.
    init( _ value: Success?, _ error: @autoclosure () -> Failure?, file: StaticString = #fileID, line: UInt = #line) {
        if let value = value {
            self = .success(value)
        } else if let error = error() {
            self = .failure(error)
        } else {
            fatalError("Unexpected nil value and nil error", file: file, line: line)
        }
    }

    var value: Success? {
        switch self {
        case let .success(value): return value
        case .failure: return nil
        }
    }

    var error: Failure? {
        switch self {
        case .success: return nil
        case let .failure(error): return error
        }
    }

}

extension Result where Success == Void {

    /// Creates a `Result<Void, Error>` with an optional `Error`.
    init(_ error: Failure?) {
        if let error = error {
            self = .failure(error)
        } else {
            self = .success(())
        }
    }

}

extension Result where Success: OptionalType {

    /// Creates a `Result` from either a value or an error, when `Success` is itself optional.
    ///
    /// Takes `Success` rather than `Success?`: the unconstrained initializer would receive a doubly
    /// optional value, in which an absent value promoted into the outer layer is indistinguishable
    /// from a present one, so `error` would never be read.
    ///
    /// `nil` is a valid success when `Success` is optional, so `error` is checked first and takes
    /// precedence, rather than being shadowed by a value that may be absent.
    init(_ value: Success, _ error: @autoclosure () -> Failure?) {
        if let error = error() {
            self = .failure(error)
        } else {
            self = .success(value)
        }
    }

    /// Converts a `Result<Success?, Error>` into `Result<Success, Error>?`
    var asOptionalResult: Result<Success.Wrapped, Failure>? {
        switch self {
        case let .success(optional):
            if let value = optional.asOptional {
                return .success(value)
            } else {
                return nil
            }
        case let .failure(error):
            return .failure(error)
        }
    }

}

extension Result where Failure == Swift.Error {

    /// Equivalent to `Result.init(catching:)` but with an `async` closure.
    init(catching block: () async throws -> Success) async {
        do {
            self = .success(try await block())
        } catch {
            self = .failure(error)
        }
    }

}
