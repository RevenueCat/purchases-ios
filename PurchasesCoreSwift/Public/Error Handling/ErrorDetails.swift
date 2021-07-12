//
//  ErrorDetails.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 7/12/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@objc(RCErrorDetails) public class ErrorDetails: NSObject {

    @objc(RCFinishableKey) public static let finishableKey: NSError.UserInfoKey = "finishable"
    @objc(RCReadableErrorCodeKey) public static let readableErrorCodeKey: NSError.UserInfoKey = "readable_error_code"

}
