//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AttributionStrings.swift
//
//  Created by Andrés Boedo on 9/14/20.
//

import Foundation

// swiftlint:disable identifier_name
class AttributionStrings {

    var appsflyer_id_deprecated: String {
        "The parameter key rc_appsflyer_id is deprecated. Pass networkUserId to addAttribution instead."
    }
    var attributes_sync_error: String {
        "Error when syncing subscriber attributes. Details: %@\n UserInfo:%@"
    }
    var attributes_sync_success: String { "Subscriber attributes synced successfully for App User ID: %@" }
    var empty_subscriber_attributes: String {
        "Called post subscriber attributes with an empty attributes dictionary!"
    }
    var marking_attributes_synced: String {
        "Marking the following attributes as synced for App User ID: %@: %@"
    }
    var method_called: String { "%@ called" }
    var networkuserid_required_for_appsflyer: String {
        "The parameter networkUserId is REQUIRED for AppsFlyer."
    }
    var no_instance_configured_caching_attribution: String {
        "There is no purchase instance configured, caching attribution"
    }
    var instance_configured_posting_attribution: String {
        "There is a purchase instance configured, posting attribution"
    }
    var search_ads_attribution_cancelled_missing_att_framework: String {
        "Tried to post Apple Search Ads Attribution, but ATT Framework is required on this OS" +
            " and it isn't included"
    }
    var att_framework_present_but_couldnt_call_tracking_authorization_status: String {
        "ATT Framework was found but it didn't respond to authorization status selector!"
    }
    var iad_framework_present_but_couldnt_call_request_attribution_details: String {
        "iAd Framework was found but it didn't respond to attribution details request!"
    }
    var search_ads_attribution_cancelled_missing_iad_framework: String {
        "Tried to post Apple Search Ads Attribution, but iAd Framework is is required for it" +
            " and it isn't included"
    }
    var search_ads_attribution_cancelled_not_authorized: String {
        "Tried to post Apple Search Ads Attribution, but authorization hasn't been granted. " +
            "Will automatically retry if authorization gets granted."
    }
    var skip_same_attributes: String { "Attribution data is the same as latest. Skipping." }
    var subscriber_attributes_error: String { "Subscriber attributes errors: %@" }
    var unsynced_attributes_count: String { "Found %lu unsynced attributes for App User ID: %@" }
    var unsynced_attributes: String { "Unsynced attributes: %@" }
    var attribute_set_locally: String { "Attribute set locally: %@. It will be synced to the backend" +
        "when the app backgrounds/foregrounds or when a purchase is made." }
    var missing_advertiser_identifiers: String { "Attribution error: identifierForAdvertisers is missing" }
    var missing_app_user_id: String { "Attribution error: can't post attribution, missing appUserId" }

}
