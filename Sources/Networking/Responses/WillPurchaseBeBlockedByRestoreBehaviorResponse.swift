//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WillPurchaseBeBlockedByRestoreBehaviorResponse.swift
//
//  Created by RevenueCat.

import Foundation

// swiftlint:disable:next type_name
struct WillPurchaseBeBlockedByRestoreBehaviorResponse: Decodable {

    let receiptBelongsToOtherSubscriber: Bool
    let transferIsAllowed: Bool

    private enum CodingKeys: String, CodingKey {
        case receiptBelongsToOtherSubscriber = "receipt_belongs_to_other_subscriber"
        case transferIsAllowed = "transfer_is_allowed"
    }

}

extension WillPurchaseBeBlockedByRestoreBehaviorResponse: HTTPResponseBody {}
