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

    case data_object_identifier_not_found_receipt
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
    case posting_receipt(AppleReceipt, initiationSource: String)
    case posting_jws(String, initiationSource: String)
    case posting_sk2_receipt(String, initiationSource: String)
    case receipt_subscription_purchase_equals_expiration(
        productIdentifier: String,
        purchase: Date,
        expiration: Date?
    )
    case local_receipt_missing_purchase(AppleReceipt, forProductIdentifier: String)
    case retrying_receipt_fetch_after(sleepDuration: TimeInterval)
    case error_validating_bundle_signature

}

extension ReceiptStrings: LogMessage {

    var description: String {
        switch self {

        case .data_object_identifier_not_found_receipt:
            return "The data object identifier couldn't be found on the receipt."

        case .force_refreshing_receipt:
            return "Force refreshing the receipt to get latest transactions from Apple."

        case .throttling_force_refreshing_receipt:
            return "Throttled request to refresh receipt."

        case .loaded_receipt(let url):
            return "Loaded receipt from url \(url.absoluteString)"

        case .no_sandbox_receipt_intro_eligibility:
            return "App running on sandbox without a receipt file. " +
            "Unable to determine intro eligibility unless you've purchased " +
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

        case let .posting_receipt(receipt, initiationSource):
            return "Posting receipt (source: '\(initiationSource)') (note: the contents might not be up-to-date, " +
            "but it will be refreshed with Apple's servers):\n\(receipt.debugDescription)"

        case let .posting_jws(token, initiationSource):
            return "Posting JWS token (source: '\(initiationSource)'):\n\(token)"

        case let .posting_sk2_receipt(receipt, initiationSource):
            return "Posting StoreKit 2 receipt (source: '\(initiationSource)'):\n\(receipt)"

        case let .receipt_subscription_purchase_equals_expiration(
            productIdentifier,
            purchase,
            expiration
        ):
            return "Receipt for product '\(productIdentifier)' has the same purchase (\(purchase)) " +
            "and expiration (\(expiration?.description ?? "")) dates. This is likely a StoreKit bug."

        case let .local_receipt_missing_purchase(receipt, productIdentifier):
            return "Local receipt is still missing purchase for '\(productIdentifier)': \n" +
            "\((try? receipt.prettyPrintedJSON) ?? "<null>")"

        case let .retrying_receipt_fetch_after(sleepDuration):
            return String(format: "Retrying receipt fetch after %2.f seconds", sleepDuration)

        case .error_validating_bundle_signature:
            return "Error validating app bundle signature."
        }
    }

    var category: String { return "receipt" }

}
