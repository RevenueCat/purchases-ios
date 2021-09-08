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
enum AttributionStrings {

    case appsflyer_id_deprecated
    case attributes_sync_error(error: NSError?)
    case attributes_sync_success(appUserID: String)
    case empty_subscriber_attributes
    case marking_attributes_synced(appUserID: String, attributes: SubscriberAttributeDict)
    case method_called(methodName: String)
    case networkuserid_required_for_appsflyer
    case no_instance_configured_caching_attribution
    case instance_configured_posting_attribution
    case search_ads_attribution_cancelled_missing_att_framework
    case att_framework_present_but_couldnt_call_tracking_authorization_status
    case iad_framework_present_but_couldnt_call_request_attribution_details
    case search_ads_attribution_cancelled_missing_iad_framework
    case search_ads_attribution_cancelled_not_authorized
    case skip_same_attributes
    case subscriber_attributes_error(errors: [String: String]?)
    case unsynced_attributes_count(unsyncedAttributesCount: Int, appUserID: String)
    case unsynced_attributes(unsyncedAttributes: SubscriberAttributeDict)
    case attribute_set_locally(attribute: String)
    case missing_advertiser_identifiers

}

extension AttributionStrings: CustomStringConvertible {

    var description: String {
        switch self {
        case .appsflyer_id_deprecated:
            return "The parameter key rc_appsflyer_id is deprecated." +
            " Pass networkUserId to addAttribution instead."

        case .attributes_sync_error(let error):
            return "Error when syncing subscriber attributes. Details: \(error?.localizedDescription ?? "")" +
            " \nUserInfo: \(error?.userInfo ?? [:])"

        case .attributes_sync_success(let appUserID):
            return "Subscriber attributes synced successfully for App User ID: \(appUserID)"

        case .empty_subscriber_attributes:
            return "Called post subscriber attributes with an empty attributes dictionary!"

        case .marking_attributes_synced(let appUserID, let attributes):
            return "Marking attributes as synced for App User ID: \(appUserID):\n attributes: \(attributes.description)"

        case .method_called(let methodName):
            return "\(methodName) called"

        case .networkuserid_required_for_appsflyer:
            return "The parameter networkUserId is REQUIRED for AppsFlyer."

        case .no_instance_configured_caching_attribution:
            return "There is no purchase instance configured, caching attribution"

        case .instance_configured_posting_attribution:
            return "There is a purchase instance configured, posting attribution"

        case .search_ads_attribution_cancelled_missing_att_framework:
            return "Tried to post Apple Search Ads Attribution, " +
            "but ATT Framework is required on this OS and it isn't included"

        case .att_framework_present_but_couldnt_call_tracking_authorization_status:
            return "ATT Framework was found but it didn't respond to authorization status selector!"

        case .iad_framework_present_but_couldnt_call_request_attribution_details:
            return "iAd Framework was found but it didn't respond to attribution details request!"

        case .search_ads_attribution_cancelled_missing_iad_framework:
            return "Tried to post Apple Search Ads Attribution, " +
            "but iAd Framework is is required for it and it isn't included"

        case .search_ads_attribution_cancelled_not_authorized:
            return "Tried to post Apple Search Ads Attribution, but " +
            "authorization hasn't been granted. Will automatically retry if authorization gets granted."

        case .skip_same_attributes:
            return "Attribution data is the same as latest. Skipping."

        case .subscriber_attributes_error(let errors):
            return "Subscriber attributes errors: \((errors?.description ?? ""))"

        case .unsynced_attributes_count(let unsyncedAttributesCount, let appUserID):
            return "Found \(unsyncedAttributesCount) unsynced attributes for App User ID: \(appUserID)"

        case .unsynced_attributes(let unsyncedAttributes):
            return "Unsynced attributes: \(unsyncedAttributes)"

        case .attribute_set_locally(let attribute):
            return "Attribute set locally: \(attribute). It will be synced to the backend" +
            "when the app backgrounds/foregrounds or when a purchase is made."

        case .missing_advertiser_identifiers:
            return "Attribution error: identifierForAdvertisers is missing"

        }
    }

}
