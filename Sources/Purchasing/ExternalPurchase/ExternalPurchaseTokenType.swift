//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseTokenType.swift
//
//  Created by Antonio Pallares on 3/9/26.

import Foundation

/// The type of external purchase token to request from StoreKit.
///
/// StoreKit takes this as a plain `String`, and which values apply depends on the storefront and on the flow the
/// customer is about to enter. Modelled as a `RawRepresentable` struct rather than an enum so that a value the SDK
/// does not know about can still be forwarded to StoreKit.
internal struct ExternalPurchaseTokenType: RawRepresentable, Hashable, Sendable, Encodable {

    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

}

extension ExternalPurchaseTokenType {

    /// For flows that use an alternative payment provider inside the app.
    static let inApp: Self = .init(rawValue: "IN_APP")

    /// For flows where the customer completes the transaction on a website, outside of the app.
    static let linkOut: Self = .init(rawValue: "LINK_OUT")

}
