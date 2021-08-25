//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaserInfoStrings.swift
//
//  Created by Tina Nguyen on 12/11/20.
//

import Foundation

// swiftlint:disable identifier_name
enum PurchaserInfoStrings {

    static let checking_intro_eligibility_locally_error = "Couldn't check intro eligibility locally, error: %@"
    static let checking_intro_eligibility_locally_result = "Local intro eligibility computed locally. Result: %@"
    static let checking_intro_eligibility_locally = "Attempting to check intro eligibility locally"
    static let invalidating_purchaserinfo_cache = "Invalidating PurchaserInfo cache."
    static let no_cached_purchaserinfo = "No cached PurchaserInfo, fetching from network."
    static let purchaserinfo_stale_updating_in_background = "PurchaserInfo cache is stale, updating from network in background."
    static let purchaserinfo_stale_updating_in_foreground = "PurchaserInfo cache is stale, updating from network in foreground."
    static let purchaserinfo_updated_from_network = "PurchaserInfo updated from network."
    static let purchaserinfo_updated_from_network_error = "Attempt to update PurchaserInfo from network failed."
    static let sending_latest_purchaserinfo_to_delegate = "Sending latest PurchaserInfo to delegate."
    static let sending_updated_purchaserinfo_to_delegate = "Sending updated PurchaserInfo to delegate."
    static let vending_cache = "Vending PurchaserInfo from cache."

}
