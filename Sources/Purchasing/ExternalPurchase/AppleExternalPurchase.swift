//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppleExternalPurchase.swift
//
//  Created by Antonio Pallares on 15/9/26.

import Foundation

/// Whether Apple's external purchase programme covers what is being bought.
///
/// Anything Apple takes a commission on does, and buying it outside the App Store means showing Apple's
/// disclosure notice and reporting a token for the purchase. Physical goods do not: Apple's rules leave them
/// alone, so a purchase of one is the app's own business.
enum AppleExternalPurchase {

    /// Apple's programme covers the purchase.
    case required

    /// Apple's programme does not cover the purchase.
    case notRequired

}

extension AppleExternalPurchase: Equatable, Sendable {}

extension AppleExternalPurchase: Codable {

    private enum WireValue: String {

        case required
        case notRequired = "not_required"

    }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)

        switch WireValue(rawValue: value) {
        case .notRequired:
            self = .notRequired
        // A value this version of the SDK does not know is read as Apple's programme applying, which is the
        // reading that keeps a purchase within Apple's rules.
        case .required, nil:
            self = .required
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .required:
            try container.encode(WireValue.required.rawValue)
        case .notRequired:
            try container.encode(WireValue.notRequired.rawValue)
        }
    }

}
