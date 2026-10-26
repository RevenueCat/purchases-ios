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
    case session_resumed(_ operationSessionID: String)
    case session_paid(_ operationSessionID: String)
    case unrecognized_outcome(_ outcome: String)
    case product_already_purchased(_ packageID: String)
    case error_creating_session(_ error: BackendError)
    case unrecognized_status(_ status: String)
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
        case let .session_resumed(operationSessionID):
            return "Resuming checkout session \(operationSessionID)."
        case let .session_paid(operationSessionID):
            return "Checkout session \(operationSessionID) was already paid for. Confirming it instead of " +
            "starting another checkout."
        case let .unrecognized_outcome(outcome):
            return "Unrecognized checkout session outcome '\(outcome)'. Treating the session as a new one."
        case let .product_already_purchased(packageID):
            return "Not starting a checkout: this customer already has an active purchase for the product " +
            "in package \(packageID)."
        case let .error_creating_session(error):
            return "Error creating the checkout session: \(error.localizedDescription)"
        case let .unrecognized_status(status):
            return "Unrecognized checkout session status '\(status)'. Treating the session as still under way."
        case let .poll_start(operationSessionID, maxAttempts):
            return "Starting to poll checkout session \(operationSessionID), up to \(maxAttempts) times."
        case let .poll_succeeded(operationSessionID):
            return "Checkout session \(operationSessionID) succeeded."
        case let .poll_failed(operationSessionID, code, message):
            let detail = code.map { "code \($0) (\(message ?? "no message"))" } ?? "no detail"
            return "Checkout session \(operationSessionID) failed with \(detail)."
        case let .poll_transient_error(operationSessionID, error):
            return "Polling checkout session \(operationSessionID) failed, trying again: " +
            "\(error.localizedDescription)"
        case let .poll_terminal_error(operationSessionID, error):
            return "Aborting polling checkout session \(operationSessionID) due to an error: " +
            "\(error.localizedDescription)"
        case let .poll_cancelled(operationSessionID):
            return "Polling checkout session \(operationSessionID) was cancelled before it answered."
        case let .poll_exhausted(operationSessionID, maxAttempts):
            return "Checkout session \(operationSessionID) was still under way after \(maxAttempts) attempts."
        case let .poll_timed_out(operationSessionID, timeout):
            return "Checkout session \(operationSessionID) gave no answer within \(Int(timeout)) seconds."
        case let .poll_fetching_customer_info(operationSessionID):
            return "Fetching CustomerInfo, since checkout session \(operationSessionID) says the customer owns " +
            "the product."
        case let .poll_customer_info_refresh_failed(operationSessionID):
            return "Could not fetch CustomerInfo, though checkout session \(operationSessionID) says the " +
            "customer owns the product. Clearing the cached CustomerInfo, so the next read fetches it."
        }
    }

    var category: String { return "hosted_checkout" }

}
