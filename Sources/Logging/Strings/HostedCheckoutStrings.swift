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
    case poll_start(_ operationSessionID: String, maxAttempts: Int)
    case poll_succeeded(_ operationSessionID: String)
    case poll_failed(_ operationSessionID: String, code: Int?, message: String?)
    case poll_transient_error(_ operationSessionID: String, error: BackendError)
    case poll_terminal_error(_ operationSessionID: String, error: BackendError)
    case poll_cancelled(_ operationSessionID: String)
    case poll_exhausted(_ operationSessionID: String, maxAttempts: Int)
    case poll_timed_out(_ operationSessionID: String, timeout: TimeInterval)
    case poll_fetching_customer_info(_ operationSessionID: String)
    case poll_customer_info_refresh_failed(_ operationSessionID: String)

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
        case let .poll_start(operationSessionID, maxAttempts):
            return "Asking what became of checkout session \(operationSessionID), up to \(maxAttempts) times."
        case let .poll_succeeded(operationSessionID):
            return "Checkout session \(operationSessionID) succeeded."
        case let .poll_failed(operationSessionID, code, message):
            let detail = code.map { "code \($0) (\(message ?? "no message"))" } ?? "no detail"
            return "Checkout session \(operationSessionID) failed with \(detail)."
        case let .poll_transient_error(operationSessionID, error):
            return "Asking about checkout session \(operationSessionID) failed, trying again: " +
            "\(error.localizedDescription)"
        case let .poll_terminal_error(operationSessionID, error):
            return "Giving up on checkout session \(operationSessionID): \(error.localizedDescription)"
        case let .poll_cancelled(operationSessionID):
            return "Stopped asking about checkout session \(operationSessionID) before it answered."
        case let .poll_exhausted(operationSessionID, maxAttempts):
            return "Checkout session \(operationSessionID) was still under way after \(maxAttempts) attempts."
        case let .poll_timed_out(operationSessionID, timeout):
            return "Checkout session \(operationSessionID) gave no answer within \(Int(timeout)) seconds."
        case let .poll_fetching_customer_info(operationSessionID):
            return "Fetching CustomerInfo for the purchase checkout session \(operationSessionID) landed."
        case let .poll_customer_info_refresh_failed(operationSessionID):
            return "Could not fetch CustomerInfo for the purchase checkout session \(operationSessionID) " +
            "landed. The purchase still stands, and the next fetch will reflect it."
        }
    }

    var category: String { return "hosted_checkout" }

}
