//
//  PurchaserInfoStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

// swiftlint:disable identifier_name
@objc(RCPurchaserInfoStrings) public class PurchaserInfoStrings: NSObject {
    @objc public var checking_intro_eligibility_locally_error: String {
        "Couldn't check intro eligibility locally, error: %@"
    }
    @objc public var checking_intro_eligibility_locally_result: String {
        "Local intro eligibility computed locally. Result: %@"
    }
    @objc public var checking_intro_eligibility_locally: String { "Attempting to check intro eligibility locally" }
    @objc public var invalidating_purchaserinfo_cache: String { "Invalidating PurchaserInfo cache." }
    @objc public var no_cached_purchaserinfo: String { "No cached PurchaserInfo, fetching from network." }
    @objc public var purchaserinfo_stale_updating_in_background: String {
        "PurchaserInfo cache is stale, updating from network in background."
    }
    @objc public var purchaserinfo_stale_updating_in_foreground: String {
        "PurchaserInfo cache is stale, updating from network in foreground."
    }
    @objc public var purchaserinfo_updated_from_network: String { "PurchaserInfo updated from network." }
    @objc public var sending_latest_purchaserinfo_to_delegate: String { "Sending latest PurchaserInfo to delegate." }
    @objc public var sending_updated_purchaserinfo_to_delegate: String { "Sending updated PurchaserInfo to delegate." }
    @objc public var vending_cache: String { "Vending PurchaserInfo from cache." }
}
