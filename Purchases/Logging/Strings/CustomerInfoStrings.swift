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
    case invalidating_purchaserinfo_cache
    case no_cached_purchaserinfo
    case purchaserinfo_stale_updating_in_background
    case purchaserinfo_stale_updating_in_foreground
    case purchaserinfo_updated_from_network
    case purchaserinfo_updated_from_network_error(error: Error)
    case sending_latest_purchaserinfo_to_delegate
    case sending_updated_purchaserinfo_to_delegate
    case vending_cache
    case error_getting_data_from_purchaserinfo_json(error: Error)
    case invalid_json

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

        case .invalidating_purchaserinfo_cache:
            return "Invalidating CustomerInfo cache."

        case .no_cached_purchaserinfo:
            return "No cached CustomerInfo, fetching from network."

        case .purchaserinfo_stale_updating_in_background:
            return "CustomerInfo cache is stale, " +
                "updating from network in background."

        case .purchaserinfo_stale_updating_in_foreground:
            return "CustomerInfo cache is stale, " +
                "updating from network in foreground."

        case .purchaserinfo_updated_from_network:
            return "CustomerInfo updated from network."

        case .purchaserinfo_updated_from_network_error(let error):
            return "Attempt to update CustomerInfo from network failed.\n\(error.localizedDescription)"

        case .sending_latest_purchaserinfo_to_delegate:
            return "Sending latest CustomerInfo to delegate."

        case .sending_updated_purchaserinfo_to_delegate:
            return "Sending updated CustomerInfo to delegate."

        case .vending_cache:
            return "Vending CustomerInfo from cache."

        case .error_getting_data_from_purchaserinfo_json(let error):
            return "Couldn't get data from purchaserInfo.jsonObject\n\(error.localizedDescription)"

        case .invalid_json:
            return "Invalid JSON returned from purchaserInfo.jsonObject"

        }

    }

}
