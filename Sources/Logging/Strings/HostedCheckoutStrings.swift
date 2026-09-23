//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckoutStrings.swift
//
//  Created by Antonio Pallares on 8/9/26.

import Foundation

// swiftlint:disable identifier_name

enum HostedCheckoutStrings {

    case starting_checkout(_ packageID: String)
    case no_registered_token
    case session_created(_ operationSessionID: String)
    case product_already_purchased(_ packageID: String)
    case error_creating_session(_ error: BackendError)
    case unknown_status(_ status: String)

}

extension HostedCheckoutStrings: LogMessage {

    var description: String {
        switch self {
        case let .starting_checkout(packageID):
            return "Starting a checkout for package \(packageID)."
        case .no_registered_token:
            return "Not starting a checkout: there is no registered external purchase token to attribute it to."
        case let .session_created(operationSessionID):
            return "Created checkout session \(operationSessionID)."
        case let .product_already_purchased(packageID):
            return "Not starting a checkout: this customer already has an active purchase for the product " +
            "in package \(packageID)."
        case let .error_creating_session(error):
            return "Error creating the checkout session: \(error.localizedDescription)"
        case let .unknown_status(status):
            return "Unknown checkout session status '\(status)'. Treating the session as still under way."
        }
    }

    var category: String { return "hosted_checkout" }

}
