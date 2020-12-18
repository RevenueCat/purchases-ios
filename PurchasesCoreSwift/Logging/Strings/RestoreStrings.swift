//
//  RestoreStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCRestoreStrings) public class RestoreStrings: NSObject {
    @objc public var sharing_acc_false_restore_called: String { "allowSharingAppStoreAccount is set to false and restoreTransactions has been called. Are you sure you want to do this?" } //warn
}
