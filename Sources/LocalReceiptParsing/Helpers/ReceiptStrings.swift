//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptStrings.swift
//
//  Created by Nacho Soto on 11/29/22.

import Foundation

// swiftlint:disable identifier_name
enum ReceiptStrings {

    case data_object_identifer_not_found_receipt
    case force_refreshing_receipt
    case throttling_force_refreshing_receipt
    case loaded_receipt(url: URL)
    case no_sandbox_receipt_intro_eligibility
    case no_sandbox_receipt_restore
    case parse_receipt_locally_error(error: Error)
    case parsing_receipt_failed(fileName: String, functionName: String)
    case parsing_receipt_success
    case parsing_receipt
    case refreshing_empty_receipt
    case unable_to_load_receipt(Error)
    case posting_receipt(AppleReceipt)
    case receipt_subscription_purchase_equals_expiration(
        productIdentifier: String,
        purchase: Date,
        expiration: Date?
    )
    case receipt_retrying_mechanism_not_available
    case local_receipt_missing_purchase(AppleReceipt, forProductIdentifier: String)
    case retrying_receipt_fetch_after(sleepDuration: TimeInterval)

}

extension ReceiptStrings: CustomStringConvertible {

    var description: String {
        switch self {

        case .data_object_identifer_not_found_receipt:
            return "The data object identifier couldn't be found on the receipt."

        case .force_refreshing_receipt:
            return "Force refreshing the receipt to get latest transactions from Apple."

        case .throttling_force_refreshing_receipt:
            return "Throttled request to refresh receipt."

        case .loaded_receipt(let url):
            return "Loaded receipt from url \(url.absoluteString)"

        case .no_sandbox_receipt_intro_eligibility:
            return "App running on sandbox without a receipt file. " +
            "Unable to determine into eligibility unless you've purchased " +
            "before and there is a receipt available."

        case .no_sandbox_receipt_restore:
            return "App running in sandbox without a receipt file. Restoring " +
            "transactions won't work until a purchase is made to generate a receipt. " +
            "This should not happen in production unless user is logged out of Apple account."

        case .parse_receipt_locally_error(let error):
            return "There was an error when trying to parse the receipt " +
           "locally, details: \(error.localizedDescription)"

        case .parsing_receipt_failed(let fileName, let functionName):
            return "\(fileName)-\(functionName): Could not parse receipt, conservatively returning true"

        case .parsing_receipt_success:
            return "Receipt parsed successfully"

        case .parsing_receipt:
            return "Parsing receipt"

        case .refreshing_empty_receipt:
            return "Receipt empty, refreshing"

        case let .unable_to_load_receipt(error):
            return "Unable to load receipt, ensure you are logged in to a valid Apple account.\n" +
            "Error: \(error)"

        case let .posting_receipt(receipt):
            return "Posting receipt (note: the contents might not be up-to-date, " +
            "but it will be refreshed with Apple's servers):\n\(receipt.debugDescription)"

        case let .receipt_subscription_purchase_equals_expiration(
            productIdentifier,
            purchase,
            expiration
        ):
            return "Receipt for product '\(productIdentifier)' has the same purchase (\(purchase)) " +
            "and expiration (\(expiration?.description ?? "")) dates. This is likely a StoreKit bug."

        case .receipt_retrying_mechanism_not_available:
            return "Receipt retrying mechanism is not available in iOS 12. Will only attempt to fetch once."

        case let .local_receipt_missing_purchase(receipt, productIdentifier):
            return "Local receipt is still missing purchase for '\(productIdentifier)': \n" +
            "\((try? receipt.prettyPrintedJSON) ?? "<null>")"

        case let .retrying_receipt_fetch_after(sleepDuration):
            return String(format: "Retrying receipt fetch after %2.f seconds", sleepDuration)

        }
    }

}
