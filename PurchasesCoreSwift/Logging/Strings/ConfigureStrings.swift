//
//  ConfigureStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCConfigureStrings) public class ConfigureStrings: NSObject {
    @objc public var adsupport_not_imported: String { "AdSupport framework not imported. Attribution data incomplete." } //warn
    @objc public var application_active: String { "applicationDidBecomeActive" } //debug
    @objc public var configuring_purchases_proxy_url_set: String { "Purchases is being configured using a proxy for RevenueCat with URL: %@" } //info
    @objc public var debug_enable: String { "Debug logging enabled" } //debug
    @objc public var delegate_set: String { "Delegate set" } //debug
    @objc public var duplicate_purchases_instance: String { "Purchases instance already set. Did you mean to configure two Purchases objects?" } //info
    @objc public var initial_app_user_id: String { "Initial App User ID - %@" } //debug
    @objc public var no_singleton_instance: String { "There is no singleton instance. Make sure you configure Purchases before trying to get the default instance. More info here: https://errors.rev.cat/configuring-sdk" } //warn
    @objc public var sdk_version: String { "SDK Version - %@" } //debug
}
