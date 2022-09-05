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

    var subscriberAttributesErrors: [String: String]? {
        return self.userInfo[ErrorDetails.attributeErrorsKey] as? [String: String]
    }

}
