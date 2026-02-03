//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseBlockStatusResponse.swift
//
//  Created by RevenueCat.

import Foundation

// swiftlint:disable:next type_name
struct WillPurchaseBeBlockedByTransferBehaviorResponse: Decodable {

    let transactionBelongsToSubscriber: Bool
    let transferBehavior: String

}

extension WillPurchaseBeBlockedByTransferBehaviorResponse: HTTPResponseBody {}
