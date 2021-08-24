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
extension Strings {

    enum AttributionStrings {

        static let appsflyer_id_deprecated = "The parameter key rc_appsflyer_id is deprecated. Pass networkUserId to addAttribution instead."

        static let attributes_sync_error = "Error when syncing subscriber attributes. Details: %@\n UserInfo:%@"

        static let attributes_sync_success = "Subscriber attributes synced successfully for App User ID: %@"
        static let empty_subscriber_attributes = "Called post subscriber attributes with an empty attributes dictionary!"

        static let marking_attributes_synced = "Marking the following attributes as synced for App User ID: %@: %@"

        static let method_called = "%@ called"
        static let networkuserid_required_for_appsflyer = "The parameter networkUserId is REQUIRED for AppsFlyer."

        static let no_instance_configured_caching_attribution = "There is no purchase instance configured, caching attribution"

        static let instance_configured_posting_attribution = "There is a purchase instance configured, posting attribution"

        static let search_ads_attribution_cancelled_missing_att_framework = "Tried to post Apple Search Ads Attribution, but ATT Framework is required on this OS" +
                " and it isn't included"

        static let att_framework_present_but_couldnt_call_tracking_authorization_status = "ATT Framework was found but it didn't respond to authorization status selector!"

        static let iad_framework_present_but_couldnt_call_request_attribution_details = "iAd Framework was found but it didn't respond to attribution details request!"

        static let search_ads_attribution_cancelled_missing_iad_framework = "Tried to post Apple Search Ads Attribution, but iAd Framework is is required for it" +
                " and it isn't included"

        static let search_ads_attribution_cancelled_not_authorized = "Tried to post Apple Search Ads Attribution, but authorization hasn't been granted. " +
                "Will automatically retry if authorization gets granted."

        static let skip_same_attributes = "Attribution data is the same as latest. Skipping."
        static let subscriber_attributes_error = "Subscriber attributes errors: %@"
        static let unsynced_attributes_count = "Found %lu unsynced attributes for App User ID: %@"
        static let unsynced_attributes = "Unsynced attributes: %@"
        static let attribute_set_locally = "Attribute set locally: %@. It will be synced to the backend" +
            "when the app backgrounds/foregrounds or when a purchase is made."
        static let missing_advertiser_identifiers = "Attribution error: identifierForAdvertisers is missing"
        static let missing_app_user_id = "Attribution error: can't post attribution, missing appUserId"

    }

}
