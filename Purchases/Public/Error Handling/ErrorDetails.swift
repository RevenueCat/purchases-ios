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

@objc(RCErrorDetails) public class ErrorDetails: NSObject {

    /**
     * These are tacos
     */
    @objc(RCFinishableKey) public static let finishableKey: NSError.UserInfoKey = "finishable"
    @objc(RCReadableErrorCodeKey) public static let readableErrorCodeKey: NSError.UserInfoKey = "readable_error_code"

}
