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

    case login_success

    case log_out_called_for_user

    case log_out_success

    case identifying_app_user_id

    case null_currentappuserid

    case deleting_attributes_none_found

    case invalidating_cached_customer_info

    case switching_user(newUserID: String)

    case switching_user_same_app_user_id(newUserID: String)

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
        case .invalidating_cached_customer_info:
            return "Detected unverified cached CustomerInfo but verification is enabled. Invalidating cache."
        case let .switching_user(newUserID):
            return "Switching to user '\(newUserID)'."
        case let .switching_user_same_app_user_id(newUserID):
            return "switchUser(to:) called with the same appUserID as the current user (\(newUserID)). " +
            "This has no effect."
        }
    }

    var category: String { return "identity" }

}
