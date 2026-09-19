//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseRequirement.swift
//
//  Created by Antonio Pallares on 15/9/26.

import Foundation

/// What StoreKit asks of the SDK around a purchase the customer makes outside the App Store.
enum ExternalPurchaseRequirement {

    /// Apple's programme covers the purchase, made through `flow`: its disclosure notice is shown and a token
    /// is reported for it.
    case required(ExternalPurchaseFlow)

    /// Apple's programme does not cover the purchase, so it asks for nothing.
    case notRequired

}

extension ExternalPurchaseRequirement: Equatable, Sendable {}

extension AppleExternalPurchase {

    /// What Apple asks of a purchase of this kind, made through `flow`.
    func requirement(for flow: ExternalPurchaseFlow) -> ExternalPurchaseRequirement {
        switch self {
        case .required:
            return .required(flow)
        case .notRequired:
            return .notRequired
        }
    }

}
