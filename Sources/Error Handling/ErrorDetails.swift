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

    static let readableErrorCode: NSError.UserInfoKey = "readable_error_code"
    static let backendErrorCode: NSError.UserInfoKey = "rc_backend_error_code"
    static let extraContext: NSError.UserInfoKey = "extra_context"
    static let file: NSError.UserInfoKey = "source_file"
    static let function: NSError.UserInfoKey = "source_function"

}

enum ErrorDetails {

    static let attributeErrorsKey = NSError.UserInfoKey.attributeErrors as String
    static let attributeErrorsResponseKey = NSError.UserInfoKey.attributeErrorsResponse as String
    static let statusCodeKey = NSError.UserInfoKey.statusCode as String

    static let readableErrorCodeKey = NSError.UserInfoKey.readableErrorCode as String
    static let extraContextKey = NSError.UserInfoKey.extraContext as String
    static let fileKey = NSError.UserInfoKey.file as String
    static let functionKey = NSError.UserInfoKey.function as String

}
