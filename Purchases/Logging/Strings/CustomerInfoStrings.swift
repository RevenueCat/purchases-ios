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
    case invalidating_customerinfo_cache
    case no_cached_customerinfo
    case customerinfo_stale_updating_in_background
    case customerinfo_stale_updating_in_foreground
    case customerinfo_updated_from_network
    case customerinfo_updated_from_network_error(error: Error)
    case sending_latest_customerinfo_to_delegate
    case sending_updated_customerinfo_to_delegate
    case vending_cache
    case error_getting_data_from_customerinfo_json(error: Error)
    case invalid_json

    case missing_json_object_instantiation_error(jsonData: [String: Any]?)
    case cant_instantiate_from_json_object(jsonObject: [String: Any]?)
    case cant_parse_request_date_from_json(date: Any?)
    case cant_parse_request_date_from_string(string: String)

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
        case .customerinfo_updated_from_network_error(let error):
            return "Attempt to update CustomerInfo from network failed.\n\(error.localizedDescription)"
        case .sending_latest_customerinfo_to_delegate:
            return "Sending latest CustomerInfo to delegate."
        case .sending_updated_customerinfo_to_delegate:
            return "Sending updated CustomerInfo to delegate."
        case .vending_cache:
            return "Vending CustomerInfo from cache."
        case .error_getting_data_from_customerinfo_json(let error):
            return "Couldn't get data from customerInfo.jsonObject\n\(error.localizedDescription)"
        case .invalid_json:
            return "Invalid JSON returned from customerInfo.jsonObject"
        case .missing_json_object_instantiation_error(let jsonData):
            var message = "Unable to find subscriber object in data"
            if let jsonData = jsonData {
                message += ":\n\(jsonData.debugDescription)"
            }
            return message
        case .cant_instantiate_from_json_object(let jsonObject):
            var message = "Unable to instantiate SubscriberData from json object"
            if let jsonObject = jsonObject {
                message += ":\n\(jsonObject.debugDescription)"
            }
            return message
        case .cant_parse_request_date_from_json(let date):
            return "Unable to parse 'request_date' from CustomerInfo json: \(String(describing: date))"
        case .cant_parse_request_date_from_string(let string):
            return "Unable to parse 'request_date' from CustomerInfo date string: \(string)"
        }

    }

}
