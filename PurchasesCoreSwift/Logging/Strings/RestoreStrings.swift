//
//  RestoreStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCRestoreStrings) public class RestoreStrings: NSObject {
    @objc public var restoretransactions_called_with_allow_sharing_appstore_account_false_warning: String {
        "allowSharingAppStoreAccount is set to false and restoreTransactions has been called. Are you sure you want " +
        "to do this?" }
}
