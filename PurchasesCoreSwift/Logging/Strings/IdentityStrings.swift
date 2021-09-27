//
//  IdentityStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

// swiftlint:disable identifier_name
@objc(RCIdentityStrings) public class IdentityStrings: NSObject {
    @objc public var changing_app_user_id: String { "Changing App User ID: %@ -> %@" }
    @objc public var creating_alias_failed_null_currentappuserid: String { "Couldn't create an alias because the " +
        "currentAppUserID is nil. This might happen if the cache in UserDefaults is unintentionally cleared." }
    @objc public var logging_in_with_initial_appuserid_nil: String { "Couldn't log in because the current appUserID " +
        "is nil. This might happen if the cache in UserDefaults is unintentionally cleared." }
    @objc public var logging_in_with_nil_appuserid: String { "The appUserID passed to logIn is nil or empty. " +
        "Can't log in. This method should only be called with non-nil and non-empty values." }
    @objc public var creating_alias_with_nil_appuserid: String { "The appUserID passed to createAlias is nil or " +
        " empty. Can't create alias. This method should only be called with non-nil and non-empty values." }
    @objc public var logging_in_with_same_appuserid: String { "The appUserID passed to logIn is the same as the one " +
    "already cached. No action will be taken."}
    @objc public var creating_alias_success: String { "Alias created" }
    @objc public var login_success: String { "Log in successful" }
    @objc public var logging_out_user: String { "Logging out user %@" }
    @objc public var log_out_success: String { "Log out successful" }
    @objc public var creating_alias: String { "Creating an alias between current appUserID %@ and %@" }
    @objc public var identifying_anon_id: String { "Identifying from an anonymous ID: %@. An alias will be created." }
    @objc public var identifying_app_user_id: String { "Identifying App User ID: %@" }
}
