//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IdentityStrings.swift
//
//  Created by Tina Nguyen on 12/11/20.

import Foundation

// swiftlint:disable identifier_name
enum IdentityStrings {

    case logging_in_with_empty_appuserid

    case logging_in_with_same_appuserid

    case logging_in_with_static_string

    case logging_in_with_preview_mode_appuserid

    case login_success

    case log_out_called_for_user

    case log_out_success

    case identifying_app_user_id

    case null_currentappuserid

    case deleting_attributes_none_found

    case invalidating_http_cache

    case switching_user(newUserID: String)

    case switching_user_same_app_user_id(newUserID: String)

    case sync_attributes_and_offerings_rate_limit_reached(maxCalls: Int, period: Int)

}

extension IdentityStrings: LogMessage {

    var description: String {
        switch self {
        case .logging_in_with_empty_appuserid:
            return "The appUserID is empty. " +
                "This method should only be called with non-empty values."
        case .logging_in_with_same_appuserid:
            return "The appUserID passed to logIn is the same as the one " +
                "already cached. No action will be taken."
        case .logging_in_with_static_string:
            return "The appUserID passed to logIn is a constant string known at compile time. " +
            "This is likely a programmer error. This ID is used to identify the current user. " +
            "See https://docs.revenuecat.com/docs/user-ids for more information."
        case .logging_in_with_preview_mode_appuserid:
            return "Using the default preview mode appUserID. The passed appUserID was ignored."
        case .login_success:
            return "Log in successful"
        case .log_out_called_for_user:
            return "Log out called for user"
        case .log_out_success:
            return "Log out successful"
        case .identifying_app_user_id:
            return "Identifying App User ID"
        case .null_currentappuserid:
            return "currentAppUserID is nil. This might happen if the cache in UserDefaults is unintentionally cleared."
        case .deleting_attributes_none_found:
            return "Attempt to delete attributes for user, but there were none to delete"
        case .invalidating_http_cache:
            return "Detected unverified cached CustomerInfo but verification is enabled. Invalidating ETag cache."
        case let .switching_user(newUserID):
            return "Switching to user '\(newUserID)'."
        case let .switching_user_same_app_user_id(newUserID):
            return "switchUser(to:) called with the same appUserID as the current user (\(newUserID)). " +
            "This has no effect."
        case let .sync_attributes_and_offerings_rate_limit_reached(maxCalls, period):
            return "Sync attributes and offerings rate limit reached:\(maxCalls) per \(period) seconds. " +
            "Returning offerings from cache."
        }
    }

    var category: String { return "identity" }

}
