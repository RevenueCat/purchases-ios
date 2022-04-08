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

enum ErrorDetails {

    static let attributeErrorsKey: NSError.UserInfoKey = "attribute_errors"
    static let attributeErrorsResponseKey: NSError.UserInfoKey = "attributes_error_response"
    static let statusCodeErrorKey: NSError.UserInfoKey = "rc_response_status_code"

    static let readableErrorCodeKey: NSError.UserInfoKey = "readable_error_code"
    static let extraContextKey: NSError.UserInfoKey = "extra_context"
    static let fileKey: NSError.UserInfoKey = "source_file"
    static let functionKey: NSError.UserInfoKey = "source_function"

}
