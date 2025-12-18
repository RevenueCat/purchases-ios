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
import StoreKit

/// An error returned by a `RevenueCat` public API.
public typealias PublicError = NSError

extension PublicError {
    /// Converts the current Error to a ``ErrorCode``
    public var asErrorCode: ErrorCode? {
        self as? ErrorCode
    }
}

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
    ///
    /// Info about the root error can be accessed in userInfo.
    /// Example:
    /// ```
    /// let error = ErrorUtils.unknownError().asPublicError
    /// let rootErrorInfo = error.userInfo["rc_root_error"] as? [String: Any]
    /// let rootErrorCode = rootErrorInfo?["code"] as? Int
    /// let rootErrorDomain = rootErrorInfo?["domain"] as? String
    /// let rootErrorLocalizedDescription = rootErrorInfo?["localizedDescription"] as? String
    /// ```
    ///
    /// If the root error comes from StoreKit, some extra info will be added to the root error.
    /// Example:
    /// ```
    /// let error = ErrorUtils.unknownError().asPublicError
    /// let rootErrorInfo = error.userInfo["rc_root_error"] as? [String: Any]
    /// let storeKitErrorInfo = rootErrorInfo?["storeKitError"] as? [String: Any]
    /// let storeKitErrorDescription = storeKitErrorInfo?["description"] as? String
    /// // If it's a SKError:
    /// let skErrorCode = storeKitErrorInfo?["skErrorCode"] as? Int
    /// // If it's a StoreKitError.networkError:
    /// let urlErrorCode = storeKitErrorInfo?["urlErrorCode"] as? Int
    /// let urlErrorFailingUrl = storeKitErrorInfo?["urlErrorFailingUrl"] as? String
    /// // If it's a StoreKitError.systemError:
    /// let systemErrorDescription = storeKitErrorInfo?["systemErrorDescription"] as? Int
    /// ```
    var asPublicError: PublicError {
        let rootError: Error = self.rootError(from: self)
        let rootNSError = rootError as NSError
        var rootErrorInfo: [String: Any] = [
            "code": rootNSError.code,
            "domain": rootNSError.domain,
            "localizedDescription": rootNSError.localizedDescription
        ]
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *) {
            if let storeKitErrorInfo = self.getStoreKitErrorInfoIfAny(error: rootError) {
                rootErrorInfo = rootErrorInfo.merging(["storeKitError": storeKitErrorInfo])
            }
        }
        let userInfoToUse = self.userInfo.merging([ErrorDetails.rootErrorKey: rootErrorInfo])
        return NSError(domain: Self.errorDomain, code: self.errorCode, userInfo: userInfoToUse)
    }

    private func rootError(from error: Error) -> Error {
        let nsError = error as NSError
        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            return rootError(from: underlyingError)
        } else {
            return error
        }
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
private extension PurchasesError {

    func getStoreKitErrorInfoIfAny(error: Error) -> [String: Any]? {
        if let skError = error as? SKError {
            return [
                "skErrorCode": skError.code.rawValue,
                "description": skError.code.trackingDescription
            ]
        } else if let storeKitError = error as? StoreKitError {
            let resultMap: [String: Any] = ["description": storeKitError.trackingDescription]
            switch storeKitError {
            case .unknown,
                    .userCancelled,
                    .notAvailableInStorefront,
                    .notEntitled:
                return resultMap
            case let .networkError(urlError):
                return resultMap.merging([
                    "urlErrorCode": urlError.errorCode,
                    "urlErrorFailingUrl": urlError.failureURLString ?? "missing_value"
                ])
            case let .systemError(systemError):
                return resultMap.merging([
                    "systemErrorDescription": systemError.localizedDescription
                ])

            @unknown default:
                Logger.warn(Strings.storeKit.unknown_storekit_error(storeKitError))
                return resultMap
            }
        } else if let storeKitError = error as? StoreKit.Product.PurchaseError {
            return ["description": storeKitError.trackingDescription]
        } else {
            return nil
        }
    }

}
