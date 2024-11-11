//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// WebRedemptionStrings.swift
//
// Created by Antonio Rico Diez on 2024-10-17.

import Foundation

// swiftlint:disable identifier_name

enum WebRedemptionStrings {

    case redeeming_web_purchase
    case redeemed_web_purchase
    case error_redeeming_web_purchase(_ error: BackendError)

}

extension WebRedemptionStrings: LogMessage {

    var description: String {
        switch self {
        case .redeeming_web_purchase:
            return "Redeeming web purchase."
        case .redeemed_web_purchase:
            return "Web purchase redeemed successfully."
        case let .error_redeeming_web_purchase(error):
            return "Error redeeming web purchase: \(error.localizedDescription)"
        }
    }

    var category: String { return "web_redemption" }

}
