//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdsStrings.swift
//
//  Created by Pol Miro on 27/05/2026.

import Foundation

// swiftlint:disable identifier_name

enum AdsStrings {

    case invalid_virtual_currency_amount(amount: Int)

}

extension AdsStrings: LogMessage {

    var description: String {
        switch self {
        case let .invalid_virtual_currency_amount(amount):
            return "Received an invalid virtual currency amount (\(amount)); falling back to unsupportedReward."
        }
    }

    var category: String { return "ads" }

}
