//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Error+Extensions.swift
//
//  Created by Joshua Liebowitz on 8/6/21.

import Foundation

extension NSError {

    var successfullySynced: Bool {
        if code == ErrorCode.networkError.rawValue {
            return false
        }

        if let successfullySyncedNumber = userInfo[Backend.RCSuccessfullySyncedKey as String] as? NSNumber {
            return successfullySyncedNumber.boolValue
        }

        return false
    }

    var subscriberAttributesErrors: [String: String]? {
        return userInfo[Backend.RCAttributeErrorsKey as String] as? [String: String]
    }

}
