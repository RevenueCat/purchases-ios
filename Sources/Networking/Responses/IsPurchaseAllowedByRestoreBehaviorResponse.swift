//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IsPurchaseAllowedByRestoreBehaviorResponse.swift
//
//  Created by Will Taylor on 2/4/26.

import Foundation

// swiftlint:disable:next type_name
struct IsPurchaseAllowedByRestoreBehaviorResponse: Decodable {

    let isPurchaseAllowedByRestoreBehavior: Bool

}

extension IsPurchaseAllowedByRestoreBehaviorResponse: HTTPResponseBody {}
