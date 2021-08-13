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
public class IdentityStrings: NSObject {

    public var changing_app_user_id: String { "Changing App User ID: %@ -> %@" }
    public var logging_in_with_initial_appuserid_nil: String { "Couldn't log in because the current appUserID " +
        "is nil. This might happen if the cache in UserDefaults is unintentionally cleared." }
    public var logging_in_with_nil_appuserid: String { "The appUserID passed to logIn is nil or empty. " +
        "Can't log in. This method should only be called with non-nil and non-empty values." }
    public var logging_in_with_same_appuserid: String { "The appUserID passed to logIn is the same as the one " +
    "already cached. No action will be taken."}
    public var creating_alias_success: String { "Alias created" }
    public var login_success: String { "Log in successful" }
    public var log_out_called_for_user: String { "Log out called for user %@" }
    public var log_out_success: String { "Log out successful" }
    public var creating_alias: String { "Creating an alias between current appUserID %@ and %@" }
    public var identifying_anon_id: String { "Identifying from an anonymous ID: %@. An alias will be created." }
    public var identifying_app_user_id: String { "Identifying App User ID: %@" }
    public var null_currentappuserid: String {
        "currentAppUserID is nil. This might happen if the cache in UserDefaults is unintentionally cleared."
    }

}
