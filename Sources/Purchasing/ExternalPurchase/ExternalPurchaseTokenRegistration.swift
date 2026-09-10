//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseTokenRegistration.swift
//
//  Created by Antonio Pallares on 10/9/26.

import Foundation

/// Everything the backend needs to register an external purchase token.
///
/// Kept because Apple expects a report for every token minted, including the ones whose registration did not
/// reach RevenueCat, so a registration has to survive the session it was minted in.
internal struct ExternalPurchaseTokenRegistration: Codable, Equatable, Sendable {

    /// The identifier generated for this registration, which the checkout is handed.
    let tokenID: String

    /// The customer the token was minted for.
    let appUserID: String

    let purchaseType: ExternalPurchaseTokenType

    /// The StoreKit token, absent where StoreKit had none to give.
    let token: String?

    /// The SDK encodes keys into snake case and decodes them back into camel case, and that round trip does
    /// not return an `ID` suffix, so the keys are spelled out.
    private enum CodingKeys: String, CodingKey {
        case tokenID = "tokenId"
        case appUserID = "appUserId"
        case purchaseType
        case token
    }

}
