//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ErrorDetails.swift
//
//  Created by Joshua Liebowitz on 7/12/21.
//

import Foundation

extension NSError.UserInfoKey {

    static let attributeErrors: NSError.UserInfoKey = "attribute_errors"
    static let attributeErrorsResponse: NSError.UserInfoKey = "attributes_error_response"
    static let statusCode: NSError.UserInfoKey = "rc_response_status_code"
    static let obfuscatedEmail: NSError.UserInfoKey = "rc_obfuscated_email"
    static let rootError: NSError.UserInfoKey = "rc_root_error"

    static let readableErrorCode: NSError.UserInfoKey = "readable_error_code"
    static let backendErrorCode: NSError.UserInfoKey = "rc_backend_error_code"
    static let extraContext: NSError.UserInfoKey = "extra_context"
    static let file: NSError.UserInfoKey = "source_file"
    static let function: NSError.UserInfoKey = "source_function"

    /// Key for `userInfo` indicating the purchase may have been interrupted by an external payment app.
    ///
    /// When this key is present and `true` in a `purchaseCancelledError`, the app was backgrounded
    /// during the purchase flow. This can occur when the user is redirected to an external payment app
    /// (e.g., UPI apps in India). In this case, the purchase may have actually succeeded.
    ///
    /// Developers should call `Purchases.shared.customerInfo()` to verify the actual entitlement status
    /// when this key is present.
    public static let purchaseWasBackgroundedKey: NSError.UserInfoKey = "rc_purchase_was_backgrounded"

}

enum ErrorDetails {

    static let attributeErrorsKey = NSError.UserInfoKey.attributeErrors as String
    static let attributeErrorsResponseKey = NSError.UserInfoKey.attributeErrorsResponse as String
    static let statusCodeKey = NSError.UserInfoKey.statusCode as String
    static let obfuscatedEmailKey = NSError.UserInfoKey.obfuscatedEmail as String
    static let rootErrorKey = NSError.UserInfoKey.rootError as String

    static let readableErrorCodeKey = NSError.UserInfoKey.readableErrorCode as String
    static let extraContextKey = NSError.UserInfoKey.extraContext as String
    static let fileKey = NSError.UserInfoKey.file as String
    static let functionKey = NSError.UserInfoKey.function as String

}
