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
    let duration: String
    let price: String
    let nextRenewal: Date?
    let willRenew: Bool
    let productIdentifier: String
    let active: Bool

    var renewalString: String {
        return active ? (willRenew ? "Renews" : "Expires") : "Expired"
    }

}
