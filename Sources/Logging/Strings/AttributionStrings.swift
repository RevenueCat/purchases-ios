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
    case marking_attributes_synced(appUserID: String, attributes: SubscriberAttribute.Dictionary)
    case setting_reserved_attribute(_ reservedAttribute: ReservedSubscriberAttribute)
    case setting_attributes(attributes: [String])
    case networkuserid_required_for_appsflyer
    case no_instance_configured_caching_attribution
    case instance_configured_posting_attribution
    case search_ads_attribution_cancelled_missing_att_framework
    case att_framework_present_but_couldnt_call_tracking_authorization_status
    case search_ads_attribution_cancelled_missing_ad_framework
    case search_ads_attribution_cancelled_not_authorized
    case skip_same_attributes
    case subscriber_attributes_error(errors: [String: String])
    case unsynced_attributes_count(unsyncedAttributesCount: Int, appUserID: String)
    case unsynced_attributes(unsyncedAttributes: SubscriberAttribute.Dictionary)
    case attribute_set_locally(attribute: String)
    case missing_advertiser_identifiers
    case adservices_not_supported
    case adservices_mocking_token(String)
    case adservices_token_fetch_failed(error: Error)
    case adservices_token_post_failed(error: BackendError)
    case adservices_token_post_succeeded
    case adservices_marking_as_synced(appUserID: String)
    case adservices_token_unavailable_in_simulator
    case latest_attribution_sent_user_defaults_invalid(networkKey: String)
    case copying_attributes(oldAppUserID: String, newAppUserID: String)

}

extension AttributionStrings: LogMessage {

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

        case .setting_reserved_attribute(let reservedAttribute):
            return "setting reserved attribute: \(reservedAttribute.key)"

        case .setting_attributes(let attributes):
            return "setting values for attributes: \(attributes)"

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

        case .search_ads_attribution_cancelled_missing_ad_framework:
            return "Tried to post Apple Search Ads Attribution, " +
            "but Apple Ad Framework is is required for it and it isn't included"

        case .search_ads_attribution_cancelled_not_authorized:
            return "Tried to post Apple Search Ads Attribution, but " +
            "authorization hasn't been granted. Will automatically retry if authorization gets granted."

        case .skip_same_attributes:
            return "Attribution data is the same as latest. Skipping."

        case let .subscriber_attributes_error(errors):
            return "Subscriber attributes errors: \(errors.description))"

        case .unsynced_attributes_count(let unsyncedAttributesCount, let appUserID):
            return "Found \(unsyncedAttributesCount) unsynced attributes for App User ID: \(appUserID)"

        case .unsynced_attributes(let unsyncedAttributes):
            return "Unsynced attributes: \(unsyncedAttributes)"

        case .attribute_set_locally(let attribute):
            return "Attribute set locally: \(attribute). It will be synced to the backend" +
            " when the app backgrounds/foregrounds or when a purchase is made."

        case .missing_advertiser_identifiers:
            return "Attribution error: identifierForAdvertisers is missing"

        case .adservices_not_supported:
            return "Tried to fetch AdServices attribution token on device without " +
                "AdServices support."

        case let .adservices_mocking_token(token):
            return "AdServices: mocking token: \(token) for tests"

        case .adservices_token_fetch_failed(let error):
            return "Fetching AdServices attribution token failed with error: \(error.localizedDescription)"

        case .adservices_token_post_failed(let error):
            return "Posting AdServices attribution token failed with error: \(error.localizedDescription)"

        case .adservices_token_post_succeeded:
            return "AdServices attribution token successfully posted"

        case let .adservices_marking_as_synced(userID):
            return "Marking AdServices attribution token as synced for App User ID: \(userID)"

        case .adservices_token_unavailable_in_simulator:
            return "AdServices attribution token is not available in the simulator"

        case .latest_attribution_sent_user_defaults_invalid(let networkKey):
            return "Attribution data stored in UserDefaults has invalid format for network key: \(networkKey)"

        case .copying_attributes(let oldAppUserID, let newAppUserID):
            return "Copying unsynced subscriber attributes from user \(oldAppUserID) to user \(newAppUserID)"

        }
    }

    var category: String { return "attribution" }

}
