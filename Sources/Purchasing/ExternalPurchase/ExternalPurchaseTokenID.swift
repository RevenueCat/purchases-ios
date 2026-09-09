//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseTokenID.swift
//
//  Created by Antonio Pallares on 9/9/26.

import Foundation

/// The identifier of an external purchase token registration, which the checkout is handed so that the
/// purchase can be tied back to the token.
///
/// Generated here rather than read back from the registration response, so the identifier exists before the
/// backend knows about it. That is what lets a registration be retried, and lets the checkout open without
/// waiting for one.
enum ExternalPurchaseTokenID {

    /// Follows the format the backend mints: a prefix and a UUID in hexadecimal.
    static func generate() -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        return Self.prefix + uuid
    }

    private static let prefix = "ept"

}
