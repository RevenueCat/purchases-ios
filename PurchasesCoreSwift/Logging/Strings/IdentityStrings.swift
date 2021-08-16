//
//  IdentityStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

// swiftlint:disable identifier_name
class IdentityStrings {

    var changing_app_user_id: String { "Changing App User ID: %@ -> %@" }
    var creating_alias_failed_null_currentappuserid: String { "Couldn't create an alias because the " +
        "currentAppUserID is nil. This might happen if the cache in UserDefaults is unintentionally cleared." }
    var logging_in_with_initial_appuserid_nil: String { "Couldn't log in because the current appUserID " +
        "is nil. This might happen if the cache in UserDefaults is unintentionally cleared." }
    var logging_in_with_nil_appuserid: String { "The appUserID passed to logIn is nil or empty. " +
        "Can't log in. This method should only be called with non-nil and non-empty values." }
    var logging_in_with_same_appuserid: String { "The appUserID passed to logIn is the same as the one " +
    "already cached. No action will be taken."}
    var creating_alias_success: String { "Alias created" }
    var login_success: String { "Log in successful" }
    var log_out_called_for_user: String { "Log out called for user %@" }
    var log_out_success: String { "Log out successful" }
    var creating_alias: String { "Creating an alias between current appUserID %@ and %@" }
    var identifying_anon_id: String { "Identifying from an anonymous ID: %@. An alias will be created." }
    var identifying_app_user_id: String { "Identifying App User ID: %@" }
    var reset_missing_app_user_id: String { "Reset App User ID called on nil current user." }

}
