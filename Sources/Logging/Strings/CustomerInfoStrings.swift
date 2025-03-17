//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoStrings.swift
//
//  Created by Tina Nguyen on 12/11/20.
//

import Foundation

// swiftlint:disable identifier_name
enum CustomerInfoStrings {

    case checking_intro_eligibility_locally_error(error: Error)
    case checking_intro_eligibility_locally_result(productIdentifiers: [String: IntroEligibilityStatus])
    case checking_intro_eligibility_locally
    case checking_intro_eligibility_locally_from_receipt(AppleReceipt)
    case invalidating_customerinfo_cache
    case no_cached_customerinfo
    case cached_customerinfo_incompatible_schema
    case not_caching_offline_customer_info
    case customerinfo_stale_updating_in_background
    case customerinfo_stale_updating_in_foreground
    case customerinfo_updated_from_network
    case customerinfo_updated_from_network_error(BackendError)
    case customerinfo_updated_offline
    case posting_transactions_in_lieu_of_fetching_customerinfo([StoreTransaction])
    case updating_request_date(CustomerInfo, Date)
    case sending_latest_customerinfo_to_delegate
    case sending_updated_customerinfo_to_delegate
    case vending_cache
    case error_encoding_customerinfo(Error)

}

extension CustomerInfoStrings: LogMessage {

    var description: String {
        switch self {
        case .checking_intro_eligibility_locally_error(let error):
            return "Couldn't check intro eligibility locally, error: \(error.localizedDescription)"
        case .checking_intro_eligibility_locally_result(let productIdentifiers):
            return "Local intro eligibility computed locally. Result: \(productIdentifiers)"
        case .checking_intro_eligibility_locally:
            return "Attempting to check intro eligibility locally"
        case let .checking_intro_eligibility_locally_from_receipt(receipt):
            return "Checking intro eligibility locally from receipt: \((try? receipt.prettyPrintedJSON) ?? "")"
        case .invalidating_customerinfo_cache:
            return "Invalidating CustomerInfo cache."
        case .no_cached_customerinfo:
            return "No cached CustomerInfo, fetching from network."
        case .cached_customerinfo_incompatible_schema:
            return "Cached CustomerInfo has incompatible schema."
        case .not_caching_offline_customer_info:
            return "CustomerInfo was computed offline. Won't be stored in cache."
        case .customerinfo_stale_updating_in_background:
            return "CustomerInfo cache is stale, updating from network in background."
        case .customerinfo_stale_updating_in_foreground:
            return "CustomerInfo cache is stale, updating from network in foreground."
        case .customerinfo_updated_from_network:
            return "CustomerInfo updated from network."
        case let .customerinfo_updated_from_network_error(error):
            var result = "Attempt to update CustomerInfo from network failed.\n\(error.localizedDescription)"

            if let underlyingError = error.underlyingError {
                result += "\nUnderlying error: \(underlyingError.localizedDescription)"
            }

            return result
        case .customerinfo_updated_offline:
            return "There was an error communicating with RevenueCat servers. " +
            "CustomerInfo was temporarily computed offline, and it will be posted again as soon as possible."
        case let .posting_transactions_in_lieu_of_fetching_customerinfo(transactions):
            return "Found \(transactions.count) unfinished transactions, will post receipt in lieu " +
            "of fetching CustomerInfo:\n\(transactions)"
        case let .updating_request_date(info, newRequestDate):
            return "Updating CustomerInfo '\(info.originalAppUserId)' request date: \(newRequestDate)"
        case .sending_latest_customerinfo_to_delegate:
            return "Sending latest CustomerInfo to delegate."
        case .sending_updated_customerinfo_to_delegate:
            return "Sending updated CustomerInfo to delegate."
        case .vending_cache:
            return "Vending CustomerInfo from cache."
        case let .error_encoding_customerinfo(error):
            return "Couldn't encode CustomerInfo:\n\(error)"
        }

    }

    var category: String { return "customer" }

}
