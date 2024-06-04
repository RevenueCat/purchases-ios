//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesError.swift
//
//  Created by Nacho Soto on 8/31/22.

import Foundation

/// An error returned by a `RevenueCat` public API.
public typealias PublicError = NSError

/// An internal error representation, containing an `ErrorCode` and additional `userInfo`.
///
/// `ErrorCode` is essentially only domain (`ErrorCode.domain`) and a code, but can't contain any more information
/// unless it's converted into an `NSError`.
/// This serves that same purpose, but allows us to pass these around in a type-safe manner,
/// being able to distinguish them from any other `NSError`.
internal struct PurchasesError: Error {

    let error: ErrorCode
    let userInfo: [String: Any]

}

extension PurchasesError {

    /// Converts this error into an error that can be used in a public API.
    /// The error returned by this can be converted to ``ErrorCode``.
    /// Example:
    /// ```
    /// let error = ErrorUtils.unknownError().asPublicError
    /// let errorCode = error as? ErrorCode
    /// ```
    var asPublicError: PublicError {
        return NSError(domain: Self.errorDomain, code: self.errorCode, userInfo: self.userInfo)
    }

}

// MARK: -

extension PurchasesError: CustomNSError {

    static let errorDomain: String = ErrorCode.errorDomain

    var errorCode: Int { return (self.error as NSError).code }
    var errorUserInfo: [String: Any] { return self.userInfo }

}

// MARK: -

extension PurchasesError {

    /// Overload of the default initializer with `NSError.UserInfoKey` as user info key type.
    init(error: ErrorCode, userInfo: [NSError.UserInfoKey: Any]) {
        self.init(error: error, userInfo: userInfo as [String: Any])
    }

}
