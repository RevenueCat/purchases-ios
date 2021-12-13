//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ManageSubscriptionsStrings.swift
//
//  Created by Andrés Boedo on 13/12/21.

import Foundation

// swiftlint:disable identifier_name
enum ManageSubscriptionStrings {

    case cant_form_apple_subscriptions_url
    case error_from_appstore_show_manage_subscription(error: Error)
    case failed_to_get_management_url_error_unknown(error: Error)
    case failed_to_get_management_url_nil_customer_info
    case failed_to_get_window_scene
    case show_manage_subscriptions_called_in_unsupported_platform
    case susbscription_management_sheet_dismissed

}

extension ManageSubscriptionStrings: CustomStringConvertible {

    var description: String {
        switch self {
        case .cant_form_apple_subscriptions_url:
            return "Error when trying to form the Apple Subscriptions URL."
        case .error_from_appstore_show_manage_subscription(let error):
            return "Error when trying to show manage subscription: \(error.localizedDescription)"
        case .failed_to_get_management_url_error_unknown(let error):
            return "Failed to get managementURL from CustomerInfo. Details: \(error.localizedDescription)"
        case .failed_to_get_management_url_nil_customer_info:
            return "Failed to get managementURL from CustomerInfo. Details: customerInfo is nil."
        case .failed_to_get_window_scene:
            return "Failed to get UIWindowScene"
        case .susbscription_management_sheet_dismissed:
            return "Subscription management sheet dismissed."
        case .show_manage_subscriptions_called_in_unsupported_platform:
            return "tried to call AppStore.showManageSubscriptions in a platform that doesn't support it!"
        }
    }

}
