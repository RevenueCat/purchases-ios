//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Matchers.swift
//
//  Created by Nacho Soto on 5/16/23.

import Foundation
import Nimble
@testable import RevenueCat

// MARK: - Dates

func beCloseToNow() -> Nimble.Predicate<Date> {
    return beCloseToDate(Date())
}

func beCloseToDate(_ expectedValue: Date) -> Nimble.Predicate<Date> {
    return beCloseTo(expectedValue, within: 1)
}

// MARK: - Errors

// Overloads for `Nimble.matchError` that allows comparing the domain/code between 2 errors
// without failures because `ErrorCode` does not contain `userInfo`.

/// Overload for `Nimble.matchError` that ignores the `PurchasesError` type and compares them as `Error`
/// (comparing the domain and code)
func matchError(_ error: PurchasesError) -> Nimble.Predicate<Error> {
    return Nimble.matchError(error as Error)
}

/// Overload for `Nimble.matchError` that ignores the `ErrorCode` type and compares them as `Error`
/// (comparing the domain and code)
func matchError(_ error: ErrorCode) -> Nimble.Predicate<Error> {
    return Nimble.matchError(error as Error)
}

/// Overload for `Nimble.throwError` that ignores the `PurchasesError` type and compares them as `Error`
/// (comparing the domain and code)
public func throwError<Out>(_ error: PurchasesError) -> Nimble.Predicate<Out> {
    return Nimble.throwError(error as Error)
}

/// Overload for `Nimble.throwError` that ignores the `ErrorCode` type and compares them as `Error`
/// (comparing the domain and code)
public func throwError<Out>(_ error: ErrorCode) -> Nimble.Predicate<Out> {
    return Nimble.throwError(error as Error)
}

// MARK: - Data

func matchJSONData(_ other: Data) -> Nimble.Predicate<Data> {
    return equal(other.serialized)
}

extension Data {

    static func encodeJSON(_ value: Any) -> Data? {
        return try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys, .prettyPrinted])
    }

    /// Decodes and encodes the data to obtain a sorted and pretty printed JSON
    /// This allows comparing 2 different JSON to verify that their contents are equal
    fileprivate var serialized: Data? {
        guard let json = try? JSONSerialization.jsonObject(with: self) else { return nil }
        return Self.encodeJSON(json)
    }

}
