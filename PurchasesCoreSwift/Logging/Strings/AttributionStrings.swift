//
//  AttributionStrings.swift
//  PurchasesCoreSwift
//
//  Created by Andrés Boedo on 9/14/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCAttributionStrings) public class AttributionStrings: NSObject {
    @objc public var appsflyer_id_deprecated: String { "The parameter key rc_appsflyer_id is deprecated. Pass networkUserId to addAttribution instead." } //warn
    @objc public var attributes_sync_error: String { "Error when syncing subscriber attributes. Details: %@\n UserInfo:%@" } //error
    @objc public var attributes_sync_success: String { "Subscriber attributes synced successfully for App User ID: %@" } // rcSuccess
    @objc public var empty_subscriber_attributes: String { "Called post subscriber attributes with an empty attributes dictionary!" } //warn
    @objc public var marking_attributes_sync: String { "Marking the following attributes as synced for App User ID: %@: %@" } // info
    @objc public var method_called: String { "%s called" } // debug
    @objc public var networkuserid_required: String { "The parameter networkUserId is REQUIRED for AppsFlyer." } //warn
    @objc public var no_instance_configured_caching_attribution: String { "There is no purchase instance configured, caching attribution" } //debug
    @objc public var purchase_instance_configured_posting_attribution: String { "There is a purchase instance configured, posting attribution"} //debug
    @objc public var skip_same_attributes: String { "Attribution data is the same as latest. Skipping." } //debug
    @objc public var subscriber_attributes_error: String { "Subscriber attributes errors: %@" } //error
    @objc public var unsynced_attributes_count: String { "Found %lu unsynced attributes for App User ID: %@" } //debug
    @objc public var unsynced_attributes: String { "Unsynced attributes: %@" } //debug
}
