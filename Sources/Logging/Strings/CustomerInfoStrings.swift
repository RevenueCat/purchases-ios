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
    case customerinfo_stale_updating_in_background
    case customerinfo_stale_updating_in_foreground
    case customerinfo_updated_from_network
    case customerinfo_updated_from_network_error(BackendError)
    case sending_latest_customerinfo_to_delegate
    case sending_updated_customerinfo_to_delegate
    case vending_cache
    case error_encoding_customerinfo(Error)

}

extension CustomerInfoStrings: CustomStringConvertible {

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

}
