//
//  AttributionStrings.swift
//  PurchasesCoreSwift
//
//  Created by Andrés Boedo on 9/14/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

// swiftlint:disable identifier_name
@objc(RCAttributionStrings) public class AttributionStrings: NSObject {
    @objc public var appsflyer_id_deprecated: String {
        "The parameter key rc_appsflyer_id is deprecated. Pass networkUserId to addAttribution instead."
    }
    @objc public var attributes_sync_error: String {
        "Error when syncing subscriber attributes. Details: %@\n UserInfo:%@"
    }
    @objc public var attributes_sync_success: String { "Subscriber attributes synced successfully for App User ID: %@" }
    @objc public var empty_subscriber_attributes: String {
        "Called post subscriber attributes with an empty attributes dictionary!"
    }
    @objc public var marking_attributes_synced: String {
        "Marking the following attributes as synced for App User ID: %@: %@"
    }
    @objc public var method_called: String { "%s called" }
    @objc public var networkuserid_required_for_appsflyer: String {
        "The parameter networkUserId is REQUIRED for AppsFlyer."
    }
    @objc public var no_instance_configured_caching_attribution: String {
        "There is no purchase instance configured, caching attribution"
    }
    @objc public var instance_configured_posting_attribution: String {
        "There is a purchase instance configured, posting attribution"
    }
    @objc public var search_ads_attribution_cancelled_missing_att_framework: String {
        "Tried to post Apple Search Ads Attribution, but ATT Framework is required on this OS" +
            " and it isn't included"
    }
    @objc public var att_framework_present_but_couldnt_call_tracking_authorization_status: String {
        "ATT Framework was found but it didn't respond to authorization status selector!"
    }
    @objc public var search_ads_attribution_cancelled_missing_ad_framework: String {
        "Tried to post Apple Search Ads Attribution, but Apple Ads Framework is is required for it" +
            " and it isn't included"
    }
    @objc public var search_ads_attribution_cancelled_not_authorized: String {
        "Tried to post Apple Search Ads Attribution, but authorization hasn't been granted. " +
            "Will automatically retry if authorization gets granted."
    }
    @objc public var skip_same_attributes: String { "Attribution data is the same as latest. Skipping." }
    @objc public var subscriber_attributes_error: String { "Subscriber attributes errors: %@" }
    @objc public var unsynced_attributes_count: String { "Found %lu unsynced attributes for App User ID: %@" }
    @objc public var unsynced_attributes: String { "Unsynced attributes: %@" }
}
