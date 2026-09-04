//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseStrings.swift
//
//  Created by Antonio Pallares on 4/9/26.

import Foundation

// swiftlint:disable identifier_name

enum ExternalPurchaseStrings {

    case eligibility_resolved(_ canMakeExternalPurchases: Bool)
    case cannot_make_external_purchases
    case notice_cancelled
    case error_showing_notice(_ error: Error)
    case no_token_available
    case error_requesting_token(_ error: Error)
    case token_registered(_ tokenID: String)
    case error_registering_token(_ error: BackendError)

}

extension ExternalPurchaseStrings: LogMessage {

    var description: String {
        switch self {
        case let .eligibility_resolved(canMakeExternalPurchases):
            return "Can make external purchases: \(canMakeExternalPurchases)."
        case .cannot_make_external_purchases:
            return "Not preparing an external purchase: this app cannot offer one to this customer."
        case .notice_cancelled:
            return "The customer chose not to continue to the external purchase."
        case let .error_showing_notice(error):
            return "Error showing the external purchase notice: \(error.localizedDescription)"
        case .no_token_available:
            return "No external purchase token available. The purchase will not be reported."
        case let .error_requesting_token(error):
            return "Error requesting the external purchase token: \(error.localizedDescription). " +
            "The purchase will not be reported."
        case let .token_registered(tokenID):
            return "Registered external purchase token \(tokenID)."
        case let .error_registering_token(error):
            return "Error registering the external purchase token: \(error.localizedDescription). " +
            "The purchase will not be reported."
        }
    }

    var category: String { return "external_purchase" }

}
