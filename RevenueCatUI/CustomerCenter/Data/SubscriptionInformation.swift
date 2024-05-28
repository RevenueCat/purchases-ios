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
    let nextRenewal: String
    let willRenew: Bool
    let productIdentifier: String
    let active: Bool

    var renewalString: String {
        return active ? (willRenew ? "Renews" : "Expires") : "Expired"
    }

}
