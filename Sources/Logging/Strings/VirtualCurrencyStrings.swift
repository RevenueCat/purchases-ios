//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyStrings.swift
//
//  Created by Will Taylor on 6/18/25.

import Foundation

// swiftlint:disable identifier_name
enum VirtualCurrencyStrings {

    case invalidating_virtual_currencies_cache
    case vending_from_cache
    case no_cached_virtual_currencies
    case virtual_currencies_stale_updating_from_network
    case virtual_currencies_updated_from_network
    case virtual_currencies_updated_from_network_error(Error)
    case empty_spend_amount
    case invalid_code
    case invalid_spend_amount(String, Int)
    case too_many_codes
    case virtual_currencies_spent_on_network
    case virtual_currencies_spent_on_network_error(Error)
    case error_decoding_cached_virtual_currencies(Error)

}

extension VirtualCurrencyStrings: LogMessage {
    var description: String {
        switch self {
        case .invalidating_virtual_currencies_cache:
            return "Invalidating VirtualCurrencies cache."
        case .no_cached_virtual_currencies:
            return "There are no cached VirtualCurrencies."
        case .virtual_currencies_stale_updating_from_network:
            return "VirtualCurrencies cache is stale, updating from network."
        case .vending_from_cache:
            return "Vending VirtualCurrencies from cache."
        case .virtual_currencies_updated_from_network:
            return "VirtualCurrencies updated from the network."
        case let .virtual_currencies_updated_from_network_error(error):
            return "Attempt to update VirtualCurrencies from network failed.\n\(error.localizedDescription)"
        case .empty_spend_amount:
            return "No amount specified to spend. This will be ignored."
        case .invalid_code:
            return "Invalid code"
        case let .invalid_spend_amount(code, amount):
            return "Attempt to spend zero/negative currency amount \(amount) for \(code). " +
            "This is not allowed and will be ignored."
        case .too_many_codes:
            return "You may not specify this many codes in a single spend transaction"
        case .virtual_currencies_spent_on_network:
            return "VirtualCurrencies spent on the network."
        case let .virtual_currencies_spent_on_network_error(error):
            return "Attempt to spend VirtualCurrencies on network failed.\n\(error.localizedDescription)"
        case let .error_decoding_cached_virtual_currencies(error):
            return "Couldn't decode cached VirtualCurrencies:\n\(error)"
        }
    }

    var category: String { return "virtual_currency" }
}
