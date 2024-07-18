//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionInformation.swift
//
//
//  Created by Cesar de la Vega on 28/5/24.
//

import Foundation

struct SubscriptionInformation {

    let title: String
    let durationTitle: String
    let price: String
    let expirationDateString: String?
    let productIdentifier: String

    var expirationString: String {
        return active ? (
            willRenew ? String(localized: "Next billing date") : String(localized: "Expires")
        ) : String(localized: "Expired")
    }

    var explanation: String {
        return active ? (
            willRenew ?
                String(localized: "This is your subscription with the earliest billing date.") :
                String(localized: "This is your subscription with the earliest expiration date.")
        ) : String(localized: "This subscription has expired.")
    }

    private let willRenew: Bool
    private let active: Bool

    init(title: String,
         durationTitle: String,
         price: String,
         expirationDateString: String?,
         willRenew: Bool,
         productIdentifier: String,
         active: Bool
    ) {
        self.title = title
        self.durationTitle = durationTitle
        self.price = price
        self.expirationDateString = expirationDateString
        self.productIdentifier = productIdentifier
        self.willRenew = willRenew
        self.active = active
    }

}
