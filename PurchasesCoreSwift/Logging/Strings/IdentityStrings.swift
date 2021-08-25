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

    static let changing_app_user_id = "Changing App User ID: %@ -> %@"
    static let logging_in_with_nil_appuserid = "The appUserID passed to logIn is nil or empty. " +
        "Can't log in. This method should only be called with non-nil and non-empty values."
    static let logging_in_with_same_appuserid = "The appUserID passed to logIn is the same as the one " +
        "already cached. No action will be taken."
    static let creating_alias_success = "Alias created"
    static let login_success = "Log in successful"
    static let log_out_called_for_user = "Log out called for user %@"
    static let log_out_success = "Log out successful"
    static let creating_alias = "Creating an alias between current appUserID %@ and %@"
    static let identifying_anon_id = "Identifying from an anonymous ID: %@. An alias will be created."
    static let identifying_app_user_id = "Identifying App User ID: %@"
    static let null_currentappuserid = "currentAppUserID is nil. This might happen if the cache in UserDefaults is " +
        "unintentionally cleared."

}
