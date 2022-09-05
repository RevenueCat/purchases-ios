//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ErrorMatcher.swift
//
//  Created by Nacho Soto on 8/29/22.

import Nimble

@testable import RevenueCat

// Overloads for `Nimble.matchError` that allows comparing the domain/code between 2 errors
// without failures because `ErrorCode` does not contain `userInfo`.

/// Overload for `Nimble.matchError` that ignores the `PurchasesError` type and compares them as `Error`
/// (comparing the domain and code)
func matchError(_ error: PurchasesError) -> Predicate<Error> {
    return Nimble.matchError(error as Error)
}

/// Overload for `Nimble.matchError` that ignores the `ErrorCode` type and compares them as `Error`
/// (comparing the domain and code)
func matchError(_ error: ErrorCode) -> Predicate<Error> {
    return Nimble.matchError(error as Error)
}

/// Overload for `Nimble.throwError` that ignores the `PurchasesError` type and compares them as `Error`
/// (comparing the domain and code)
public func throwError<Out>(_ error: PurchasesError) -> Predicate<Out> {
    return Nimble.throwError(error as Error)
}

/// Overload for `Nimble.throwError` that ignores the `ErrorCode` type and compares them as `Error`
/// (comparing the domain and code)
public func throwError<Out>(_ error: ErrorCode) -> Predicate<Out> {
    return Nimble.throwError(error as Error)
}
