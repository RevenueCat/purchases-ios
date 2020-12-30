//
//  ConfigureStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCConfigureStrings) public class ConfigureStrings: NSObject {
    @objc public var adsupport_not_imported: String { "AdSupport framework not imported. Attribution data incomplete." }
    @objc public var application_active: String { "applicationDidBecomeActive" }
    @objc public var configuring_purchases_proxy_url_set: String { "Purchases is being configured using a proxy for RevenueCat with URL: %@" }
    @objc public var debug_enabled: String { "Debug logging enabled" }
    @objc public var delegate_set: String { "Delegate set" }
    @objc public var purchase_instance_already_set: String { "Purchases instance already set. Did you mean to configure two Purchases objects?" }
    @objc public var initial_app_user_id: String { "Initial App User ID - %@" }
    @objc public var no_singleton_instance: String { "There is no singleton instance. Make sure you configure Purchases before trying to get the default instance. More info here: https://errors.rev.cat/configuring-sdk" }
    @objc public var sdk_version: String { "SDK Version - %@" }
}
