//
//  PurchaserInfoStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCPurchaserInfoStrings) public class PurchaserInfoStrings: NSObject {
    @objc public var checking_intro_eligibility_locally_error: String { "Couldn't check intro eligibility locally, error: %@" } //error, og checking_intro_eligibility_error - 
    @objc public var checking_intro_eligibility_locally_result: String { "Local intro eligibility computed locally. Result: %@" } //debug, og checking_intro_eligibility_result -
    @objc public var checking_intro_eligibility_locally: String { "Attempting to check intro eligibility locally" } //debug, og checking_intro_eligibility -
    @objc public var invalidating_purchaserinfo_cache: String { "Invalidating PurchaserInfo cache." } //debug - 
    @objc public var no_cached_purchaserinfo: String { "No cached PurchaserInfo, fetching from network." } //debug -
    @objc public var purchaserinfo_stale_updating_background: String { "PurchaserInfo cache is stale, updating from network in background." } //debug -
    @objc public var purchaserinfo_stale_updating_foreground: String { "PurchaserInfo cache is stale, updating from network in foreground." } //debug - 
    @objc public var purchaserinfo_updated_from_network: String { "PurchaserInfo updated from network." } //rcSuccess
    @objc public var sending_latest_purchaserinfo_to_delegate: String { "Sending latest PurchaserInfo to delegate." } //debug -
    @objc public var sending_updated_purchaserinfo_to_delegate: String { "Sending updated PurchaserInfo to delegate." } //debug -
    @objc public var vending_cache: String { "Vending PurchaserInfo from cache." } //debug - 
}
