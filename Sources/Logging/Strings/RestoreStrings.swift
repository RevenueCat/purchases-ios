//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RestoreStrings.swift
//
//  Created by Tina Nguyen on 12/11/20.
//

import Foundation

enum RestoreStrings {

    // swiftlint:disable identifier_name
    case restorepurchases_called_with_allow_sharing_appstore_account_false_warning
    // swiftlint:enable identifier_name

}

extension RestoreStrings: CustomStringConvertible {

    var description: String {
        switch self {
        case .restorepurchases_called_with_allow_sharing_appstore_account_false_warning:
            return "allowSharingAppStoreAccount is set to false and restorePurchases has been called. " +
            "Are you sure you want to do this?"
        }
    }

}
