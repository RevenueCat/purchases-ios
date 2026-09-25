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
    case unrecognized_status(_ status: String)
    case unrecognized_payment_status(_ paymentStatus: String)
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
    case dismissed_without_paying(_ operationSessionID: String)
    case payment_status_unknown(_ operationSessionID: String)
    case payment_status_undetermined(_ operationSessionID: String)

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
        case let .unrecognized_status(status):
            return "Unrecognized checkout session status '\(status)'. Treating the session as still under way."
        case let .unrecognized_payment_status(paymentStatus):
            return "Unrecognized checkout payment status '\(paymentStatus)'. Treating the payment as undetermined."
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
        case let .dismissed_without_paying(operationSessionID):
            return "Checkout session \(operationSessionID) was dismissed without a payment."
        case let .payment_status_unknown(operationSessionID):
            return "The backend could not say whether checkout session \(operationSessionID) was paid for."
        case let .payment_status_undetermined(operationSessionID):
            return "Could not learn whether the dismissed checkout session \(operationSessionID) was paid for."
        }
    }

    var category: String { return "hosted_checkout" }

}
