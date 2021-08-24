//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ConfigureStrings.swift
//
//  Created by Tina Nguyen on 12/11/20.
//

import Foundation

// swiftlint:disable identifier_name
enum ConfigureStrings {

    static let adsupport_not_imported = "AdSupport framework not imported. Attribution data incomplete."
    static let application_active = "applicationDidBecomeActive"
    static let configuring_purchases_proxy_url_set = "Purchases is being configured using a proxy for RevenueCat with URL: %@"
    static let debug_enabled = "Debug logging enabled"
    static let delegate_set = "Delegate set"
    static let purchase_instance_already_set = "Purchases instance already set. Did you mean to configure two Purchases objects?"
    static let initial_app_user_id = "Initial App User ID - %@"
    static let no_singleton_instance = "There is no singleton instance. Make sure you configure Purchases before trying to get the default instance." +
        " More info here: https://errors.rev.cat/configuring-sdk"
    static let sdk_version = "SDK Version - %@"

}
