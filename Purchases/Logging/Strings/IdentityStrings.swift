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

    case changing_app_user_id(from: String, to: String)

    case logging_in_with_empty_appuserid

    case logging_in_with_same_appuserid

    case creating_alias_success

    case login_success

    case log_out_called_for_user(appUserID: String)

    case log_out_success

    case creating_alias(userA: String, userB: String)

    case identifying_anon_id(appUserID: String)

    case identifying_app_user_id(appUserID: String)

    case null_currentappuserid

}

extension IdentityStrings: CustomStringConvertible {

    var description: String {
        switch self {
        case .changing_app_user_id(let from, let to):
            return "Changing App User ID: \(from) -> \(to)"
        case .logging_in_with_empty_appuserid:
            return "The appUserID is empty. " +
                "This method should only be called with non-empty values."
        case .logging_in_with_same_appuserid:
            return "The appUserID passed to logIn is the same as the one " +
                "already cached. No action will be taken."
        case .creating_alias_success:
            return "Alias created"
        case .login_success:
            return "Log in successful"
        case .log_out_called_for_user(let appUserID):
            return "Log out called for user \(appUserID)"
        case .log_out_success:
            return "Log out successful"
        case .creating_alias(let userA, let userB):
            return "Creating an alias between current appUserID \(userA) and \(userB)"
        case .identifying_anon_id(let appUserID):
            return "Identifying from an anonymous ID: \(appUserID). An alias will be created."
        case .identifying_app_user_id(let appUserID):
            return "Identifying App User ID: \(appUserID)"
        case .null_currentappuserid:
            return "currentAppUserID is nil. This might happen if the cache in UserDefaults is unintentionally cleared."
        }
    }

}
