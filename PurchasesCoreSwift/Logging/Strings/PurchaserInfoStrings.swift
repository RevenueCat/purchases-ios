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
class PurchaserInfoStrings {

    var checking_intro_eligibility_locally_error: String { "Couldn't check intro eligibility locally, error: %@" }
    var checking_intro_eligibility_locally_result: String { "Local intro eligibility computed locally. Result: %@" }
    var checking_intro_eligibility_locally: String { "Attempting to check intro eligibility locally" }
    var invalidating_purchaserinfo_cache: String { "Invalidating PurchaserInfo cache." }
    var no_cached_purchaserinfo: String { "No cached PurchaserInfo, fetching from network." }
    var purchaserinfo_stale_updating_in_background: String {
        "PurchaserInfo cache is stale, updating from network in background."
    }
    var purchaserinfo_stale_updating_in_foreground: String {
        "PurchaserInfo cache is stale, updating from network in foreground."
    }
    var purchaserinfo_updated_from_network: String { "PurchaserInfo updated from network." }
    var purchaserinfo_updated_from_network_error: String { "Attempt to update PurchaserInfo from network failed." }
    var sending_latest_purchaserinfo_to_delegate: String { "Sending latest PurchaserInfo to delegate." }
    var sending_updated_purchaserinfo_to_delegate: String { "Sending updated PurchaserInfo to delegate." }
    var vending_cache: String { "Vending PurchaserInfo from cache." }

}
