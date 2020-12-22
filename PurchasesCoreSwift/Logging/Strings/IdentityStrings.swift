//
//  IdentityStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCIdentityStrings) public class IdentityStrings: NSObject {
    @objc public var changing_app_user_id: String { "Changing App User ID: %@ -> %@" }
    @objc public var creating_alias_failed_null_currentappuserid: String { "Couldn't create an alias because the currentAppUserID is null. This might happen if the cache in UserDefaults is unintentionally cleared." }
    @objc public var creating_alias_success: String { "Alias created" }
    @objc public var creating_alias: String { "Creating an alias to %@ from %@" }
    @objc public var identifying_anon_id: String { "Identifying from an anonymous ID: %@. An alias will be created." }
    @objc public var identifying_app_user_id: String { "Identifying App User ID: %@" }
}
