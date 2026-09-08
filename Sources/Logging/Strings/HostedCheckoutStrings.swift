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
    case external_purchase_skipped_with_test_store
    case no_registered_token
    case session_created(_ operationSessionID: String)
    case error_creating_session(_ error: BackendError)

}

extension HostedCheckoutStrings: LogMessage {

    var description: String {
        switch self {
        case let .starting_checkout(packageID):
            return "Starting a checkout for package \(packageID)."
        case .external_purchase_skipped_with_test_store:
            return "Skipping the external purchase: the SDK is configured with a Test Store API key."
        case .no_registered_token:
            return "Not starting a checkout: there is no registered external purchase token to attribute it to."
        case let .session_created(operationSessionID):
            return "Created checkout session \(operationSessionID)."
        case let .error_creating_session(error):
            return "Error creating the checkout session: \(error.localizedDescription)"
        }
    }

    var category: String { return "hosted_checkout" }

}
